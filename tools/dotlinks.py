"""Safe, dependency-free link planning for a home-shaped dotfiles repository."""

from __future__ import annotations

from contextlib import contextmanager
from dataclasses import dataclass
import os
from pathlib import Path
import signal
import stat


# These are repository infrastructure, not files to install in $HOME.
ROOT_EXCLUDES = {".git", ".jj", ".gitignore", "README.md", "dotfiles", "tools", "tests"}
NOISE = {".git", ".jj", "__pycache__", ".DS_Store"}


class Conflict(Exception):
    """A change cannot be made without touching something we do not own."""


@dataclass(frozen=True)
class Node:
    rel: str
    is_dir: bool
    children: tuple[str, ...] = ()


@dataclass(frozen=True)
class Operation:
    action: str
    rel: str
    target: str | None = None


@dataclass(frozen=True)
class Plan:
    operations: tuple[Operation, ...]


def beneath(path: str, parent: str) -> bool:
    return path == parent or path.startswith(parent + "/")


@contextmanager
def defer_interrupt():
    """Keep a SIGINT from landing between a mutation and its undo record."""
    previous = signal.pthread_sigmask(signal.SIG_BLOCK, {signal.SIGINT})
    try:
        yield
    finally:
        signal.pthread_sigmask(signal.SIG_SETMASK, previous)


def scan(repository: Path) -> dict[str, Node]:
    nodes: dict[str, Node] = {}

    def visit(directory: Path, root: bool = False) -> tuple[str, ...]:
        children = []
        entries = sorted(directory.iterdir(), key=lambda p: (not (p.is_dir() and not p.is_symlink()), p.name.casefold()))
        for entry in entries:
            if entry.name in NOISE or (root and entry.name in ROOT_EXCLUDES):
                continue
            rel = entry.relative_to(repository).as_posix()
            is_dir = entry.is_dir() and not entry.is_symlink()
            nested = visit(entry) if is_dir else ()
            nodes[rel] = Node(rel, is_dir, nested)
            children.append(rel)
        return tuple(children)

    visit(repository, root=True)
    return nodes


