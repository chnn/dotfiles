"""Filesystem-backed tests for the dotfiles link manager (no real home writes)."""

import os
from pathlib import Path
import stat
import sys
import tempfile
import unittest
from unittest import mock


sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from dotlinks import Conflict, LinkManager, Node, Operation, Plan


class LinkManagerTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="dotlinks-test-")
        self.addCleanup(self.temporary.cleanup)
        self.base = Path(self.temporary.name).resolve()
        self.repository = self.base / "repo"
        self.home = self.base / "home"
        self.repository.mkdir()
        self.home.mkdir()

    def source(self, rel, contents="repository data\n"):
        path = self.repository / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(contents)
        return path

    def local(self, rel, contents="unrelated local data\n"):
        path = self.home / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(contents)
        return path

    def source_dir(self, rel):
        path = self.repository / rel
        path.mkdir(parents=True, exist_ok=True)
        return path

    def managed_link(self, rel, relative=False):
        path = self.home / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        target = self.repository / rel
        if relative:
            target = os.path.relpath(target, path.parent)
        path.symlink_to(target)
        return path

    def manager(self):
        return LinkManager(self.repository, self.home)

    @staticmethod
    def snapshot(root):
        """Record names, file contents, and raw link targets without following links."""
        result = {}

        def visit(directory):
            for path in sorted(directory.iterdir()):
                rel = path.relative_to(root).as_posix()
                if path.is_symlink():
                    result[rel] = ("link", os.readlink(path))
                elif path.is_dir():
                    result[rel] = ("directory",)
                    visit(path)
                else:
                    result[rel] = ("file", path.read_bytes())

        visit(root)
        return result

    def assert_owned_link(self, rel):
        path = self.home / rel
        self.assertTrue(path.is_symlink(), rel)
        self.assertEqual(os.readlink(path), str(self.repository / rel))

    def assert_conflict_without_changes(self, manager, reviewed=None):
        before_home = self.snapshot(self.home)
        before_repository = self.snapshot(self.repository)
        with self.assertRaises(Conflict):
            manager.plan()
        self.assertEqual(self.snapshot(self.home), before_home)
        with self.assertRaises(Conflict):
            manager.apply(reviewed)
        self.assertEqual(self.snapshot(self.home), before_home)
        self.assertEqual(self.snapshot(self.repository), before_repository)

    def test_link_and_unlink_individual_file(self):
        self.source(".zshrc", "shell settings\n")
        manager = self.manager()
        self.assertEqual(manager.roots, (".zshrc",))
        self.assertEqual(manager.nodes[".zshrc"], Node(".zshrc", False))
        self.assertEqual(manager.existing, set())
        self.assertEqual(manager.selection_state(".zshrc"), "none")
        self.assertEqual(manager.status(".zshrc"), "missing")

        manager.toggle(".zshrc")
        reviewed = Plan((Operation("link", ".zshrc", str(self.repository / ".zshrc")),))
        self.assertEqual(manager.plan(), reviewed)
        self.assertFalse(os.path.lexists(self.home / ".zshrc"))
        self.assertEqual(manager.status(".zshrc"), "missing")
        self.assertEqual(manager.apply(reviewed), reviewed)
        self.assert_owned_link(".zshrc")
        self.assertEqual(manager.existing, {".zshrc"})
        self.assertEqual(manager.desired, manager.existing)
        self.assertEqual(manager.status(".zshrc"), "linked")
        self.assertEqual((self.home / ".zshrc").read_text(), "shell settings\n")

        manager.toggle(".zshrc")
        unlink = Plan((Operation("unlink", ".zshrc", str(self.repository / ".zshrc")),))
        self.assertEqual(manager.apply(), unlink)
        self.assertFalse(os.path.lexists(self.home / ".zshrc"))
        self.assertEqual((self.repository / ".zshrc").read_text(), "shell settings\n")
        self.assertEqual(manager.existing, set())

    def test_link_directory_and_report_inherited_descendants(self):
        self.source(".config/editor/init.lua")
        self.source(".config/theme")
        manager = self.manager()
        manager.toggle(".config")
        manager.apply()
        self.assert_owned_link(".config")
        self.assertEqual(manager.existing, {".config"})
        self.assertEqual(manager.status(".config"), "linked")
        for rel in (".config/editor", ".config/editor/init.lua", ".config/theme"):
            with self.subTest(rel=rel):
                self.assertEqual(manager.status(rel), "inherited")
                self.assertEqual(manager.selection_state(rel), "all")
        before = self.snapshot(self.repository)
        manager.toggle(".config")
        manager.apply()
        self.assertFalse(os.path.lexists(self.home / ".config"))
        self.assertEqual(self.snapshot(self.repository), before)

    def test_relative_owned_symlink_is_discovered_and_unlinked(self):
        self.source(".config/app/file")
        path = self.managed_link(".config/app/file", relative=True)
        target = os.readlink(path)
        manager = self.manager()
        self.assertEqual(manager.existing, {".config/app/file"})
        self.assertEqual(manager.status(".config/app/file"), "linked")
        manager.toggle(".config/app/file")
        self.assertEqual(manager.plan(), Plan((Operation("unlink", ".config/app/file", target),)))
        manager.apply()
        self.assertFalse(os.path.lexists(path))
        self.assertTrue(path.parent.is_dir())
        self.assertTrue((self.repository / ".config/app/file").is_file())

    def test_relative_owned_directory_link_has_inherited_status(self):
        self.source("settings/nested/file")
        self.managed_link("settings", relative=True)
        manager = self.manager()
        self.assertEqual(manager.existing, {"settings"})
        self.assertEqual(manager.status("settings/nested/file"), "inherited")
        self.assertEqual(manager.plan(), Plan(()))

    def test_link_nested_file_creates_parents_in_order(self):
        self.source(".config/app/nested/file")
        manager = self.manager()
        manager.toggle(".config/app/nested/file")
        reviewed = manager.plan()
        self.assertEqual(reviewed.operations, (
            Operation("mkdir", ".config"),
            Operation("mkdir", ".config/app"),
            Operation("mkdir", ".config/app/nested"),
            Operation("link", ".config/app/nested/file", str(self.repository / ".config/app/nested/file")),
        ))
        manager.apply(reviewed)
        self.assert_owned_link(".config/app/nested/file")
        self.assertFalse((self.home / ".config/app").is_symlink())
        self.assertEqual(manager.status(".config"), "directory")

    def test_multiple_new_links_share_parent_creation(self):
        for rel in ("settings/app/a", "settings/app/b"):
            self.source(rel)
        manager = self.manager()
        manager.toggle("settings/app/a")
        manager.toggle("settings/app/b")
        self.assertEqual([op.rel for op in manager.plan().operations if op.action == "mkdir"],
                         ["settings", "settings/app"])
        manager.apply()
        self.assertEqual(manager.existing, {"settings/app/a", "settings/app/b"})

    def test_split_directory_link_leaves_unchecked_child_missing(self):
        self.source("settings/a", "first")
        self.source("settings/b", "second")
        self.managed_link("settings")
        before = self.snapshot(self.repository)
        manager = self.manager()
        manager.toggle("settings/a")
        self.assertEqual(manager.desired, {"settings/b"})
        self.assertEqual(manager.selection_state("settings"), "some")
        self.assertEqual(manager.status("settings/a"), "inherited")
        self.assertEqual(manager.plan().operations, (
            Operation("unlink", "settings", str(self.repository / "settings")),
            Operation("mkdir", "settings"),
            Operation("link", "settings/b", str(self.repository / "settings/b")),
        ))
        manager.apply()
        self.assertFalse((self.home / "settings").is_symlink())
        self.assertFalse(os.path.lexists(self.home / "settings/a"))
        self.assert_owned_link("settings/b")
        self.assertEqual(manager.status("settings/a"), "missing")
        self.assertEqual(manager.status("settings"), "directory")
        self.assertEqual(self.snapshot(self.repository), before)

    def test_nested_split_keeps_siblings_at_each_level(self):
        for rel in ("settings/root", "settings/app/other", "settings/app/deep/keep",
                    "settings/app/deep/remove", "settings/other-app/file"):
            self.source(rel, rel)
        self.managed_link("settings", relative=True)
        before = self.snapshot(self.repository)
        manager = self.manager()
        manager.toggle("settings/app/deep/remove")
        expected = {"settings/root", "settings/app/other", "settings/app/deep/keep", "settings/other-app"}
        self.assertEqual(manager.desired, expected)
        self.assertEqual([op.rel for op in manager.plan().operations if op.action == "mkdir"],
                         ["settings", "settings/app", "settings/app/deep"])
        manager.apply()
        self.assertEqual(manager.existing, expected)
        self.assertFalse(os.path.lexists(self.home / "settings/app/deep/remove"))
        for rel in expected:
            self.assert_owned_link(rel)
        self.assertEqual(self.snapshot(self.repository), before)

    def test_unchecking_only_child_removes_parent_without_empty_replacement(self):
        self.source("settings/only")
        self.managed_link("settings")
        manager = self.manager()
        manager.toggle("settings/only")
        self.assertEqual(manager.desired, set())
        self.assertEqual([op.action for op in manager.plan().operations], ["unlink"])
        manager.apply()
        self.assertFalse(os.path.lexists(self.home / "settings"))
        self.assertTrue((self.repository / "settings/only").is_file())

    def test_collapse_managed_children_and_empty_directories_into_parent(self):
        self.source("settings/a")
        self.source("settings/nested/b")
        self.managed_link("settings/a", relative=True)
        self.managed_link("settings/nested/b")
        (self.home / "settings/empty/deep").mkdir(parents=True)
        before = self.snapshot(self.repository)
        manager = self.manager()
        manager.toggle("settings")
        self.assertEqual(manager.desired, {"settings"})
        self.assertEqual([(op.action, op.rel) for op in manager.plan().operations], [
            ("unlink", "settings/a"), ("unlink", "settings/nested/b"),
            ("rmdir", "settings/empty/deep"), ("rmdir", "settings/empty"),
            ("rmdir", "settings/nested"), ("rmdir", "settings"),
            ("link", "settings"),
        ])
        manager.apply()
        self.assert_owned_link("settings")
        self.assertEqual(manager.existing, {"settings"})
        self.assertEqual(self.snapshot(self.repository), before)

    def test_unlink_managed_children_retains_unrelated_files_and_directories(self):
        self.source("settings/a")
        self.source("settings/nested/b")
        self.managed_link("settings/a")
        self.managed_link("settings/nested/b")
        self.local("settings/local", "keep me")
        (self.home / "settings/empty").mkdir()
        (self.home / "settings/foreign").symlink_to("nowhere")
        manager = self.manager()
        manager.toggle("settings/a")
        manager.toggle("settings/nested/b")
        self.assertEqual([op.action for op in manager.plan().operations], ["unlink", "unlink"])
        manager.apply()
        self.assertEqual(self.snapshot(self.home), {
            "settings": ("directory",),
            "settings/empty": ("directory",),
            "settings/foreign": ("link", "nowhere"),
            "settings/local": ("file", b"keep me"),
            "settings/nested": ("directory",),
        })

    def test_empty_source_directory_can_be_linked_and_unlinked(self):
        self.source_dir("empty")
        manager = self.manager()
        self.assertEqual(manager.nodes["empty"], Node("empty", True, ()))
        manager.toggle("empty")
        self.assertEqual(manager.selection_state("empty"), "all")
        manager.apply()
        self.assert_owned_link("empty")
        manager.toggle("empty")
        manager.apply()
        self.assertFalse(os.path.lexists(self.home / "empty"))
        self.assertTrue((self.repository / "empty").is_dir())

    def test_empty_destination_directory_can_be_replaced(self):
        self.source("settings/file")
        (self.home / "settings").mkdir()
        manager = self.manager()
        self.assertEqual(manager.status("settings"), "directory")
        manager.toggle("settings")
        self.assertEqual([op.action for op in manager.plan().operations], ["rmdir", "link"])
        manager.apply()
        self.assert_owned_link("settings")

    def test_toggle_changes_staging_only_and_invalid_path_does_not_change_it(self):
        self.source("settings/a")
        self.source("settings/b")
        manager = self.manager()
        before = self.snapshot(self.home)
        manager.toggle("settings/a")
        self.assertEqual(manager.selection_state("settings/a"), "all")
        self.assertEqual(manager.selection_state("settings/b"), "none")
        self.assertEqual(manager.selection_state("settings"), "some")
        manager.toggle("settings")
        self.assertEqual(manager.desired, {"settings"})
        manager.toggle("settings")
        self.assertEqual(manager.desired, set())
        with self.assertRaises(KeyError):
            manager.toggle("does-not-exist")
        self.assertEqual(manager.desired, set())
        self.assertEqual(self.snapshot(self.home), before)

    def test_selection_state_accepts_explicit_empty_and_independent_roots(self):
        self.source("settings/a")
        self.source("settings/b")
        manager = self.manager()
        manager.toggle("settings")
        self.assertEqual(manager.selection_state("settings/a", roots=set()), "none")
        self.assertEqual(manager.selection_state("settings", roots={"settings/a"}), "some")
        self.assertEqual(manager.selection_state("settings/b", roots={"settings/a"}), "none")
        self.assertEqual(manager.desired, {"settings"})

    def test_path_prefix_does_not_confuse_sibling_names(self):
        self.source("app/file")
        self.source("application/file")
        manager = self.manager()
        manager.toggle("app")
        self.assertEqual(manager.selection_state("application"), "none")
        manager.toggle("application/file")
        manager.apply()
        self.assertEqual(manager.status("application/file"), "linked")
        manager.toggle("app/file")
        manager.apply()
        self.assertFalse(os.path.lexists(self.home / "app"))
        self.assert_owned_link("application/file")

    def test_real_destination_file_never_overwritten_even_if_contents_match(self):
        self.source(".zshrc", "same")
        self.local(".zshrc", "same")
        manager = self.manager()
        self.assertEqual(manager.status(".zshrc"), "conflict")
        manager.toggle(".zshrc")
        self.assert_conflict_without_changes(manager)

    def test_directory_at_file_destination_with_local_contents_blocks_link(self):
        self.source("settings")
        self.local("settings/local")
        manager = self.manager()
        self.assertEqual(manager.status("settings"), "conflict")
        manager.toggle("settings")
        self.assert_conflict_without_changes(manager)

    def test_foreign_and_dangling_destination_symlinks_never_overwritten(self):
        self.source("file")
        external = self.base / "external"
        external.write_text("external data")
        targets = [external, self.base / "missing", self.repository / "other", "missing-relative"]
        for target in targets:
            with self.subTest(target=target):
                path = self.home / "file"
                path.symlink_to(target)
                manager = self.manager()
                self.assertEqual(manager.existing, set())
                self.assertEqual(manager.status("file"), "conflict")
                manager.toggle("file")
                self.assert_conflict_without_changes(manager)
                self.assertEqual(external.read_text(), "external data")
                path.unlink()

    def test_foreign_parent_symlinks_are_not_traversed_or_modified(self):
        self.source("settings/file")
        self.source("other/file", "different repository path")
        external = self.base / "external"
        external.mkdir()
        (external / "file").symlink_to(self.repository / "settings/file")
        targets = [external, self.repository / "other", self.repository,
                   self.base / "missing", "missing-relative"]
        for target in targets:
            with self.subTest(target=target):
                path = self.home / "settings"
                path.symlink_to(target)
                before_external = self.snapshot(external)
                manager = self.manager()
                self.assertEqual(manager.existing, set())
                self.assertEqual(manager.status("settings"), "conflict")
                self.assertEqual(manager.status("settings/file"), "conflict")
                manager.toggle("settings/file")
                self.assert_conflict_without_changes(manager)
                self.assertEqual(self.snapshot(external), before_external)
                path.unlink()

    def test_dotdot_after_symlink_in_target_is_foreign_not_owned(self):
        # Known bug in owned(): abspath() collapses alias/.. before resolving
        # alias, incorrectly treating this foreign link as repo/file. Toggling
        # it off then deletes the foreign link instead of reporting a conflict.
        self.source("file", "repository")
        external = self.base / "outside"
        (external / "deep").mkdir(parents=True)
        (external / "repo").mkdir()
        (external / "repo/file").write_text("foreign")
        (self.base / "alias").symlink_to(external / "deep", target_is_directory=True)
        path = self.home / "file"
        path.symlink_to("../alias/../repo/file")
        self.assertEqual(path.resolve(), external / "repo/file")
        self.assertEqual(path.read_text(), "foreign")
        manager = self.manager()
        self.assertEqual(manager.existing, set())
        self.assertEqual(manager.status("file"), "conflict")
        manager.toggle("file")
        self.assert_conflict_without_changes(manager)

    def test_real_file_in_parent_position_blocks_nested_link(self):
        self.source("settings/app/file")
        self.local("settings", "not a directory")
        manager = self.manager()
        self.assertEqual(manager.status("settings/app/file"), "conflict")
        manager.toggle("settings/app/file")
        self.assert_conflict_without_changes(manager)

    def test_foreign_contents_block_full_directory_collapse_before_any_unlink(self):
        self.source("settings/managed")
        external = self.base / "external"
        external.mkdir()
        cases = ("file", "nested-file", "foreign-link", "dangling-link")
        for kind in cases:
            with self.subTest(kind=kind):
                self.managed_link("settings/managed")
                if kind == "file":
                    obstacle = self.local("settings/local")
                elif kind == "nested-file":
                    obstacle = self.local("settings/nested/local")
                else:
                    obstacle = self.home / "settings/local-link"
                    obstacle.symlink_to(external if kind == "foreign-link" else self.base / "absent")
                manager = self.manager()
                manager.toggle("settings")
                self.assert_conflict_without_changes(manager)
                self.assert_owned_link("settings/managed")
                obstacle.unlink()
                if kind == "nested-file":
                    obstacle.parent.rmdir()
                (self.home / "settings/managed").unlink()

    def test_unmanaged_link_into_repository_also_blocks_collapse(self):
        self.source("settings/managed")
        self.managed_link("settings/managed")
        (self.home / "settings/alias").symlink_to(self.repository / "settings/managed")
        manager = self.manager()
        self.assertEqual(manager.existing, {"settings/managed"})
        manager.toggle("settings")
        self.assert_conflict_without_changes(manager)

    def test_conflict_on_one_selection_prevents_other_valid_selection_writes(self):
        self.source("a-good")
        self.source("z-conflict")
        self.local("z-conflict")
        manager = self.manager()
        manager.toggle("a-good")
        manager.toggle("z-conflict")
        self.assert_conflict_without_changes(manager)
        self.assertFalse(os.path.lexists(self.home / "a-good"))

    def test_source_directory_symlink_is_leaf_not_recursively_scanned(self):
        self.source("actual/file", "source")
        (self.repository / "alias").symlink_to("actual", target_is_directory=True)
        manager = self.manager()
        self.assertEqual(manager.nodes["alias"], Node("alias", False, ()))
        self.assertNotIn("alias/file", manager.nodes)
        manager.toggle("alias")
        manager.apply()
        self.assert_owned_link("alias")
        self.assertEqual(manager.existing, {"alias"})
        self.assertEqual((self.home / "alias/file").read_text(), "source")
        manager.toggle("alias")
        manager.apply()
        self.assertEqual(os.readlink(self.repository / "alias"), "actual")
        self.assertTrue((self.repository / "actual/file").is_file())

    def test_dangling_source_symlink_is_owned_leaf(self):
        (self.repository / "broken").symlink_to("missing")
        manager = self.manager()
        self.assertFalse(manager.nodes["broken"].is_dir)
        manager.toggle("broken")
        manager.apply()
        self.assertTrue((self.home / "broken").is_symlink())
        self.assertFalse((self.home / "broken").exists())
        self.assertEqual(manager.existing, {"broken"})
        self.assertEqual(manager.status("broken"), "linked")
        manager.toggle("broken")
        manager.apply()
        self.assertFalse(os.path.lexists(self.home / "broken"))
        self.assertEqual(os.readlink(self.repository / "broken"), "missing")

    def test_link_resolving_to_source_symlink_target_is_not_owned(self):
        self.source("actual")
        (self.repository / "alias").symlink_to("actual")
        (self.home / "alias").symlink_to(self.repository / "actual")
        manager = self.manager()
        self.assertEqual(manager.existing, set())
        self.assertEqual(manager.status("alias"), "conflict")
        manager.toggle("alias")
        self.assert_conflict_without_changes(manager)

    def test_source_symlink_to_external_directory_does_not_scan_external_files(self):
        external = self.base / "external"
        external.mkdir()
        (external / "private").write_text("leave alone")
        (self.repository / "alias").symlink_to(external, target_is_directory=True)
        before_external = self.snapshot(external)
        manager = self.manager()
        self.assertEqual(set(manager.nodes), {"alias"})
        manager.toggle("alias")
        manager.apply()
        manager.toggle("alias")
        manager.apply()
        self.assertEqual(self.snapshot(external), before_external)

    def test_refresh_discards_staging_and_rescans_sources_and_owned_links(self):
        self.source("first")
        self.source("second")
        manager = self.manager()
        manager.toggle("first")
        self.source("new/.hidden")
        self.managed_link("second")
        manager.refresh()
        self.assertEqual(manager.existing, {"second"})
        self.assertEqual(manager.desired, {"second"})
        self.assertIn("new/.hidden", manager.nodes)
        self.assertIn("new", manager.roots)
        (self.repository / "first").unlink()
        manager.refresh()
        self.assertNotIn("first", manager.nodes)

    def test_noop_apply_and_plan_are_empty_and_do_not_touch_links(self):
        self.source("file")
        path = self.managed_link("file", relative=True)
        before = self.snapshot(self.home)
        manager = self.manager()
        self.assertEqual(manager.plan(), Plan(()))
        self.assertEqual(manager.apply(Plan(())), Plan(()))
        self.assertEqual(self.snapshot(self.home), before)
        self.assertEqual(os.readlink(path), "../repo/file")

    def test_review_rejects_changed_selection_without_filesystem_writes(self):
        self.source("a")
        self.source("b")
        manager = self.manager()
        manager.toggle("a")
        reviewed = manager.plan()
        manager.toggle("b")
        before = self.snapshot(self.home)
        with self.assertRaisesRegex(Conflict, "changed since review"):
            manager.apply(reviewed)
        self.assertEqual(self.snapshot(self.home), before)
        self.assertEqual(manager.desired, {"a", "b"})

    def test_review_rejects_parent_directory_created_after_review(self):
        self.source("settings/file")
        manager = self.manager()
        manager.toggle("settings/file")
        reviewed = manager.plan()
        (self.home / "settings").mkdir()
        before = self.snapshot(self.home)
        with self.assertRaisesRegex(Conflict, "changed since review"):
            manager.apply(reviewed)
        self.assertEqual(self.snapshot(self.home), before)
        manager.apply(manager.plan())
        self.assert_owned_link("settings/file")

    def test_review_rejects_destination_file_created_after_review(self):
        self.source("file")
        manager = self.manager()
        manager.toggle("file")
        reviewed = manager.plan()
        self.local("file", "created after review")
        self.assert_conflict_without_changes(manager, reviewed)

    def test_review_rejects_foreign_contents_added_before_directory_collapse(self):
        self.source("settings/managed")
        self.managed_link("settings/managed")
        manager = self.manager()
        manager.toggle("settings")
        reviewed = manager.plan()
        self.local("settings/local", "added after review")
        self.assert_conflict_without_changes(manager, reviewed)
        self.assert_owned_link("settings/managed")

    def test_source_deletion_after_review_requires_refresh_without_writes(self):
        self.source("settings/a")
        deleted = self.source("settings/b")
        self.managed_link("settings", relative=True)
        manager = self.manager()
        manager.toggle("settings/a")
        reviewed = manager.plan()
        deleted.unlink()
        before_home = self.snapshot(self.home)
        before_repository = self.snapshot(self.repository)

        with self.assertRaisesRegex(Conflict, "[Rr]efresh"):
            manager.plan()
        with self.assertRaisesRegex(Conflict, "[Rr]efresh"):
            manager.apply(reviewed)
        self.assertEqual(self.snapshot(self.home), before_home)
        self.assertEqual(self.snapshot(self.repository), before_repository)
        manager.refresh()
        self.assertNotIn("settings/b", manager.nodes)
        self.assertEqual(manager.existing, {"settings"})
        self.assertEqual(manager.desired, manager.existing)

    def test_source_sibling_added_after_review_requires_refresh_without_writes(self):
        self.source("settings/a")
        self.source("settings/b")
        self.managed_link("settings", relative=True)
        manager = self.manager()
        manager.toggle("settings/a")
        reviewed = manager.plan()
        # Splitting with a stale source tree would silently omit this new sibling.
        self.source("settings/c", "added after review")
        before_home = self.snapshot(self.home)
        before_repository = self.snapshot(self.repository)

        with self.assertRaisesRegex(Conflict, "[Rr]efresh"):
            manager.plan()
        with self.assertRaisesRegex(Conflict, "[Rr]efresh"):
            manager.apply(reviewed)
        self.assertEqual(self.snapshot(self.home), before_home)
        self.assertEqual(self.snapshot(self.repository), before_repository)
        manager.refresh()
        self.assertIn("settings/c", manager.nodes)
        self.assertEqual(manager.existing, {"settings"})
        self.assertEqual(manager.desired, manager.existing)

    def test_external_owned_link_changes_require_refresh(self):
        self.source("a")
        self.source("b")
        path = self.managed_link("a")
        manager = self.manager()
        manager.toggle("a")
        reviewed = manager.plan()
        path.unlink()
        path.symlink_to(self.base / "foreign")
        self.assert_conflict_without_changes(manager, reviewed)
        manager.refresh()
        self.assertEqual(manager.existing, set())
        self.assertEqual(manager.status("a"), "conflict")
        self.managed_link("b")
        with self.assertRaisesRegex(Conflict, "Links changed"):
            manager.plan()
        manager.refresh()
        self.assertEqual(manager.existing, {"b"})

    def test_external_owned_link_removal_requires_refresh(self):
        self.source("file")
        path = self.managed_link("file")
        manager = self.manager()
        manager.toggle("file")
        reviewed = manager.plan()
        path.unlink()
        self.assert_conflict_without_changes(manager, reviewed)

    def test_review_detects_changed_raw_target_of_still_owned_link(self):
        self.source("file")
        path = self.managed_link("file", relative=True)
        manager = self.manager()
        manager.toggle("file")
        reviewed = manager.plan()
        path.unlink()
        path.symlink_to(self.repository / "file")
        before = self.snapshot(self.home)
        with self.assertRaisesRegex(Conflict, "changed since review"):
            manager.apply(reviewed)
        self.assertEqual(self.snapshot(self.home), before)
        manager.apply(manager.plan())
        self.assertFalse(os.path.lexists(path))

    def test_invalid_desired_paths_or_overlapping_roots_are_rejected(self):
        self.source("settings/file")
        manager = self.manager()
        for invalid in ({"../escape"}, {"unknown"}, {"settings", "settings/file"}):
            with self.subTest(selection=invalid):
                manager.desired = invalid
                self.assert_conflict_without_changes(manager)

    def test_link_failure_after_success_rolls_back_links_and_created_parents(self):
        self.source("settings/a")
        self.source("settings/b")
        manager = self.manager()
        manager.toggle("settings/a")
        manager.toggle("settings/b")
        before_home = self.snapshot(self.home)
        before_repository = self.snapshot(self.repository)
        original = manager._mutate
        attempted = []

        def fail_second(op, mode=None):
            if op.action == "link":
                attempted.append(self.home / op.rel)
                if op.rel == "settings/b":
                    self.assert_owned_link("settings/a")
                    raise OSError("injected second link failure")
            return original(op, mode=mode)

        with mock.patch.object(manager, "_mutate", new=fail_second):
            with self.assertRaisesRegex(Conflict, "No changes kept.*rollback completed"):
                manager.apply(manager.plan())
        self.assertEqual(attempted, [self.home / "settings/a", self.home / "settings/b"])
        self.assertEqual(self.snapshot(self.home), before_home)
        self.assertEqual(self.snapshot(self.repository), before_repository)
        self.assertEqual(manager.existing, set())
        self.assertEqual(manager.desired, {"settings/a", "settings/b"})
        manager.apply()
        self.assert_owned_link("settings/a")
        self.assert_owned_link("settings/b")

    def test_split_failure_restores_original_relative_directory_link(self):
        self.source("settings/a")
        self.source("settings/b")
        self.source("settings/c")
        self.managed_link("settings", relative=True)
        manager = self.manager()
        manager.toggle("settings/a")
        before_home = self.snapshot(self.home)
        before_repository = self.snapshot(self.repository)
        original = manager._mutate

        def fail_c(op, mode=None):
            if op.action == "link" and op.rel == "settings/c":
                self.assert_owned_link("settings/b")
                raise OSError("injected split failure")
            return original(op, mode=mode)

        with mock.patch.object(manager, "_mutate", new=fail_c):
            with self.assertRaisesRegex(Conflict, "rollback completed"):
                manager.apply()
        self.assertEqual(self.snapshot(self.home), before_home)
        self.assertEqual(self.snapshot(self.repository), before_repository)
        self.assertEqual(manager.existing, {"settings"})

    def test_collapse_failure_recreates_directories_and_original_child_links(self):
        self.source("settings/a")
        self.source("settings/nested/b")
        self.managed_link("settings/a", relative=True)
        self.managed_link("settings/nested/b", relative=True)
        (self.home / "settings/empty/deep").mkdir(parents=True)
        manager = self.manager()
        manager.toggle("settings")
        before_home = self.snapshot(self.home)
        before_repository = self.snapshot(self.repository)
        original = manager._mutate

        def fail_parent(op, mode=None):
            if op.action == "link" and op.rel == "settings":
                self.assertFalse(os.path.lexists(self.home / op.rel))
                raise OSError("injected collapse failure")
            return original(op, mode=mode)

        with mock.patch.object(manager, "_mutate", new=fail_parent):
            with self.assertRaisesRegex(Conflict, "rollback completed"):
                manager.apply()
        self.assertEqual(self.snapshot(self.home), before_home)
        self.assertEqual(self.snapshot(self.repository), before_repository)

    def test_keyboard_interrupt_before_split_mkdir_restores_original_link(self):
        self.source("settings/a")
        self.source("settings/b")
        self.managed_link("settings", relative=True)
        manager = self.manager()
        manager.toggle("settings/a")
        reviewed = manager.plan()
        before_home = self.snapshot(self.home)
        before_repository = self.snapshot(self.repository)
        original = manager._mutate
        interruption = KeyboardInterrupt("injected before replacement mkdir")

        def interrupt_mkdir(op, mode=None):
            if op.action == "mkdir" and op.rel == "settings":
                self.assertFalse(os.path.lexists(self.home / "settings"))
                raise interruption
            return original(op, mode=mode)

        with mock.patch.object(manager, "_mutate", new=interrupt_mkdir):
            with self.assertRaises(KeyboardInterrupt) as caught:
                manager.apply(reviewed)
        self.assertIs(caught.exception, interruption)
        self.assertEqual(self.snapshot(self.home), before_home)
        self.assertEqual(self.snapshot(self.repository), before_repository)
        self.assertEqual(manager.existing, {"settings"})
        self.assertEqual(manager.desired, {"settings/b"})
        manager.apply(reviewed)
        self.assert_owned_link("settings/b")
        self.assertFalse(os.path.lexists(self.home / "settings/a"))

    def test_collapse_rollback_restores_private_directory_mode(self):
        self.source("settings/file")
        self.managed_link("settings/file", relative=True)
        directory = self.home / "settings"
        directory.chmod(0o700)
        manager = self.manager()
        manager.toggle("settings")
        before_home = self.snapshot(self.home)
        before_repository = self.snapshot(self.repository)
        original = manager._mutate

        def fail_parent(op, mode=None):
            if op.action == "link" and op.rel == "settings":
                self.assertFalse(os.path.lexists(directory))
                raise OSError("injected failure after removing private directory")
            return original(op, mode=mode)

        with mock.patch.object(manager, "_mutate", new=fail_parent):
            with self.assertRaisesRegex(Conflict, "rollback completed"):
                manager.apply()
        self.assertEqual(self.snapshot(self.home), before_home)
        self.assertEqual(self.snapshot(self.repository), before_repository)
        self.assertEqual(stat.S_IMODE(directory.stat().st_mode), 0o700)

    def test_rollback_does_not_delete_replacement_foreign_link(self):
        self.source("a")
        self.source("b")
        external = self.base / "external"
        external.write_text("keep external")
        manager = self.manager()
        manager.toggle("a")
        manager.toggle("b")
        original = manager._mutate

        def replace_first_then_fail(op, mode=None):
            if op.action == "link" and op.rel == "b":
                (self.home / "a").unlink()
                (self.home / "a").symlink_to(external)
                raise OSError("injected failure after external replacement")
            return original(op, mode=mode)

        with mock.patch.object(manager, "_mutate", new=replace_first_then_fail):
            with self.assertRaisesRegex(Conflict, "Rollback incomplete") as caught:
                manager.apply()
        self.assertIn(str(self.home / "a"), str(caught.exception))
        self.assertEqual(os.readlink(self.home / "a"), str(external))
        self.assertEqual(external.read_text(), "keep external")
        self.assertFalse(os.path.lexists(self.home / "b"))
        manager.refresh()
        self.assertEqual(manager.existing, set())

    def test_destination_race_during_apply_never_overwrites_new_local_file(self):
        self.source("a")
        self.source("b")
        manager = self.manager()
        manager.toggle("a")
        manager.toggle("b")
        original = manager._mutate

        def create_conflict_before_second(op, mode=None):
            if op.action == "link" and op.rel == "b":
                (self.home / op.rel).write_text("concurrent local file")
            return original(op, mode=mode)

        with mock.patch.object(manager, "_mutate", new=create_conflict_before_second):
            with self.assertRaisesRegex(Conflict, "rollback completed"):
                manager.apply()
        self.assertFalse(os.path.lexists(self.home / "a"))
        self.assertFalse((self.home / "b").is_symlink())
        self.assertEqual((self.home / "b").read_text(), "concurrent local file")

    def test_parent_changed_to_foreign_symlink_during_apply_is_not_followed(self):
        self.source("a")
        self.source("settings/b")
        (self.home / "settings").mkdir()
        external = self.base / "external"
        external.mkdir()
        manager = self.manager()
        manager.toggle("a")
        manager.toggle("settings/b")
        original = manager._mutate

        def replace_parent_after_first(op, mode=None):
            result = original(op, mode=mode)
            if op.action == "link" and op.rel == "a":
                (self.home / "settings").rmdir()
                (self.home / "settings").symlink_to(external, target_is_directory=True)
            return result

        with mock.patch.object(manager, "_mutate", new=replace_parent_after_first):
            with self.assertRaises(Conflict):
                manager.apply()
        self.assertFalse(os.path.lexists(self.home / "a"))
        self.assertEqual(os.readlink(self.home / "settings"), str(external))
        self.assertEqual(self.snapshot(external), {})

    def test_parent_replaced_with_source_symlink_after_check_is_not_followed(self):
        self.source("a")
        self.source("settings/b")
        # Keep b absent in the replacement source directory: following this link
        # must not be masked by a harmless FileExistsError on an existing source.
        replacement = self.source_dir("other")
        parent = self.home / "settings"
        parent.mkdir()
        manager = self.manager()
        manager.toggle("a")
        manager.toggle("settings/b")
        reviewed = manager.plan()
        before_repository = self.snapshot(self.repository)
        original = manager._check_parent
        replaced = False

        def replace_parent_after_check(path):
            nonlocal replaced
            result = original(path)
            if path == parent / "b" and not replaced:
                parent.rmdir()
                parent.symlink_to(replacement, target_is_directory=True)
                replaced = True
            return result

        with mock.patch.object(manager, "_check_parent", new=replace_parent_after_check):
            with self.assertRaises(Conflict):
                manager.apply(reviewed)
        self.assertTrue(replaced, "race hook must run after the parent safety check")
        self.assertFalse(os.path.lexists(self.home / "a"))
        self.assertEqual(os.readlink(parent), str(replacement))
        self.assertFalse(os.path.lexists(replacement / "b"))
        self.assertEqual(self.snapshot(self.repository), before_repository)

    def test_scan_excludes_infrastructure_and_noise_but_keeps_hidden_untracked_files(self):
        for rel in (".git/config", ".jj/state", "tools/program.py", "tests/test.py",
                    "dotfiles/legacy", ".gitignore", "README.md", ".DS_Store",
                    "__pycache__/cache", ".config/.git/config", ".config/.jj/state",
                    ".config/__pycache__/cache", ".config/.DS_Store"):
            self.source(rel)
        included = {".zshrc", ".hidden/file", ".config/app/.secret", ".config/app/untracked",
                    ".config/tools/helper", ".config/tests/example", ".config/README.md",
                    ".config/.gitignore", "README.local", "tools-extra/file"}
        for rel in included:
            self.source(rel)
        manager = self.manager()
        expected = set(included)
        for rel in included:
            expected.update(parent.as_posix() for parent in Path(rel).parents if parent != Path("."))
        self.assertEqual(set(manager.nodes), expected)
        self.assertEqual(set(manager.roots), {rel for rel in expected if "/" not in rel})
        for rel, node in manager.nodes.items():
            self.assertEqual(node.rel, rel)
            if node.is_dir:
                self.assertEqual(set(node.children), {child for child in expected if Path(child).parent == Path(rel)})
            else:
                self.assertEqual(node.children, ())
        # No .git metadata exists that could mark these files tracked.
        manager.toggle(".config/app/untracked")
        manager.apply()
        self.assert_owned_link(".config/app/untracked")

    def test_scan_orders_directories_before_files_case_insensitively(self):
        self.source("z-dir/file")
        self.source("A-dir/file")
        self.source("B-file")
        self.source("a-file")
        manager = self.manager()
        self.assertEqual(manager.roots, ("A-dir", "z-dir", "a-file", "B-file"))
        self.assertIsInstance(manager.roots, tuple)
        self.assertIsInstance(manager.nodes["A-dir"].children, tuple)

    def test_empty_repository_produces_empty_plan(self):
        manager = self.manager()
        self.assertEqual(manager.nodes, {})
        self.assertEqual(manager.roots, ())
        self.assertEqual(manager.existing, set())
        self.assertEqual(manager.apply(), Plan(()))

    def test_missing_or_nondirectory_repository_and_home_are_rejected(self):
        file_path = self.base / "plain-file"
        file_path.write_text("not a directory")
        for repository, home in ((self.base / "absent", self.home),
                                 (self.repository, self.base / "absent"),
                                 (file_path, self.home), (self.repository, file_path)):
            with self.subTest(repository=repository, home=home):
                with self.assertRaises(Conflict):
                    LinkManager(repository, home)

    def test_home_equal_to_or_inside_repository_is_rejected(self):
        nested = self.source_dir("nested-home")
        for home in (self.repository, nested):
            with self.subTest(home=home):
                with self.assertRaises(Conflict):
                    LinkManager(self.repository, home)

    def test_aliased_home_and_repository_paths_are_normalized(self):
        self.source("file")
        repo_alias = self.base / "repo-alias"
        home_alias = self.base / "home-alias"
        repo_alias.symlink_to(self.repository, target_is_directory=True)
        home_alias.symlink_to(self.home, target_is_directory=True)
        (self.home / "file").symlink_to(repo_alias / "file")
        manager = LinkManager(repo_alias, home_alias)
        self.assertEqual(manager.repository, self.repository)
        self.assertEqual(manager.home, self.home)
        self.assertEqual(manager.existing, {"file"})
        manager.toggle("file")
        manager.apply()
        self.assertFalse(os.path.lexists(self.home / "file"))
        self.assertTrue((self.repository / "file").is_file())

    def test_destination_containing_repository_cannot_be_collapsed(self):
        nested_repository = self.home / "container/repo"
        nested_repository.mkdir(parents=True)
        (nested_repository / "container").mkdir()
        (nested_repository / "container/file").write_text("source")
        manager = LinkManager(nested_repository, self.home)
        manager.toggle("container")
        before = self.snapshot(self.home)
        with self.assertRaisesRegex(Conflict, "contains the repository"):
            manager.plan()
        with self.assertRaises(Conflict):
            manager.apply()
        self.assertEqual(self.snapshot(self.home), before)

    def test_destination_inside_repository_cannot_be_linked(self):
        self.repository = self.home / "repo"
        self.repository.mkdir()
        self.source("repo/file")
        destination = self.repository / "file"
        self.assertFalse(os.path.lexists(destination))
        manager = self.manager()
        manager.toggle("repo/file")
        self.assert_conflict_without_changes(manager)
        self.assertFalse(os.path.lexists(destination))

    def test_destination_inside_repository_cannot_unlink_source_symlink(self):
        self.repository = self.home / "repo"
        self.repository.mkdir()
        source = self.source("repo/file")
        # home/repo/file is both a source leaf and an apparently owned link for
        # repo/file. Unselecting it must not delete anything in the repository.
        destination = self.repository / "file"
        destination.symlink_to(source)
        manager = self.manager()
        self.assertIn("repo/file", manager.existing)
        manager.set_selected("repo/file", False)
        self.assertNotIn("repo/file", manager.desired)
        self.assert_conflict_without_changes(manager)
        self.assertEqual(os.readlink(destination), str(source))


if __name__ == "__main__":
    unittest.main()
