# Publishing to the existing public GitHub repository

The Windows entry point is `scripts/update_github.bat`, which invokes Windows
PowerShell with a process-local execution-policy setting. It does not change the
machine's execution policy. Git and authenticated GitHub access are needed for
publication; MATLAB is needed for the default test gate. Git's configured
name/email are used as the commit author.

From the G2 repository root, in Command Prompt:

```bat
scripts\update_github.bat
scripts\update_github.bat -Plan
scripts\update_github.bat -Publish -CommitMessage "Organize G2 and update documentation"
scripts\update_github.bat -Publish -SkipTests -CommitMessage "Organize G2 and update documentation"
```

No flags: list local files only, with no network or mutations.
`-Plan`: clone the remote default branch, stage the proposed synchronized tree,
show its diff summary, then remove the temporary clone. No commit/push.
`-Publish`: first run the complete MATLAB test suite, then prepare the tree in
the same way, create a commit and push normally. A command failure returns a
nonzero exit code and prevents subsequent publication steps.

`-Publish -SkipTests`: commit and push without launching MATLAB or requiring it
to be installed. Use this explicit option when publishing without the current
test run, for example when MATLAB graphics handshaking stalls. Tests remain
enabled by default; the Git synchronization and history preservation are the same.

## Manifest and synchronization

Published root files: `.gitignore`, `README.md`, `LICENSE.md`, `setup_g2.m`.
Published trees: `src`, `EXAMPLES`, `docs`, `data`, `tests`, `scripts`.
Results, legacy output directories, Python caches and editor backups are excluded.
The user-supplied ElCentro input is included in `data/earthquakes`; its provenance
limitations are recorded there. Source licensing remains in `LICENSE.md`.

This is a complete project-tree synchronization: remote tracked files absent
from the local manifest are deleted **in the temporary clone**. That removes old
root-level MATLAB classes and documents after their relocation. Existing remote
`.github` automation, `.gitattributes` and `.editorconfig` are preserved.
Use `-Plan` to inspect the actual additions/deletions before publishing.

The script discovers the remote default branch (verified as `master` during
preparation) and creates its commit on that branch's existing history. It does not
require shared ancestry with the local feature branch, change local remotes, reset
the local checkout or force-push. GitHub's existing history remains the parent of
the new commit. If the remote advances concurrently, Git rejects the push; rerun
to prepare from the new head. Branch protection and account permissions still apply.

No credentials are embedded. Authenticate using Git Credential Manager or your
existing Git configuration. A missing identity fails the commit rather than
inventing an author. The temporary clone is removed after success or failure;
the local source tree and Git history are retained for retries.

For isolated tests, `-RemoteUrl` can point to a local bare Git repository.
The default target is:
`https://github.com/mgrubisic/G2-MATLAB-predecessor-to-OpenSees.git`.
The provided script has been exercised against local Git fixtures; preparing
it does not publish anything to the public target.

Reproduce the Windows workflow checks with:

```sh
python -m unittest discover -s tests -p test_publishing.py -v
```

The fixture verifies preview/no-op behavior, ordinary pushes preserving ancestry,
remote automation preservation, output exclusions, paths and messages with
spaces, and failure of the pre-publication gate. A controlled MATLAB executable
is used for this workflow test; the real 52-test numerical suite is verified
separately. Optional `verify_examples` runs all six MATLAB demonstrations with
figure cleanup between them.
