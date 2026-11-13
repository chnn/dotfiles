"""Exercise keyboard workflows with a fake terminal and isolated filesystems."""

from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from dotfiles_tui import App, clipped, safe_text, wrapped_lines
from dotlinks import LinkManager


class Screen:
    def __init__(self, keys, size=(24, 100)):
        self.keys = iter(keys)
        self.size = size
        self.frames = []
        self.lines = {}

    def getmaxyx(self):
        return self.size

    def keypad(self, value):
        pass

    def erase(self):
        self.lines = {}

    def addstr(self, y, x, value, attr):
        self.lines[y] = self.lines.get(y, "")[:x].ljust(x) + value

    def refresh(self):
        self.frames.append("\n".join(self.lines.values()))

    def get_wch(self):
        try:
            return next(self.keys)
        except StopIteration:
            raise AssertionError("UI did not exit before running out of test input")


class TuiTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="dotfiles-tui-")
        self.addCleanup(self.temporary.cleanup)
        self.base = Path(self.temporary.name).resolve()
        self.repository = self.base / "repo"
        self.home = self.base / "home"
        self.repository.mkdir()
        self.home.mkdir()
        (self.repository / "settings").mkdir()
        (self.repository / "settings/a").write_text("first")
        (self.repository / "settings/b").write_text("second")
        self.manager = LinkManager(self.repository, self.home)

    def run_ui(self, keys, size=(24, 100)):
        screen = Screen(keys, size)
        with mock.patch("dotfiles_tui.curses.curs_set"), mock.patch("dotfiles_tui.curses.has_colors", return_value=False):
            app = App(screen, self.manager)
        app.run()
        return screen, app

    def test_select_directory_review_and_apply(self):
        screen, _ = self.run_ui([" ", "a", "y", "q"])
        self.assertTrue((self.home / "settings").is_symlink())
        self.assertEqual(self.manager.existing, {"settings"})
        self.assertTrue(any("Review 1 filesystem operations" in frame for frame in screen.frames))
        self.assertTrue(any("Applied 1 operations successfully" in frame for frame in screen.frames))

    def test_unselect_child_of_linked_directory(self):
        (self.home / "settings").symlink_to(self.repository / "settings")
        self.manager.refresh()
        self.run_ui(["j", " ", "a", "y", "q"])
        self.assertFalse((self.home / "settings").is_symlink())
        self.assertFalse((self.home / "settings/a").exists())
        self.assertTrue((self.home / "settings/b").is_symlink())
        self.assertEqual((self.repository / "settings/a").read_text(), "first")

    def test_review_cancel_and_undo_do_not_touch_disk(self):
        screen, _ = self.run_ui([" ", "a", "n", "u", "q"])
        self.assertEqual(list(self.home.iterdir()), [])
        self.assertEqual(self.manager.desired, set())
        self.assertTrue(any("All staged changes discarded" in frame for frame in screen.frames))

    def test_quit_confirms_discard_without_applying(self):
        screen, _ = self.run_ui([" ", "q", "n", "q", "y"])
        self.assertEqual(list(self.home.iterdir()), [])
        self.assertTrue(any("Discard staged changes and quit?" in frame for frame in screen.frames))

    def test_minus_unselects_partial_directory_and_preserves_local_file(self):
        (self.home / "settings").mkdir()
        (self.home / "settings/a").symlink_to(self.repository / "settings/a")
        (self.home / "settings/b").write_text("local")
        self.manager.refresh()
        self.run_ui(["-", "a", "y", "q"])
        self.assertFalse((self.home / "settings/a").exists())
        self.assertEqual((self.home / "settings/b").read_text(), "local")

    def test_filter_selects_individual_file(self):
        self.run_ui(["/", "b", "\n", "j", " ", "a", "y", "q"])
        self.assertEqual(self.manager.existing, {"settings/b"})
        self.assertFalse((self.home / "settings/a").exists())

    def test_no_matches_ignores_selection_and_escape_clears_filter(self):
        _, app = self.run_ui(["/", "z", "\n", " ", "\x1b", "q"])
        self.assertEqual(app.query, "")
        self.assertEqual(list(self.home.iterdir()), [])

    def test_conflicting_file_reports_error_and_preserves_all_data(self):
        (self.home / "settings").mkdir()
        (self.home / "settings/a").write_text("local")
        screen, _ = self.run_ui(["j", " ", "a", "\n", "u", "q"])
        self.assertEqual((self.home / "settings/a").read_text(), "local")
        self.assertTrue(any("Changes could not be applied" in frame for frame in screen.frames))

    def test_right_on_expanded_empty_directory_does_not_jump_to_sibling(self):
        (self.repository / "empty").mkdir()
        self.manager.refresh()
        _, app = self.run_ui(["l", "q"])
        self.assertEqual(app.cursor, 0)

    def test_small_terminal_can_quit(self):
        screen, _ = self.run_ui(["q"], size=(10, 40))
        self.assertIn("Terminal too small", screen.frames[0])

    def test_cli_status_is_noninteractive_and_read_only(self):
        root = Path(__file__).resolve().parents[1]
        result = subprocess.run(
            [sys.executable, str(root / "dotfiles"), "--repo", str(self.repository), "--home", str(self.home), "--status"],
            capture_output=True, text=True, check=True,
        )
        self.assertIn("missing    settings/a", result.stdout)
        self.assertIn("0 direct symlinks", result.stdout)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_tui_rejects_noninteractive_input(self):
        root = Path(__file__).resolve().parents[1]
        result = subprocess.run(
            [sys.executable, str(root / "dotfiles"), "--repo", str(self.repository), "--home", str(self.home)],
            capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("interactive terminal", result.stderr)


class RenderingTests(unittest.TestCase):
    def test_clip_wide_and_combining_characters_by_cells(self):
        self.assertEqual(clipped("a界b", 3), "a界")
        self.assertEqual(clipped("e\u0301z", 1), "e\u0301")

    def test_control_characters_cannot_inject_terminal_sequences(self):
        text = safe_text("name\n\x1b[2J")
        self.assertNotIn("\x1b", text)
        self.assertNotIn("\n", text)
        self.assertIn("\\n", text)

    def test_review_wraps_long_paths_without_losing_suffixes(self):
        lines = ["  UNLINK settings/" + "a" * 70 + "-delete", "", "  LINK settings/" + "a" * 70 + "-keep"]
        wrapped = wrapped_lines(lines, 57)
        self.assertEqual("".join(wrapped), "".join(lines))
        self.assertTrue(all(len(line) <= 57 for line in wrapped))
        self.assertIn("-delete", "\n".join(wrapped))
        self.assertIn("-keep", "\n".join(wrapped))

    def test_wrapping_wide_paths_preserves_all_characters(self):
        source = "  LINK " + "界" * 50
        wrapped = wrapped_lines([source], 20)
        self.assertEqual("".join(wrapped), source)
        self.assertTrue(all(clipped(line, 20) == line for line in wrapped))


if __name__ == "__main__":
    unittest.main()
