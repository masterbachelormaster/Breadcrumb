# Breadcrumb — Bug Review Handoff

**Date:** 2026-04-16
**Scope:** Full bug hunt of `/Users/roger/Claude/Code/Breadcrumb` (macOS menu bar Pomodoro + project status tracker, Swift 6 / SwiftUI / SwiftData, target macOS 26).
**Method:** Opus 4.7 read-only review. No code changed.

This document is a handoff. Every finding includes file path, line number, reproduction steps, and fix direction — enough for a fresh Claude instance to pick up without re-reading the codebase.

**Context for the next Claude (non-negotiable):**
- User is non-technical and works solo. Skip PR suggestions — just commit, push, merge to `master`.
- User prefers small, targeted changes; over-engineering is the default tendency — actively restrain.
- All UI text MUST go through the `Strings` enum — never hardcode German/English in views.
- All `ModelContext.save()` calls MUST go through `saveWithLogging()`.
- Run `xcodegen generate` after adding/removing Swift files before building.
- Tests use Swift Testing (`@Test`, `@Suite`, `#expect`), not XCTest.
- Invoke Swift skills before writing code: `swiftui-pro`, `swiftdata-pro`, `swift-concurrency-pro`.
- Git identity: `masterbachelormaster` / `noreply@anthropic.com`. Never real name.
- Build + upload DMG for every release. No PRs.

---

## Table of Contents

