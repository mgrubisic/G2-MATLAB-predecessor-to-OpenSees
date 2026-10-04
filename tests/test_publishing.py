"""Windows publishing integration checks against local Git, never GitHub.

Run: python -m unittest discover -s tests -p test_publishing.py -v
MATLAB's gate is a controlled executable here; the real suite is tested separately.
"""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(os.name == "nt", "Windows batch/PowerShell utility")
class PublishingTest(unittest.TestCase):
    def test_plan_publish_history_and_failed_gate(self):
        # All fixture file operations stay under our own temporary results tree.
        (ROOT / "results").mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="publishing-", dir=ROOT / "results") as directory:
            fixture = Path(directory)
            self.assertTrue(fixture.resolve().is_relative_to((ROOT / "results").resolve()))
            project = fixture / "project with spaces"
            project.mkdir()
            for name in ("src", "EXAMPLES", "docs", "data", "tests", "scripts"):
                shutil.copytree(ROOT / name, project / name)
            for name in ("README.md", "LICENSE.md", "setup_g2.m", ".gitignore"):
                shutil.copy2(ROOT / name, project / name)
            # Generated and unrelated data must not enter the publishing manifest.
            (project / "results").mkdir()
            (project / "results" / "private-output.txt").write_text("generated")
            (project / "EXAMPLES" / "output").mkdir()
            (project / "EXAMPLES" / "output" / "ignored.txt").write_text("generated")
            (project / "sibling-reference.txt").write_text("not a G2 publication file")
            remote = fixture / "remote.git"
            seed = fixture / "seed"
            seed.mkdir()
            environment = os.environ.copy()
            environment.update(GIT_AUTHOR_NAME="Fixture", GIT_AUTHOR_EMAIL="fixture@example.invalid",
                               GIT_COMMITTER_NAME="Fixture", GIT_COMMITTER_EMAIL="fixture@example.invalid")

            def command(args, *, check=True):
                result = subprocess.run(args, env=environment, text=True, capture_output=True)
                if check and result.returncode:
                    self.fail(result.stdout + result.stderr)
                return result

            command(["git", "init", "--bare", "--initial-branch=master", str(remote)])
            command(["git", "init", "--initial-branch=master", str(seed)])
            (seed / "README.md").write_text("old project")
            (seed / "@model").mkdir()
            (seed / "@model" / "model.m").write_text("old model")
            (seed / ".github" / "workflows").mkdir(parents=True)
            (seed / ".github" / "workflows" / "preserved.yml").write_text("# remote metadata")
            command(["git", "-C", str(seed), "add", "."])
            command(["git", "-C", str(seed), "commit", "-m", "Original history"])
            command(["git", "-C", str(seed), "push", str(remote), "master"])

            def head():
                return command(["git", "--git-dir", str(remote), "rev-parse", "master"]).stdout.strip()

            initial = head()
            shim = fixture / "bin"
            shim.mkdir()
            matlab = shim / "matlab.bat"
            matlab.write_text("@echo off\nexit /b 0\n")
            environment["PATH"] = str(shim) + os.pathsep + environment["PATH"]
            batch = project / "scripts" / "update_github.bat"

            def batch_command(*args, check=True):
                # CMD /S needs an outer quote pair around a quoted executable.
                line = subprocess.list2cmdline([str(batch), *args])
                return command('cmd.exe /d /s /c "' + line + '"', check=check)

            manifest = batch_command().stdout
            self.assertIn("src/@model/model.m", manifest)
            self.assertNotIn("private-output.txt", manifest)
            self.assertNotIn("ignored.txt", manifest)
            self.assertNotIn("sibling-reference.txt", manifest)
            plan = batch_command("-Plan", "-RemoteUrl", str(remote))
            self.assertIn("Plan complete", plan.stdout)
            self.assertEqual(head(), initial)
            message = "Fixture update with spaces & parentheses (safe)"
            batch_command("-Publish", "-RemoteUrl", str(remote), "-CommitMessage", message)
            updated = head()
            self.assertNotEqual(updated, initial)
            command(["git", "--git-dir", str(remote), "merge-base", "--is-ancestor", initial, updated])
            tree = command(["git", "--git-dir", str(remote), "ls-tree", "-r", "--name-only", "master"]).stdout
            self.assertIn("src/@model/model.m", tree)
            self.assertNotIn("\n@model/model.m", tree)
            self.assertIn(".github/workflows/preserved.yml", tree)
            self.assertNotIn("private-output.txt", tree)
            self.assertNotIn("EXAMPLES/output/", tree)
            committed_message = command(["git", "--git-dir", str(remote), "log", "-1", "--format=%s"]).stdout.strip()
            self.assertEqual(committed_message, message)
            again = batch_command("-Plan", "-RemoteUrl", str(remote))
            self.assertIn("already matches", again.stdout)
            marker = fixture / "matlab-called.txt"
            environment["MATLAB_TEST_MARKER"] = str(marker)
            matlab.write_text('@echo off\necho invoked> "%MATLAB_TEST_MARKER%"\nexit /b 1\n')
            failed = batch_command("-Publish", "-RemoteUrl", str(remote), check=False)
            self.assertNotEqual(failed.returncode, 0)
            self.assertEqual(head(), updated)
            self.assertTrue(marker.exists())
            marker.unlink()
            with (project / "README.md").open("a", encoding="utf-8") as stream:
                stream.write("\nFixture change for publication without MATLAB.\n")
            skipped = batch_command("-Publish", "-SkipTests", "-RemoteUrl", str(remote),
                                    "-CommitMessage", "Publish without MATLAB tests")
            self.assertIn("MATLAB tests skipped", skipped.stdout)
            self.assertFalse(marker.exists(), "SkipTests must not invoke MATLAB")
            self.assertNotEqual(head(), updated)
            command(["git", "--git-dir", str(remote), "merge-base", "--is-ancestor", updated, head()])
            self.assertEqual((project / "results" / "private-output.txt").read_text(), "generated")


if __name__ == "__main__":
    unittest.main()
