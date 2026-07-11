---
name: breadcrumb-release
description: Run the migrated Breadcrumb release command. Use when the user asks for /breadcrumb-release, breadcrumb-release, $breadcrumb-release, or to cut, publish, tag, build, and install a new Breadcrumb release from the latest commits.
---

# Breadcrumb Release

Use this skill to cut a new Breadcrumb release from the current `master` branch.
Follow the flow exactly. Pause at the required user checkpoints; never skip
confirmations. Do not modify files until the final release confirmation is
accepted.

## Preconditions

- Work from `/Users/roger/Claude/Code/Breadcrumb`.
- Treat this as the Codex equivalent of the Claude Code `/breadcrumb-release`
  command.
- Run independent read-only checks in parallel when the current Codex toolset
  supports it.
- If anything unexpected appears, especially a dirty tree with changes you did
  not make, stop and ask the user before continuing.

## 1. Pre-flight

Change nothing. Abort on any failure except the known flaky test case below.

Run these checks:

- `git rev-parse --abbrev-ref HEAD` - must equal `master`.
- `git status --porcelain` - must be empty for tracked modifications and staged
  files. Untracked root scratch files `BUGS.md` and `UX.md` are allowed.
- `git fetch origin` followed by
  `git rev-list --left-right --count origin/master...HEAD` - must be `0  0`.
- `gh auth status` - must show an authenticated GitHub session.
- `xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb` - all tests
  except `KeychainHelperTests` must pass. If only `KeychainHelperTests` fails,
  warn and continue. Any other test failure aborts.
- `xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Release build`
  - must succeed.

If a check fails, report the failed check and stop. Do not modify anything.

## 2. Gather Inputs

Read `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` from `project.yml`; both
are quoted strings.

Ask the user which bump to apply:

- Patch: `0.3.3 -> 0.3.4` for bug fixes or small tweaks.
- Minor: `0.3.3 -> 0.4.0` for new features without breaking changes.
- Major: `0.3.3 -> 1.0.0` for milestones or breaking changes.

Compute the new `MARKETING_VERSION` from the answer. Always increment
`CURRENT_PROJECT_VERSION` by 1.

Capture the commits that will be included before bumping:

```bash
git describe --tags --abbrev=0
git log <lastTag>..HEAD --oneline
```

Show that commit list to the user.

Suggest 2-3 one-line release titles derived from the commit subjects and allow
freeform input. Title style:

```text
Short summary
```

The final GitHub release title must be:

```text
vX.Y.Z - Short summary
```

Build release notes as one bullet per commit subject, chronological order
oldest first:

```text
- Commit subject
- Commit subject
```

Show a final summary with new version, build number, title, notes, and commit
count. Ask exactly whether to cut release `vX.Y.Z`. If the user cancels, stop
with no modifications.

## 3. Execute

Run each step sequentially. If a step fails, stop immediately and print the
rollback guidance for that step from section 4. Never continue after a failed
step.

1. Edit `project.yml`, bumping `MARKETING_VERSION` and
   `CURRENT_PROJECT_VERSION`.
2. Run `xcodegen generate`.
3. Commit only the version bump and regenerated Xcode project:

   ```bash
   git add project.yml Breadcrumb.xcodeproj
   git commit -m "chore: bump version to X.Y.Z

   Co-Authored-By: Codex <noreply@openai.com>"
   ```

   Do not use `--no-verify`, `--no-gpg-sign`, or hook-skipping flags.

4. Tag:

   ```bash
   git tag vX.Y.Z
   ```

5. Push:

   ```bash
   git push origin master --tags
   ```

6. Build the DMG:

   ```bash
   ./scripts/build-dmg.sh
   ```

   Verify `build/Breadcrumb-vX.Y.Z.dmg` exists and is larger than 1 MB.

7. Create the GitHub release and capture the URL:

   ```bash
   gh release create vX.Y.Z --title "vX.Y.Z - Short summary" --notes "<notes>" build/Breadcrumb-vX.Y.Z.dmg
   ```

8. Install locally. These commands touch `/Applications` and may require Codex
   approval/escalation:

   ```bash
   pkill -x Breadcrumb || true
   find ~/Library/Developer/Xcode/DerivedData/Breadcrumb-*/Build/Products/Release -maxdepth 1 -name "Breadcrumb.app"
   rm -rf /Applications/Breadcrumb.app
   cp -R <found_app> /Applications/
   open /Applications/Breadcrumb.app
   ```

Print the release URL and new version when finished.

## 4. Rollback Guidance

Do not auto-rollback. Print the relevant state and recovery hint, then stop.

| Failed step | State | Recovery hint |
| --- | --- | --- |
| 1 edit | `project.yml` modified in working tree | `git restore project.yml` |
| 2 xcodegen | `project.yml` modified, project regenerated | `git restore project.yml && xcodegen generate` |
| 3 commit | files modified, no bump commit | `git restore project.yml && xcodegen generate` |
| 4 tag | bump commit exists locally, no tag | `git reset --soft HEAD~1 && git restore --staged project.yml && git restore project.yml && xcodegen generate` |
| 5 push | commit and tag are local only | fix the cause, then re-run `git push origin master --tags` |
| 6 DMG | tag is pushed to origin | fix the build, re-run `./scripts/build-dmg.sh`, then continue from release creation |
| 7 GitHub release | tag pushed, DMG built locally | re-run `gh release create` with the same args |
| 8 install | release is live | copy the app from the DMG manually |

## Notes

- `.claude/` and `build/` are gitignored; never commit them.
- Do not touch `BUGS.md` or `UX.md`.
- Use the globally configured git identity.
- Prefer modern Codex approval handling for commands that write outside the
  workspace or interact with GUI applications.
