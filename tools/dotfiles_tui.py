"""Curses frontend. Run via ../dotfiles; no third-party packages required."""

from __future__ import annotations

import argparse
import curses
import locale
from pathlib import Path
import sys
import unicodedata

from dotlinks import Conflict, LinkManager


HELP = [
    "Navigate",
    "  Up/Down or j/k     Move the cursor",
    "  Right/l           Expand directory / move into it",
    "  Left/h            Collapse directory / move to parent",
    "  Enter             Expand or collapse directory",
    "  Home/End or g/G    First / last visible entry",
    "  PageUp/PageDown    Scroll one page",
    "  /                 Filter paths (Enter keeps, Esc clears)",
    "",
    "Stage changes (nothing on disk changes yet)",
    "  Space             Toggle file or whole-directory link",
    "  + / -             Select / unselect a whole subtree",
    "  u                 Undo all staged changes",
    "  r                 Refresh from disk (discards staging)",
    "  a                 Review the exact plan, then y to apply",
    "  q                 Quit (confirm if changes are staged)",
    "",
    "Legend",
    "  [x] selected      [-] partially selected      [ ] unselected",
    "  @ direct link     > covered by a parent link  ! local conflict",
    "  + staged link     - staged unlink            ~ link layout change",
    "",
    "Directories are linked as ONE symlink, not copied or merged.",
    "Unselecting a child of a linked directory splits its parent into",
    "a real directory with links for the remaining siblings.",
    "Existing files and foreign links are never overwritten. Expand",
    "a conflicting directory to select individual files instead.",
    "A real directory can become a link only if it contains nothing",
    "but managed links and empty directories. Unlinking keeps real",
    "directories and unrelated contents. Source files are never deleted.",
]


def safe_text(value: str) -> str:
    return "".join(char if char.isprintable() else repr(char)[1:-1] for char in value)


def clipped(value: str, width: int) -> str:
    """Clip by terminal cells, including wide filenames, not Python length."""
    result = []
    used = 0
    for char in safe_text(value):
        cells = 0 if unicodedata.combining(char) else (2 if unicodedata.east_asian_width(char) in "WF" else 1)
        if used + cells > width:
            break
        result.append(char)
        used += cells
    return "".join(result)


def wrapped_lines(lines: list[str], width: int) -> list[str]:
    """Make every character inspectable in review, even with long paths."""
    result = []
    width = max(2, width)
    for line in lines:
        rest = safe_text(line)
        if not rest:
            result.append("")
        while rest:
            part = clipped(rest, width)
            result.append(part)
            rest = rest[len(part):]
    return result