class LinkManager:
    def __init__(self, repository: Path, home: Path):
        self.repository = repository.expanduser().resolve()
        self.home = home.expanduser().resolve()
        if not self.repository.is_dir() or not self.home.is_dir():
            raise Conflict("Repository and home must both be existing directories.")
        if self.home == self.repository or self.repository in self.home.parents:
            raise Conflict("Home must not be inside the repository.")
        self.refresh()

    def refresh(self) -> None:
        self.nodes = scan(self.repository)
        self.roots = tuple(rel for rel in self.nodes if "/" not in rel)
        self.existing = self.direct_links()
        self.desired = set(self.existing)

    def owned(self, rel: str) -> bool:
        destination = self.home / rel
        if not destination.is_symlink():
            return False
        target = destination.parent / os.readlink(destination)
        source = self.repository / rel
        # Resolve parent aliases before normalizing '..': a/../b can escape
        # elsewhere when a is a symlink. Do not resolve the final component:
        # a source symlink is itself a legitimate dotfile.
        try:
            actual = target.resolve() if target.name == ".." else target.parent.resolve() / target.name
            return actual == source.parent.resolve() / source.name
        except (OSError, RuntimeError):
            return False

    def direct_links(self) -> set[str]:
        found: set[str] = set()

        def visit(rel: str) -> None:
            path = self.home / rel
            if path.is_symlink():
                if self.owned(rel):
                    found.add(rel)
                return  # Never traverse another symlink, even one into the repo.
            if self.nodes[rel].is_dir and path.is_dir():
                for child in self.nodes[rel].children:
                    visit(child)

        for rel in self.roots:
            visit(rel)
        return found

    def covering(self, rel: str, roots: set[str]) -> str | None:
        return next((root for root in roots if beneath(rel, root)), None)

    def selection_state(self, rel: str, roots: set[str] | None = None) -> str:
        roots = self.desired if roots is None else roots
        if self.covering(rel, roots) is not None:
            return "all"
        if any(beneath(root, rel) for root in roots):
            return "some"
        return "none"

    def toggle(self, rel: str) -> None:
        self.set_selected(rel, self.covering(rel, self.desired) is None)

    def set_selected(self, rel: str, selected: bool) -> None:
        if rel not in self.nodes:
            raise KeyError(rel)
        ancestor = self.covering(rel, self.desired)
        if selected or ancestor is None:
            if ancestor is None:
                self.desired = {root for root in self.desired if not beneath(root, rel)}
                if selected:
                    self.desired.add(rel)
            return
        self.desired.remove(ancestor)
        # Unchecking a child of a directory link unfolds that link into links
        # for the siblings along the path. No writes through the parent link.
        while ancestor != rel:
            child_on_path = next(child for child in self.nodes[ancestor].children if beneath(rel, child))
            self.desired.update(child for child in self.nodes[ancestor].children if child != child_on_path)
            ancestor = child_on_path

    def status(self, rel: str) -> str:
        """On-disk status, independent of staged selection."""
        owner = self.covering(rel, self.existing)
        if owner is not None:
            return "linked" if owner == rel else "inherited"
        parts = Path(rel).parts
        for length in range(1, len(parts) + 1):
            path = self.home.joinpath(*parts[:length])
            if path.is_symlink():
                return "conflict"
            if path.exists() and (length < len(parts) or self.nodes[rel].is_dir):
                if not path.is_dir():
                    return "conflict"
            elif path.exists():
                return "conflict"
        return "directory" if (self.home / rel).is_dir() else "missing"

    def _protect_repository(self, path: Path) -> None:
        if path == self.repository or path in self.repository.parents or self.repository in path.parents:
            raise Conflict(f"Refusing to change {path}: it contains the repository or is inside it.")

    def plan(self) -> Plan:
        if scan(self.repository) != self.nodes:
            raise Conflict("Repository paths changed. Refresh before applying.")
        if self.direct_links() != self.existing:
            raise Conflict("Links changed outside this app. Refresh before applying.")
        # Enforce normalized, valid roots even if a caller changed desired.
        if not self.desired <= self.nodes.keys() or any(
            a != b and beneath(a, b) for a in self.desired for b in self.desired
        ):
            raise Conflict("Invalid selection; refresh and select paths again.")
        removed = self.existing - self.desired
        added = self.desired - self.existing
        unlinks = []
        for rel in sorted(removed):
            path = self.home / rel
            self._protect_repository(path)
            unlinks.append(Operation("unlink", rel, os.readlink(path)))
        rmdirs: set[str] = set()
        mkdirs: set[str] = set()

        def under_removed(rel: str) -> bool:
            return self.covering(rel, removed) is not None

        def clean_directory(path: Path) -> None:
            self._protect_repository(path)
            # Only empty directories and links scheduled for removal can be
            # collapsed. Any other entry, including an unrelated symlink, blocks.
            for child in sorted(path.iterdir()):
                child_rel = child.relative_to(self.home).as_posix()
                if child_rel in removed:
                    continue
                if child.is_dir() and not child.is_symlink():
                    clean_directory(child)
                else:
                    raise Conflict(f"Cannot replace directory: {child} is not a managed link. Link individual files instead.")
            rmdirs.add(path.relative_to(self.home).as_posix())

        for rel in sorted(added):
            destination = self.home / rel
            self._protect_repository(destination)
            parts = Path(rel).parts
            for length in range(1, len(parts)):
                parent_rel = Path(*parts[:length]).as_posix()
                parent = self.home / parent_rel
                if under_removed(parent_rel) or not os.path.lexists(parent):
                    mkdirs.add(parent_rel)
                elif parent.is_symlink() or not parent.is_dir():
                    raise Conflict(f"Cannot link {rel}: parent {parent} is not a real directory.")
            if under_removed(rel) or not os.path.lexists(destination):
                continue
            if destination.is_dir() and not destination.is_symlink():
                clean_directory(destination)
            else:
                raise Conflict(f"Cannot link {rel}: {destination} already exists and is not a managed link.")
        operations = (
            unlinks
            + [Operation("rmdir", rel) for rel in sorted(rmdirs, key=lambda p: (-p.count("/"), p))]
            + [Operation("mkdir", rel) for rel in sorted(mkdirs, key=lambda p: (p.count("/"), p))]
            + [Operation("link", rel, str(self.repository / rel)) for rel in sorted(added)]
        )
        return Plan(tuple(operations))

    def _check_parent(self, path: Path) -> None:
        self._protect_repository(path)
        # Check every component, not just parent.is_dir(), which follows links.
        for parent in reversed((path.parent, *path.parent.parents)):
            if parent == self.home or self.home in parent.parents:
                if parent.is_symlink() or not parent.is_dir():
                    raise Conflict(f"Unsafe parent changed while applying: {parent}")

    @contextmanager
    def _parent_fd(self, path: Path):
        # Open every component without following links. A parent replaced after
        # validation can no longer redirect a write into the repository.
        flags = os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW
        fd = os.open(path.anchor, flags)
        try:
            for part in path.parent.parts[1:]:
                child_fd = os.open(part, flags, dir_fd=fd)
                os.close(fd)
                fd = child_fd
            yield fd
        finally:
            os.close(fd)

    def _mutate(self, op: Operation, mode: int | None = None) -> int | None:
        path = self.home / op.rel
        self._check_parent(path)
        with self._parent_fd(path) as parent_fd:
            if op.action == "unlink":
                if os.readlink(path.name, dir_fd=parent_fd) != op.target:
                    raise Conflict(f"Link changed while applying: {path}")
                os.unlink(path.name, dir_fd=parent_fd)
            elif op.action == "rmdir":
                metadata = os.stat(path.name, dir_fd=parent_fd, follow_symlinks=False)
                os.rmdir(path.name, dir_fd=parent_fd)  # Never follows a symlink; must be empty.
                return stat.S_IMODE(metadata.st_mode)
            elif op.action == "mkdir":
                os.mkdir(path.name, mode=0o777 if mode is None else 0o700, dir_fd=parent_fd)
                if mode is not None:
                    child_fd = os.open(path.name, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=parent_fd)
                    try:
                        os.fchmod(child_fd, mode)
                    finally:
                        os.close(child_fd)
            elif op.action == "link":
                os.symlink(op.target, path.name, dir_fd=parent_fd)
            else:
                raise Conflict(f"Unknown operation: {op.action}")
        return None

    def apply(self, reviewed: Plan | None = None) -> Plan:
        plan = self.plan()
        if reviewed is not None and reviewed != plan:
            raise Conflict("The filesystem changed since review. Review the new plan before applying.")
        completed: list[tuple[Operation, int | None]] = []
        try:
            for op in plan.operations:
                with defer_interrupt():
                    mode = self._mutate(op)
                    completed.append((op, mode))
        except (OSError, Conflict, KeyboardInterrupt) as error:
            rollback_errors = []
            with defer_interrupt():
                for op, mode in reversed(completed):
                    inverse = {"link": "unlink", "unlink": "link", "mkdir": "rmdir", "rmdir": "mkdir"}[op.action]
                    try:
                        self._mutate(Operation(inverse, op.rel, op.target), mode=mode)
                    except (OSError, Conflict) as rollback_error:
                        rollback_errors.append(str(rollback_error))
            if rollback_errors:
                raise Conflict(f"{error}\nRollback incomplete; inspect these paths and refresh:\n" + "\n".join(rollback_errors)) from error
            if isinstance(error, KeyboardInterrupt):
                raise
            raise Conflict(f"{error}\nNo changes kept (rollback completed).") from error
        self.refresh()
        return plan