1. [Critical Bugs](#critical-bugs) — data loss, silent corruption, wrong info to user
2. [High-Severity Bugs](#high-severity-bugs) — wrong behavior user will notice
3. [Medium-Severity Bugs](#medium-severity-bugs) — edge cases / latent
4. [Low / Suspected Bugs](#low--suspected-bugs)
5. [Recommended Work Order](#recommended-work-order)
6. [Hot-Spot Files](#hot-spot-files)

---

## Critical Bugs

### C1. Duplicate PomodoroSession saved on FocusMate "Save & Done"

- **Where:** `Breadcrumb/Views/PomodoroSessionEndView.swift:201-232` combined with `Breadcrumb/Views/PomodoroRunningView.swift:138-156`.
- **Bug:** `saveAndDone()` in `PomodoroSessionEndView` constructs a `PomodoroSession`, calls `modelContext.insert(session)`, saves, then also calls `onStopCompletely()`. The parent's `onStopCompletely` closure in `PomodoroRunningView` independently constructs a *second* `PomodoroSession`, inserts it, and saves again. Every successfully completed FocusMate session writes **two** session records.
- **Repro:**
  1. Start a FocusMate session.
  2. Let it finish (or stop).
  3. In the session-end overlay, fill the status form and press "Save & Done".
  4. Open Stats or History — the same session is recorded twice.
  5. `project.completedPomodoroCount` and `project.totalFocusTime` are both doubled for that session.
- **Fix direction:** In `saveAndDone()`, replace `onStopCompletely()` with a dedicated callback (e.g. `onFinished`) that only stops the timer. Alternative: have `saveAndDone()` emit the built `PomodoroSession` through a callback, and the parent closure only inserts if it wasn't already inserted (guard on identity).
- **Why this matters:** silently corrupts focus-time stats. No test covers this path — add one.

### C2. Phantom "work" session recorded when stopping after a break

- **Where:** `Breadcrumb/Views/PomodoroSessionEndView.swift:77` + `Breadcrumb/Views/PomodoroRunningView.swift:138-156`.
- **Bug:** The break-end variant (`breakEndContent`) exposes a "Stop Completely" button that calls `onStopCompletely()`. The parent closure unconditionally creates:
  ```swift
  PomodoroSession(
      sessionType: .work,
      plannedDuration: timer.originalDurationSeconds,
      sessionNumber: timer.currentSessionNumber
  )
  ```
  and inserts it. When the user presses Stop during a *break*, the app fabricates a fake completed work session that never occurred.
- **Repro:**
  1. Start Pomodoro, finish a work session (Save & Break).
  2. Let the break run to zero (or skip it).
  3. On the break-end screen, press "Stop Completely".
  4. A bogus `PomodoroSession(sessionType: .work, plannedDuration: workMinutes)` row is inserted.
- **Fix direction:** In the parent `onStopCompletely` closure, skip the session-construction block when `wasBreakEnd == true` (flag exists in `PomodoroSessionEndView`) OR when `timer.currentPhase` was a break / `.sessionEnded` after a break. Cleaner: split into `onStopAfterWork` and `onStopAfterBreak` closures.

### C3. App version hard-coded to "1.0" in all releases

- **Where:** `Breadcrumb/Info.plist:21-22` and `Breadcrumb/Views/AboutView.swift:51`.
- **Bug:** `project.yml` sets `MARKETING_VERSION: 0.3.2` (bumped per release), but the checked-in `Info.plist` literally contains:
  ```xml
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  ```
  rather than referencing `$(MARKETING_VERSION)`. The shipped binary at `~/Library/Developer/Xcode/DerivedData/Breadcrumb-.../Release/Breadcrumb.app/Contents/Info.plist` confirms built app reports version 1.0. AboutView reads this key and shows "Version 1.0" on every release.
- **Repro:** Open app → right-click menu bar → About. Says "Version 1.0" on every release (including current 0.3.2 DMG).
- **Fix direction:** Change `Info.plist`:
  ```xml
  <key>CFBundleShortVersionString</key>
  <string>$(MARKETING_VERSION)</string>
  <key>CFBundleVersion</key>
  <string>$(CURRENT_PROJECT_VERSION)</string>
  ```
  Preferred: delete the explicit `Info.plist` entirely and let Xcode synthesize one (requires `GENERATE_INFOPLIST_FILE = YES` in `project.yml`). Verify by building Release and inspecting the `.app`'s Info.plist.
- **Why this matters:** users cannot tell which version they have. Bug reports include wrong version.

---

## High-Severity Bugs

### H1. Stopping a running work session starts a break instead of stopping

- **Where:** `Breadcrumb/Views/PomodoroRunningView.swift:70-72, 198-202` and `PomodoroSessionEndView.swift:115-121` (workEndContent action wiring).
- **Bug:** `stopSession()` responds to the red "Stopp" button during a work phase by showing the session-end overlay with `wasBreakEnd = false`. In that overlay, the default (`.borderedProminent`) button is "Save & Break" which triggers `onSaveAndBreak → timer.startBreak()`. A user who pressed Stop intending to *end* the session, then types a status and hits the prominent button, accidentally starts a break.
- **Repro:**
  1. Start a Pomodoro work session.
  2. Press Stopp.
  3. Type a status note.
  4. Press "Speichern & Pause" (the default/prominent button).
  5. The app enters break phase instead of stopping.
- **Fix direction:** When the session-end overlay was triggered by a user Stop (not by timer completion), either hide/disable "Save & Break" and make "Stop Completely" the prominent default, or add a distinct overlay variant (`stopRequestedContent`) whose primary action is `onStopCompletely`. A `wasUserStop` conditional does it.

### H2. Work-session status entry may not be persisted (missing `modelContext.insert`)

- **Where:** `Breadcrumb/Views/PomodoroSessionEndView.swift:170-199` (`saveAndBreak()`).
- **Bug:** `saveAndBreak()` creates a `StatusEntry`, wires `entry.project = project` and `entry.session = session`, calls `project.entries.append(entry)`, but does **not** call `modelContext.insert(entry)`. The equivalent `saveAndDone()` at line 226 DOES insert it. `StatusEntryForm.save()` also inserts. Relying on SwiftData inverse-registration is fragile — on first insert of a detached object graph, SwiftData does not always auto-register every member. The parent callback `onSaveAndBreak` only inserts `session`. On devices where auto-registration fails, the status note silently disappears.
- **Repro:** Finish a work session, type a status, press "Speichern & Pause". Device-dependent: session appears in Stats but no `StatusEntry` appears in History.
- **Fix direction:** Add `modelContext.insert(entry)` in `saveAndBreak()` to mirror `saveAndDone()` and `StatusEntryForm.save()`. One line, immediately after constructing `entry`.

### H3. `AIFillerStripper` strips legitimate short user input

- **Where:** `Breadcrumb/Services/AIFillerStripper.swift:18-192`.
- **Bug:** Exact-match filler set includes single words like `"no"`, `"nein"`, `"ok"`, `"okay"`, `"clear"`, `"klar"`, `"passt"`, `"nothing"`, `"none"`, `"keine"`, `"null"`. The prefix list includes `"pending"`, `"no upcoming"`. Legitimate short answers ("ok") or sentences starting with these prefixes ("pending review from Sarah", "no upcoming conflicts — good") are silently wiped to `""`.
- **Repro:**
  1. Status freetext: "Tested build. No regressions."
  2. Run AI extract.
  3. AI returns `nextStep: "pending review from Sarah"`.
  4. After `AIFillerStripper.cleanLines` the field becomes empty.
  5. User sees empty Next Step.
- **Fix direction:**
  - Make prefix matching require a word-boundary + non-alphanumeric continuation so `"pending"` matches `"pending"` / `"pending."` but not `"pending review from Sarah"`.
  - Remove standalone generics like `"no"`, `"nein"`, `"ok"` from exact-match.
  - Update `BreadcrumbTests/AIFillerStripperTests.swift` — current tests (line 20-22) codify the over-stripping; rewrite to assert tightened behavior (see M5).

### H4. `openSettings` / `openAbout` notifications lost if popover never opened

- **Where:** `Breadcrumb/AppDelegate.swift:87-93` posts notifications. Only subscriber is `Breadcrumb/Views/ContentView.swift:88-95` inside `MenuBarExtra` content.
- **Bug:** `MenuBarExtra(style: .window)` does not guarantee content view is mounted before the popover is first opened. Right-clicking the menu bar icon on a fresh launch and choosing "Einstellungen…" / "Über" posts `.openSettings`/`.openAbout` into `NotificationCenter` — but no listener, menu item does nothing.
- **Repro:** Launch fresh → right-click menu bar icon → "Einstellungen…". Settings window may not open.
- **Fix direction:** Move `.onReceive(.openSettings)` / `.onReceive(.openAbout)` subscriptions out of popover content. Subscribe in `AppDelegate.applicationDidFinishLaunching` and call `WindowManager.open(.settings)` + trigger `openWindow(id: "main")` via a shared handle. Or add a lightweight always-alive SwiftUI scene hosting the subscription.

---

## Medium-Severity Bugs

### M1. FocusMate sessions inflate Pomodoro stats

- **Where:** `Breadcrumb/Models/Project.swift:36-45` + `Breadcrumb/Views/PomodoroRunningView.swift:120-149`.
- **Bug:** Every session-save path hardcodes `sessionType: .work`, but sets `isFocusMate = true` for FocusMate sessions. `project.completedPomodoroCount` filters by `sessionType == .work && completed` — FocusMate sessions inflate the Pomodoro count on ProjectDetailView and StatsContentView even though the user treats them as different modes.
- **Fix direction:** Add `!isFocusMate` to `completedPomodoroCount` and `totalFocusTime` filters. (Alternative: new `sessionType` case via schema V3 migration — more invasive, user prefers simple.)

### M2. OpenRouter API key saved on every keystroke

- **Where:** `Breadcrumb/Views/Settings/OpenRouterSettingsSection.swift:19-21`.
- **Bug:** `onChange(of: apiKey)` fires per character. Each runs `SecItemUpdate` + (on miss) `SecItemAdd`. Typing a 64-char key writes 64 times. Silent failure because `@discardableResult`. `.onAppear` restore from keychain re-triggers `onChange`, re-saves same value.
- **Fix direction:** Debounce save with short `Task.sleep` (~500ms), OR save only on `.onSubmit`/focus loss. Also: `guard apiKey != KeychainHelper.read(...) else { return }`.

### M3. HistoryView `onDelete` doesn't animate row out

- **Where:** `Breadcrumb/Views/HistoryView.swift:54-85`.
- **Bug:** `.onDelete(perform:)` expects the data source to update so the row animates out. Handler only sets `entryToDelete` and opens confirmation dialog; row snaps back visually. Also, `sortedEntries` recomputes each body pass — `offsets.first` refers to an entry that may shift between swipe and confirmation (no concurrent mutation in practice, but fragile).
- **Fix direction:** Replace `.onDelete` with `.swipeActions` containing a destructive `Button` that sets `entryToDelete` directly. Keeps confirm-first pattern, removes IndexSet indirection.

### M4. `LinkedDocument.url()` / `.file()` factories bypassed

- **Where:** `Breadcrumb/Models/LinkedDocument.swift:56-88` vs `Breadcrumb/Views/AddURLFormView.swift:84` and `Breadcrumb/Views/DocumentListView.swift:168`.
- **Bug:** Every call site uses `LinkedDocument(type: ...)` directly, bypassing factory guards against empty `urlString`/`bookmarkData`. `AddURLFormView` duplicates validation via `normalizedURL`, but `DocumentListView.addFileViaPanel()` has no equivalent guard. `LinkedDocument.isValid` is dead code — never checked.
- **Fix direction:** Use factories at call sites (`LinkedDocument.url(...)`, `LinkedDocument.file(...)`), handle optional return. Minimum: add `guard !bookmarkData.isEmpty` in `addFileViaPanel()`. If factories remain unused, delete them.

### M5. `AIFillerStripperTests` asserts the buggy over-stripping

- **Where:** `BreadcrumbTests/AIFillerStripperTests.swift:20-22`.
- **Bug:** Asserts that literal word "nothing" is stripped, codifying over-aggressive behavior from H3. Test passes but documents the bug.
- **Fix direction:** After tightening `AIFillerStripper` (H3), rewrite test. Expect stripping only when "nothing" stands alone as the entire value; assert that `"nothing planned yet — Sarah to confirm"` is preserved. Remove prefix-matching tests that accept real-looking sentences.

### M6. `enterOvertime()` resets accumulated overtime

- **Where:** `Breadcrumb/PomodoroTimer.swift:161-169`.
- **Bug:** If user is in overtime (tick already set `isOvertime = true`, `overtimeSeconds > 0`), presses Stop, then picks "Continue Working", `enterOvertime()` sets `overtimeSeconds = 0`, `elapsedBeforePause = 0`, resets `phaseStartDate`. Accumulated overtime minutes are wiped. Final `actualDuration = originalDurationSeconds + overtimeSeconds` under-reports.
- **Fix direction:** Guard in `enterOvertime()` — if already in overtime with accumulated seconds, retain them. Cleanest: set `elapsedBeforePause = overtimeSeconds` and `phaseDurationSeconds = 0` so tick continues from accumulated value.

### M7. Stepper range clamping has minor drift

- **Where:** `Breadcrumb/Views/PomodoroConfigView.swift:59`, `Breadcrumb/Views/SettingsView.swift:106`.
- **Bug:** Range `2...(totalSessions - 1)` is inside `if hasLongBreak` (requires `totalSessions >= 3`). onChange clamp is `max(2, totalSessions - 1)`. If user drops `totalSessions` to 2 or 1, `sessionsBeforeLongBreak` silently stays at 2 (UI hidden). Bouncing back leaves stored value that may not match the user's mental model.
- **Fix direction:** Clamp both directions: `sessionsBeforeLongBreak = max(2, min(totalSessions - 1, sessionsBeforeLongBreak))`, only when `totalSessions >= 3`. Otherwise reset to default.

### M8. `NotificationServiceTests.initialization` is a tautology

- **Where:** `BreadcrumbTests/NotificationServiceTests.swift:10-13`.
- **Bug:** `let service = NotificationService(); #expect(service != nil)` — `service` is non-optional. Expression always true. Test verifies nothing.
- **Fix direction:** Replace with `#expect(UNUserNotificationCenter.current().delegate === service)` (requires exposing delegate) or assert side effects like authorization request.

---

## Low / Suspected Bugs

### L1. `NotificationService.requestAuthorization` swallows denial

- **Where:** `Breadcrumb/Services/NotificationService.swift:12-16`.
- **Bug:** `try?` swallows authorization errors. If user denies, later `UNUserNotificationCenter.add()` calls silently fail. `showBannerNotification` setting remains on, implying banners work when they don't.
- **Fix direction:** Query `getNotificationSettings()` before posting, or surface warning in Settings when `authorizationStatus == .denied`.

### L2. Menu bar stays tomato-labeled after cycle complete

- **Where:** `Breadcrumb/PomodoroTimer.swift:73-90`.
- **Bug:** When all sessions done and last break ends, `currentPhase == .sessionEnded` and label shows "🍅 Fertig!" until user presses Stop Completely.
- **Fix direction:** Different icon/text when `isCycleComplete && currentPhase == .sessionEnded`, e.g. `"✅ Fertig!"` or revert to idle bookmark.

### L3. Dock icon policy can stick if `onDisappear` misses

- **Where:** `Breadcrumb/WindowManager.swift:47-96` + `Breadcrumb/Views/BreakoutWindowView.swift:23`.
- **Bug:** `NSApp.setActivationPolicy(.regular)` in `open()` is only reverted through `BreakoutWindowView.onDisappear → windowClosed() → Task(delay 50ms)`. If window terminates through a path that skips `onDisappear`, app stays in `.regular`, Dock icon persists.
- **Fix direction:** Observe `NSWindow.willCloseNotification` for "main" window in `AppDelegate`, or add scenePhase safety net resetting policy when no breakout visible.

### L4. `Text(project.name)` may resolve as `LocalizedStringKey` (Suspected)

- **Where:** `Breadcrumb/Views/ProjectRowView.swift:16`, `ProjectDetailView.swift:53`, `StatsContentView.swift:11`, `ArchivedProjectsView.swift:54`, `PomodoroRunningView.swift:42`, `PomodoroConfigView.swift:39`.
- **Bug:** `Text(_:)` prefers `LocalizedStringKey` overload. A project named "Save" or "Cancel" could resolve through localization and render the wrong label.
- **Fix direction:** Change all sites to `Text(verbatim: project.name)`.

### L5. `extractJSONObject` uses greedy `lastIndex(of: "}")` (Suspected)

- **Where:** `Breadcrumb/Services/OpenRouterProvider.swift:102-127`.
- **Bug:** `s.lastIndex(of: "}")` can grab a stray `}` in trailing prose, or one inside a string literal, causing parse failures (user sees `invalidResponse`). Requires specific model output to hit.
- **Fix direction:** Scan forward from first `{` counting braces while tracking string-literal state, stop at depth 0. Or progressively try prefixes with `JSONSerialization`.

### L6. `NSWorkspace.didWakeNotification` observer never removed

- **Where:** `Breadcrumb/PomodoroTimer.swift:47-57`.
- **Bug:** `PomodoroTimer` registers wake observer in `init`, no `deinit` to unregister. Lives for app lifetime in production so no leak, but tests/previews creating a second timer receive stale callbacks on the old one.
- **Fix direction:** Store observer token from `addObserver(forName:object:queue:using:)`, remove in `deinit`.

### L7. `NotificationService.delegate` never torn down

- **Where:** `Breadcrumb/Services/NotificationService.swift:7-10`.
- **Bug:** `UNUserNotificationCenter.current().delegate` is a singleton pointer. Recreating service in tests leaves stale delegate.
- **Fix direction:** In `deinit`, set delegate to nil only if still self.

### L8. Sleep-across-phase-boundary unverified (Suspected)

- **Where:** `Breadcrumb/PomodoroTimer.swift:263-273`.
- **Bug:** On wake, `tick()` fires once. If system wakes mid-break, elapsed from `phaseStartDate` may blow past break-end, advancing to `.sessionEnded` without firing the "break done" notification.
- **Fix direction:** Verify wake path fires break-done reliably. Add test simulating sleep-across-phase-boundary asserting notification fired.

---

## Recommended Work Order

### Batch 1 — Critical correctness (commit each)
1. **C3** (version in Info.plist) — 1-line fix, immediate user benefit.
2. **C1** (duplicate FocusMate session) — guard double-insert.
3. **C2** (phantom work session after break) — guard construction in parent.
4. **H2** (missing `modelContext.insert` in saveAndBreak) — one line.

After Batch 1: add tests. Session-save paths have no coverage. `PomodoroSessionSaveTests.swift` should verify:
- FocusMate Save & Done → exactly 1 `PomodoroSession` in context.
- Break-end Stop Completely → no `.work` session fabricated.
- Work Save & Break → exactly 1 `StatusEntry` + 1 `PomodoroSession`.

### Batch 2 — High-severity behavior
5. **H1** (Stop during work → Save & Break is default) — wire `wasUserStop` conditional.
6. **H4** (notifications lost before popover mount) — move subscribers to AppDelegate.
7. **H3 + M5** (AIFillerStripper over-stripping + tests) — tighten matcher, rewrite tests.

### Batch 3 — Data integrity
8. **M1** (FocusMate inflates Pomodoro count) — add `!isFocusMate` filter.
9. **M6** (enterOvertime resets accumulator) — preserve accumulated overtime.
10. **M2** (API key keystroke writes) — debounce or save-on-submit.
11. **M7** (stepper clamp drift) — two-sided clamp.

### Batch 4 — Cleanup
12. **M3** (onDelete animation) — `.swipeActions` refactor.
13. **M4** (LinkedDocument factories) — use or delete.
14. **M8** (tautology test) — real assertion.
15. **L1-L8** — opportunistic.

Per user memory: build + upload DMG for every release, commit/push directly to `master`, bump version in `project.yml`.

---

## Hot-Spot Files

Files appearing in multiple findings. Read first when picking up:

- `Breadcrumb/Views/PomodoroSessionEndView.swift` — C1, C2, H1, H2
- `Breadcrumb/Views/PomodoroRunningView.swift` — C1, C2, H1, M1, L4
- `Breadcrumb/PomodoroTimer.swift` — M6, L2, L6, L8
- `Breadcrumb/Services/AIFillerStripper.swift` — H3, M5
- `Breadcrumb/Services/NotificationService.swift` — L1, L7, M8
- `Breadcrumb/AppDelegate.swift` — H4
- `Breadcrumb/Info.plist` — C3
