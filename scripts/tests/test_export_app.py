"""Test publication, rollback and mutual exclusion using isolated export directories."""

import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / "export_app.py"
SPEC = importlib.util.spec_from_file_location("export_app", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class ExportAppTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.output = self.root / "output/runtime"
        self.output.mkdir(parents=True)
        (self.output / "old-app").write_text("previous", encoding="utf-8")

    def install(self, command, check):
        self.assertTrue(check)
        prefix = Path(command[command.index("--prefix") + 1])
        candidate = prefix / "runtime"
        candidate.mkdir()
        (candidate / "new-app").write_text("current", encoding="utf-8")

    def export(self):
        MODULE.export_app("cmake", self.root / "build", "Release", self.output)

    def test_successful_export_replaces_old_files_and_can_repeat(self):
        with patch.object(MODULE.subprocess, "run", side_effect=self.install):
            self.export()
            self.export()
        self.assertEqual([path.name for path in self.output.iterdir()], ["new-app"])
        self.assertEqual(list(self.output.parent.glob(".runtime-*")), [])

    def test_failed_install_preserves_previous_export(self):
        failure = subprocess.CalledProcessError(1, ["cmake", "--install"])
        with patch.object(MODULE.subprocess, "run", side_effect=failure):
            with self.assertRaises(subprocess.CalledProcessError):
                self.export()
        self.assertEqual((self.output / "old-app").read_text(), "previous")
        self.assertEqual(list(self.output.parent.glob(".runtime-*")), [])

    def test_failed_publication_restores_previous_export(self):
        original_rename = Path.rename

        def rename(source, target):
            if source.name == "runtime" and source != self.output:
                raise OSError("Simulated publication failure")
            return original_rename(source, target)

        with patch.object(MODULE.subprocess, "run", side_effect=self.install):
            with patch.object(Path, "rename", new=rename):
                with self.assertRaisesRegex(OSError, "Simulated publication failure"):
                    self.export()
        self.assertEqual((self.output / "old-app").read_text(), "previous")

    def test_failed_recovery_preserves_backup(self):
        original_rename = Path.rename

        def rename(source, target):
            if source != self.output and target == self.output:
                raise OSError("Simulated destination lock")
            return original_rename(source, target)

        with patch.object(MODULE.subprocess, "run", side_effect=self.install):
            with patch.object(Path, "rename", new=rename):
                with self.assertRaisesRegex(OSError, "Previous export preserved at"):
                    self.export()
        backups = list(self.output.parent.glob(".runtime-*/previous/old-app"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), "previous")

    def test_concurrent_export_cannot_acquire_same_output(self):
        with MODULE.lock_output(self.output):
            with self.assertRaises(OSError):
                with MODULE.lock_output(self.output):
                    self.fail("The output lock must exclude concurrent exporters")


if __name__ == "__main__":
    unittest.main()