class App:
    def __init__(self, screen, manager: LinkManager):
        self.screen = screen
        self.manager = manager
        self.expanded = {rel for rel in manager.roots if manager.nodes[rel].is_dir}
        self.cursor = 0
        self.scroll = 0
        self.query = ""
        self.searching = False
        self.message = "Nothing changes on disk until you review with a and confirm with y."
        self.error = False
        self.colors = False
        try:
            curses.curs_set(0)
        except curses.error:
            pass
        if curses.has_colors():
            try:
                curses.start_color()
                curses.use_default_colors()
                for number, color in enumerate((curses.COLOR_CYAN, curses.COLOR_GREEN, curses.COLOR_YELLOW, curses.COLOR_RED), 1):
                    curses.init_pair(number, color, -1)
                self.colors = True
            except curses.error:
                pass
        self.screen.keypad(True)

    def attr(self, color: int = 0, bold: bool = False) -> int:
        return (curses.color_pair(color) if color and self.colors else 0) | (curses.A_BOLD if bold else 0)

    def put(self, y: int, x: int, value: str, attr: int = 0) -> None:
        height, width = self.screen.getmaxyx()
        if 0 <= y < height and 0 <= x < width:
            try:
                self.screen.addstr(y, x, clipped(value, width - x - 1), attr)
            except curses.error:
                pass  # Resize or a terminal's differing character-width table.

    def key(self):
        try:
            return self.screen.get_wch()
        except curses.error:
            return None

    def visible(self) -> list[tuple[str, int]]:
        matches: set[str] | None = None
        if self.query:
            matches = set()
            for rel in self.manager.nodes:
                if self.query.casefold() in rel.casefold():
                    matches.add(rel)
                    matches.update(parent.as_posix() for parent in Path(rel).parents if parent != Path("."))
        result = []

        def visit(rel: str, depth: int) -> None:
            if matches is not None and rel not in matches:
                return
            result.append((rel, depth))
            if rel in self.expanded or matches is not None:
                for child in self.manager.nodes[rel].children:
                    visit(child, depth + 1)

        for rel in self.manager.roots:
            visit(rel, 0)
        return result

    def pending(self) -> int:
        return len(self.manager.desired ^ self.manager.existing)

    def draw(self, rows: list[tuple[str, int]]) -> None:
        self.screen.erase()
        height, width = self.screen.getmaxyx()
        if height < 18 or width < 60:
            self.put(0, 0, "Terminal too small (need 60 x 18). Resize, or q to quit.")
            self.screen.refresh()
            return
        self.put(0, 1, f"DOTFILES  /  symlink manager    {self.pending()} staged link changes", self.attr(1, True))
        self.put(1, 1, f"Repository  {self.manager.repository}")
        self.put(2, 1, f"Home        {self.manager.home}")
        self.put(3, 1, "[x] selected  [-] partial    @ linked  > inherited  ! conflict", self.attr(1))
        self.put(4, 0, "─" * width, curses.A_DIM)
        count = max(1, height - 13)
        self.cursor = max(0, min(self.cursor, len(rows) - 1))
        self.scroll = max(0, min(self.scroll, self.cursor))
        if self.cursor >= self.scroll + count:
            self.scroll = self.cursor - count + 1
        for y, (rel, depth) in enumerate(rows[self.scroll:self.scroll + count], 5):
            index = self.scroll + y - 5
            node = self.manager.nodes[rel]
            state = self.manager.selection_state(rel)
            before = self.manager.selection_state(rel, self.manager.existing)
            status = self.manager.status(rel)
            mark = {"all": "x", "some": "-", "none": " "}[state]
            live = {"linked": "@", "inherited": ">", "conflict": "!"}.get(status, " ")
            delta = " "
            if state != before:
                delta = "+" if state == "all" else ("-" if state == "none" else "~")
            elif (rel in self.manager.desired) != (rel in self.manager.existing):
                delta = "~"
            arrow = ("▾" if rel in self.expanded or self.query else "▸") if node.is_dir else " "
            label = f" {delta} [{mark}] {live}  {'  ' * depth}{arrow} {Path(rel).name}{'/' if node.is_dir else ''}"
            color = 3 if delta != " " else (4 if status == "conflict" else (2 if state == "all" else 0))
            attr = self.attr(color)
            if index == self.cursor:
                attr |= curses.A_REVERSE
                self.put(y, 0, " " * (width - 1), attr)
            self.put(y, 0, label, attr)
        if not rows:
            self.put(5, 2, "No matching paths." if self.query else "No installable paths in this repository.")
        self.put(height - 8, 0, "─" * width, curses.A_DIM)
        if rows:
            rel = rows[self.cursor][0]
            status = self.manager.status(rel)
            now = {
                "linked": "direct symlink to this repository",
                "inherited": f"covered by ~/{self.manager.covering(rel, self.manager.existing)}",
                "conflict": "existing file or foreign symlink (will not overwrite)",
                "directory": "real directory; individual links can live inside it",
                "missing": "not linked / destination missing",
            }[status]
            owner = self.manager.covering(rel, self.manager.desired)
            staged = ("one directory symlink" if self.manager.nodes[rel].is_dir else "one file symlink") if owner == rel else (
                f"covered by ~/{owner}" if owner else ("individual descendant links" if self.manager.selection_state(rel) == "some" else "not linked")
            )
            self.put(height - 7, 1, f"~/{rel}", self.attr(1, True))
            self.put(height - 6, 1, f"Now     {now}")
            self.put(height - 5, 1, f"Staged  {staged}")
        self.put(height - 4, 1, self.message, self.attr(4 if self.error else 3))
        self.put(height - 3, 1, f"{len(rows)} visible / {len(self.manager.nodes)} paths" + (f"    filter: {self.query}" if self.query else ""), curses.A_DIM)
        self.put(height - 2, 1, "↑↓/jk move  ←→/hl fold  Space toggle  +/- select/unselect  / filter")
        self.put(height - 1, 1, f"/{self.query}▏  Enter keep · Esc clear" if self.searching else "a review/apply  u undo  r refresh  ? help  q quit", self.attr(1) if self.searching else 0)
        self.screen.refresh()

    def modal(self, title: str, lines: list[str], footer: str, accept: tuple = ()) -> bool:
        offset = 0
        while True:
            self.screen.erase()
            height, width = self.screen.getmaxyx()
            page = max(1, height - 5)
            wrapped = wrapped_lines(lines, width - 3)
            offset = max(0, min(offset, max(0, len(wrapped) - page)))
            self.put(0, 1, title, self.attr(1, True))
            self.put(1, 0, "─" * width, curses.A_DIM)
            for y, line in enumerate(wrapped[offset:offset + page], 2):
                color = 2 if line.startswith("  LINK ") else (3 if line.startswith("  UNLINK ") else 0)
                self.put(y, 1, line, self.attr(color))
            self.put(height - 2, 1, f"{offset + 1 if wrapped else 0}-{min(offset + page, len(wrapped))} / {len(wrapped)}    ↑↓ or PgUp/PgDn to scroll", curses.A_DIM)
            self.put(height - 1, 1, footer, self.attr(3, True))
            self.screen.refresh()
            key = self.key()
            if key in ("q", "n", "N", "\x1b"):
                return False
            if key in accept and height >= 8 and width >= 40:
                return True
            if not accept and key in ("\n", "\r", " "):
                return False
            if key in (curses.KEY_DOWN, "j"):
                offset += 1
            elif key in (curses.KEY_UP, "k"):
                offset -= 1
            elif key in (curses.KEY_NPAGE, " "):
                offset += page
            elif key == curses.KEY_PPAGE:
                offset -= page
            elif key in ("g", curses.KEY_HOME):
                offset = 0
            elif key in ("G", curses.KEY_END):
                offset = len(wrapped)

    def confirm(self, question: str) -> bool:
        return self.modal(question, [], "y confirm  ·  n / Esc cancel", ("y", "Y"))

    def review(self) -> None:
        try:
            plan = self.manager.plan()
            if not plan.operations:
                self.message = "No staged changes to apply."
                return
            lines = [f"Home: {self.manager.home}", "", "Only the following changes will be made:", ""]
            for op in plan.operations:
                lines.append(f"  {op.action.upper():6} ~/{op.rel}")
                if op.action == "link":
                    lines.append(f"           -> {op.target}")
            lines += ["", "UNLINK removes only a symlink, never its target.", "RMDIR removes only an empty real directory.", "No existing files or foreign links will be overwritten."]
            if self.modal(f"Review {len(plan.operations)} filesystem operations", lines, "y APPLY these changes  ·  n / Esc cancel", ("y", "Y")):
                self.manager.apply(plan)
                self.message = f"Applied {len(plan.operations)} operations successfully."
        except (Conflict, OSError) as error:
            self.error = True
            self.message = str(error).splitlines()[0]
            self.modal("Changes could not be applied", str(error).splitlines(), "Enter / Esc to return; no conflicting paths are overwritten")

    def run(self) -> None:
        while True:
            rows = self.visible()
            self.draw(rows)
            key = self.key()
            if key is None or key == curses.KEY_RESIZE:
                continue
            if min(self.screen.getmaxyx()[0] / 18, self.screen.getmaxyx()[1] / 60) < 1:
                if key == "q" and (not self.pending() or self.confirm("Discard staged changes and quit?")):
                    return
                continue
            if self.searching:
                if key in ("\n", "\r", curses.KEY_ENTER):
                    self.searching = False
                elif key == "\x1b":
                    self.query = ""
                    self.searching = False
                elif key in (curses.KEY_BACKSPACE, "\x7f", "\b"):
                    self.query = self.query[:-1]
                elif key == "\x15":
                    self.query = ""
                elif isinstance(key, str) and key.isprintable():
                    self.query += key
                self.cursor = self.scroll = 0
                continue
            self.error = False
            rel = rows[self.cursor][0] if rows else None
            page = max(1, self.screen.getmaxyx()[0] - 13)
            if key in ("q", "Q"):
                if not self.pending() or self.confirm("Discard staged changes and quit?"):
                    return
            elif key == "/":
                self.searching = True
            elif key == "\x1b":
                self.query = ""
            elif key in (curses.KEY_DOWN, "j"):
                self.cursor = min(self.cursor + 1, len(rows) - 1)
            elif key in (curses.KEY_UP, "k"):
                self.cursor = max(0, self.cursor - 1)
            elif key in (curses.KEY_HOME, "g"):
                self.cursor = 0
            elif key in (curses.KEY_END, "G"):
                self.cursor = max(0, len(rows) - 1)
            elif key == curses.KEY_NPAGE:
                self.cursor = min(self.cursor + page, len(rows) - 1)
            elif key == curses.KEY_PPAGE:
                self.cursor = max(0, self.cursor - page)
            elif key in (" ", "+", "=", "-") and rel:
                if key == " ":
                    self.manager.toggle(rel)
                else:
                    self.manager.set_selected(rel, key != "-")
                self.message = "Selection staged. Press a to review and apply; u to undo all."
            elif key in (curses.KEY_RIGHT, "l") and rel:
                if self.manager.nodes[rel].is_dir:
                    if (rel in self.expanded or self.query) and self.cursor + 1 < len(rows) and rows[self.cursor + 1][1] > rows[self.cursor][1]:
                        self.cursor += 1
                    else:
                        self.expanded.add(rel)
            elif key in (curses.KEY_LEFT, "h") and rel:
                if rel in self.expanded and not self.query:
                    self.expanded.remove(rel)
                else:
                    parent = Path(rel).parent.as_posix()
                    self.cursor = next((i for i, (path, _) in enumerate(rows) if path == parent), self.cursor)
            elif key in ("\n", "\r", curses.KEY_ENTER) and rel:
                if rel in self.expanded:
                    self.expanded.remove(rel)
                elif self.manager.nodes[rel].is_dir:
                    self.expanded.add(rel)
            elif key == "a":
                self.review()
            elif key == "u":
                self.manager.desired = set(self.manager.existing)
                self.message = "All staged changes discarded."
            elif key == "r":
                if not self.pending() or self.confirm("Refresh and discard staged changes?"):
                    try:
                        self.manager.refresh()
                        self.message = "Refreshed link status from disk."
                    except (Conflict, OSError) as error:
                        self.error = True
                        self.message = str(error)
            elif key == "?":
                self.modal("Dotfiles / help", HELP, "Enter / Esc close  ·  ↑↓ scroll")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Browse and safely manage symlinks from this dotfiles repository into home.")
    parser.add_argument("--home", type=Path, default=Path.home(), help="destination home directory (default: %(default)s)")
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[1], help="source repository (default: this checkout)")
    parser.add_argument("--status", action="store_true", help="print current link status without opening the TUI or changing anything")
    args = parser.parse_args(argv)
    try:
        manager = LinkManager(args.repo, args.home)
        if args.status:
            print(f"Repository: {manager.repository}\nHome: {manager.home}")
            for rel in sorted(manager.nodes):
                print(f"{manager.status(rel):10} {safe_text(rel)}{'/' if manager.nodes[rel].is_dir else ''}")
            print(f"\n{len(manager.existing)} direct symlinks to this repository")
            return 0
        if not sys.stdin.isatty() or not sys.stdout.isatty():
            parser.error("the TUI needs an interactive terminal; use --status for plain text")
        locale.setlocale(locale.LC_ALL, "")
        curses.set_escdelay(25)
        curses.wrapper(lambda screen: App(screen, manager).run())
        return 0
    except (Conflict, OSError, curses.error) as error:
        print(f"dotfiles: {error}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        return 130


if __name__ == "__main__":
    raise SystemExit(main())
