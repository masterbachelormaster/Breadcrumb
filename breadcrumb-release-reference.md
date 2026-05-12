# Breadcrumb Release Workflow Reference

Reference document for replicating the `/breadcrumb-release` skill in another tool (e.g. Codex).

---

## Overview

A fully automated release pipeline with three interactive checkpoints. Nothing is modified until the user explicitly confirms. If any step fails mid-execution, the pipeline stops and prints rollback guidance — it never auto-rollbacks.

---

## Phase 1: Pre-flight (read-only)

Run all six checks in parallel. Abort on any failure (with one exception noted below).

| Check | Command | Pass condition |
|-------|---------|----------------|
| Branch | `git rev-parse --abbrev-ref HEAD` | Must equal `master` |
| Clean tree | `git status --porcelain` | Empty output (untracked scratch files like `BUGS.md`/`UX.md` are OK) |
| In sync with remote | `git fetch origin && git rev-list --left-right --count origin/master...HEAD` | `0  0` |
| GitHub auth | `gh auth status` | Authenticated |
| Tests | `xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb` | All pass **except** `KeychainHelperTests` (known flaky — warn and continue) |
| Release build | `xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Release build` | Succeeds |

**Key principle:** If any check fails, print what failed and stop. Do not modify anything.

---

## Phase 2: Gather inputs (3 interactive checkpoints)

### Step 2a — Read current version

Read `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` from `project.yml`.

### Step 2b — Ask: bump type

Prompt the user to choose:

- **Patch** — `0.3.3 → 0.3.4` (bug fixes, small tweaks)
- **Minor** — `0.3.3 → 0.4.0` (new features)
- **Major** — `0.3.3 → 1.0.0` (milestone/breaking)

Compute the new `MARKETING_VERSION`. Always increment `CURRENT_PROJECT_VERSION` by 1 regardless of bump type.

### Step 2c — Capture commit list

```bash
git describe --tags --abbrev=0          # find last release tag
git log <lastTag>..HEAD --oneline       # commits since that tag
```

Show the commit list to the user.

### Step 2d — Ask: release title

Suggest 2-3 titles derived from the commit messages, plus a freeform "Other" option. Style: `— Short summary` (e.g. `v0.6.3 — Tooltip labels & FocusMate session fix`).

### Step 2e — Build release notes

One bullet per commit (`- <subject line>`), chronological order (oldest first).

### Step 2f — Ask: final confirmation

Show a full summary (new version, title, notes, commit count) and ask `"Cut release vX.Y.Z?"` with Yes / Cancel. On Cancel, stop — nothing has been modified.

---

## Phase 3: Execute (sequential, fail-stop)

Each step runs only if the previous succeeded. On failure: stop, print rollback guidance (see Phase 4), do not continue.

### Step 3.1 — Bump version in `project.yml`

Edit `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` to the new values.

### Step 3.2 — Regenerate Xcode project

```bash
xcodegen generate
```

### Step 3.3 — Commit

```bash
git add project.yml Breadcrumb.xcodeproj
git commit -m "chore: bump version to X.Y.Z

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

No `--no-verify`. No hook skipping. Git identity: `masterbachelormaster / noreply` (already set globally).

### Step 3.4 — Tag

```bash
git tag vX.Y.Z
```

### Step 3.5 — Push

```bash
git push origin master --tags
```

### Step 3.6 — Build DMG

```bash
./scripts/build-dmg.sh
```

Verify `build/Breadcrumb-vX.Y.Z.dmg` exists and is >1MB.

### Step 3.7 — Create GitHub release

```bash
gh release create vX.Y.Z \
  --title "vX.Y.Z — Release title" \
  --notes "- commit 1
- commit 2
- commit 3" \
  build/Breadcrumb-vX.Y.Z.dmg
```

The DMG is attached as a release asset. Capture the release URL.

### Step 3.8 — Install locally

```bash
pkill -x Breadcrumb || true
# Find the Release build:
find ~/Library/Developer/Xcode/DerivedData/Breadcrumb-*/Build/Products/Release \
  -maxdepth 1 -name "Breadcrumb.app"
rm -rf /Applications/Breadcrumb.app
cp -R <found_app> /Applications/
open /Applications/Breadcrumb.app
```

Print the release URL and new version. Done.

---

## Phase 4: Rollback guidance (on failure)

Never auto-rollback. Print the current state and recovery hint.

| Failed at | What's been modified | Recovery |
|-----------|---------------------|----------|
| Step 3.1 (edit) | `project.yml` dirty | `git restore project.yml` |
| Step 3.2 (xcodegen) | `project.yml` + `.xcodeproj` dirty | `git restore project.yml && xcodegen generate` |
| Step 3.3 (commit) | Files dirty, no commit yet | `git restore project.yml && xcodegen generate` |
| Step 3.4 (tag) | Commit exists locally, no tag | `git reset --soft HEAD~1 && git restore --staged . && git restore project.yml && xcodegen generate` |
| Step 3.5 (push) | Commit + tag local only | Fix cause, re-run `git push origin master --tags` |
| Step 3.6 (DMG) | Tag is pushed to remote | Fix build, re-run `./scripts/build-dmg.sh`, then continue from step 3.7 |
| Step 3.7 (gh release) | Tag pushed, DMG built | Re-run `gh release create` with same args |
| Step 3.8 (install) | Release is live | Copy from DMG manually |

---

## Design Principles

1. **Nothing modified until user confirms** — all validation and input gathering is read-only
2. **Three interactive checkpoints** — bump type, release title, final go/no-go
3. **Sequential execution with fail-stop** — step N+1 never runs if step N failed
4. **No hook skipping** — never `--no-verify`, `--no-gpg-sign`, etc.
5. **DMG attached to GitHub release** — not just a tag, users get a downloadable installer
6. **Local install as final step** — developer immediately runs what was released
7. **Manual rollback only** — the tool prints guidance but never undoes things automatically (too risky)
8. **Known-flaky tests tolerated** — `KeychainHelperTests` fails in non-interactive contexts; warn but don't block

---

## Adapting for Codex

Things to adjust when porting:

- **Interactive prompts**: Replace `AskUserQuestion` with whatever Codex uses for user input
- **Tool-specific commands**: `xcodebuild`, `xcodegen`, `build-dmg.sh` are project-specific — swap for your build system
- **Version file**: This reads/writes `project.yml` — adapt to `package.json`, `Cargo.toml`, etc.
- **GitHub CLI**: `gh release create` with asset attachment — works the same in any environment
- **Co-author footer**: Update the model name/version in the commit footer
- **Git identity**: Hardcoded to a specific GitHub username — make configurable
