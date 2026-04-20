# Breadcrumb — UX Review Handoff

**Date:** 2026-04-16
**Scope:** Full UX / usability review of `/Users/roger/Claude/Code/Breadcrumb` (macOS menu bar Pomodoro + project status tracker, Swift 6 / SwiftUI / SwiftData, target macOS 26).
**Method:** Opus 4.7 read-only review. No code changed.

This document is a handoff. Every finding includes file path, line number, problem description, and concrete fix — enough for a fresh Claude instance to pick up without re-reading the codebase.

**Context for the next Claude (non-negotiable):**
- User is non-technical and works solo. Skip PR suggestions — commit, push, merge to `master`.
- Over-engineering is the default tendency — actively restrain. "Too much" is valid feedback.
- All UI text MUST go through the `Strings` enum — never hardcode German/English in views. Add entries to BOTH languages in `Strings.swift`.
- Run `xcodegen generate` after adding/removing Swift files before building.
- Tests use Swift Testing (`@Test`, `@Suite`, `#expect`), not XCTest.
- Invoke Swift skills before writing code: `swiftui-pro`, `swiftdata-pro`, `swift-concurrency-pro`.
- Git identity: `masterbachelormaster` / `noreply@anthropic.com`. Never real name.
- Build + upload DMG for every release.

---

## Table of Contents

1. [High Priority](#high-priority) — hurts daily use
2. [Medium Priority](#medium-priority) — annoying but workable
3. [Low Priority / Polish](#low-priority--polish)
4. [Recommended Work Order](#recommended-work-order)
5. [Hot-Spot Files](#hot-spot-files)

---

## High Priority

### U1. Toolbar buttons have no tooltips or labels

- **Where:** `Breadcrumb/Views/FooterView.swift` (entire view).
- **Problem:** FooterView has two icon buttons — Archive (`.labelStyle(.iconOnly)`) and a 🍅 emoji button. Neither has `.help()` nor visible labels. A non-technical user cannot tell what the tomato does. The CLAUDE.md promises "Pomodoro / Update Status / History buttons" but those only appear after a project is selected.
- **Fix:** Add `.help(Strings.Projects.archiveTitle(l))` on Archive, `.help(Strings.Pomodoro.pomodoro(l))` on tomato. Better: replace the emoji with `Label("Pomodoro", systemImage: "timer")` + `.labelStyle(.iconOnly)` for visual consistency with the rest of the toolbar.

### U2. Paused and running Pomodoro look identical in the menu bar

- **Where:** `Breadcrumb/PomodoroTimer.swift:73-90` (`menuBarLabel`).
- **Problem:** When paused, the menu bar still shows `🍅 12:34`. A user who paused and walked away can't tell whether the clock is counting.
- **Fix:** Add pause indicator. Simplest: `isPaused ? "⏸ \(formattedTime)" : "🍅 \(formattedTime)"`. Apply to break and FocusMate variants as well.

### U3. Return key saves the form instead of inserting a newline

- **Where:** `Breadcrumb/Views/StatusEntryForm.swift:23-26, 50-53` (and the equivalent form in `PomodoroSessionEndView.swift`).
- **Problem:** `freeText` is a multi-line `TextField(axis: .vertical)` with `lineLimit(4...)`, but the Save button has `.keyboardShortcut(.defaultAction)`. Return saves instead of inserting a newline — infuriating for multi-line notes.
- **Fix:** Remove `.keyboardShortcut(.defaultAction)` from Save, OR change to Cmd-Return: `.keyboardShortcut(.return, modifiers: .command)`. Apply to all multi-line form save buttons.

### U4. Pomodoro config edits don't persist to settings

- **Where:** `Breadcrumb/Views/ContentView.swift:104-113` + `Breadcrumb/Views/PomodoroConfigView.swift`.
- **Problem:** `PomodoroConfigView` reads AppStorage defaults but edits made in the config view only apply to the running session. If the user tweaks to 50 min in config, next start is back to 25. They re-tweak every time.
- **Fix:** Either (a) sync back to AppStorage when `onStart` fires — the config view doubles as quick-settings; or (b) add a "Remember these settings" toggle. Option (a) matches user expectation and is simpler.

### U5. No way to edit a saved status entry

- **Where:** `Breadcrumb/Views/HistoryView.swift:55-59` + `Breadcrumb/Views/HistoryEntryRow.swift`.
- **Problem:** Swipe-to-delete exists but no edit. A typo requires delete + full re-type. For a "keep track of where you stand" tool, this is painful.
- **Fix:** Add a context menu (right-click) on `HistoryEntryRow` with "Edit" and "Delete". Edit opens `StatusEntryForm` prefilled with the entry's values.

### U6. Overtime setting implies banner but code only plays sound

- **Where:** `Breadcrumb/Services/NotificationService.swift:55-58` + `Breadcrumb/Strings.swift:297-299`.
- **Problem:** `notifyOvertime` plays only sound. `Strings.Notifications.overtimeNotificationBody` exists and implies a banner. Dead string + mismatch between Settings label and reality.
- **Fix:** Delete the unused `overtimeNotificationBody` string (the gentle-nudge intent is sound-only). Confirm the Settings label reads "Overtime sound" only.

### U7. AI error messages show raw internal keys

- **Where:** `Breadcrumb/Views/AIExtractButton.swift:70-75` uses `error.localizedDescription`; `Breadcrumb/Services/AIService.swift:20-24` uses `errorDescription` reading language from UserDefaults at error-creation time.
- **Problem:** `.notAvailable(reason)` returns the internal reason key (`"deviceNotEligible"`, `"requiresMacOS26"`, `"notConfigured"`) to the user as the error message. The UserDefaults read at error-creation can lag a live language switch.
- **Fix:** In `AIExtractButton.extract()`, if error is `AIServiceError`, call `error.description(for: languageManager.language)` explicitly. Add `localizedUnavailableReason(for:)` mapping each reason key to a friendly translated message.

### U8. Breakout window doesn't resize per content type

- **Where:** `Breadcrumb/BreadcrumbApp.swift:49` + `Breadcrumb/Views/BreakoutWindowView.swift:17-22`.
- **Problem:** The `Window` has fixed `defaultSize(width: 500, height: 400)`. macOS restores previous size across openings. `BreakoutWindowView` declares different `minSize`/`idealSize` per content type but those are ignored once the window exists. Opening Settings then History leaves the window at Settings dimensions.
- **Fix:** Either (a) use separate `Window` scenes per content type (clean, more code), or (b) observe `WindowManager.currentContent` and programmatically set the NSWindow frame. Option (a) is more SwiftUI-idiomatic.

---

## Medium Priority

### U9. Welcome view is German-only regardless of locale

- **Where:** `Breadcrumb/Views/WelcomeView.swift` + `Breadcrumb/Services/LanguageManager.swift`.
- **Problem:** `LanguageManager` defaults to German (`"de"`). An English-speaking first-launch user sees a German welcome with no obvious way to switch.
- **Fix:** Default `LanguageManager` to `Locale.current.language.languageCode == "de" ? .german : .english`. Alternatively add a small DE/EN toggle in a WelcomeView corner.

### U10. Inline overlay pattern has accessibility gaps

- **Where:** `ContentView.swift:66-70`, `ProjectListView.swift:71-75`, `ProjectDetailView.swift:160-164/177-181/192-196/207-211`, `PomodoroRunningView.swift:101-102`.
- **Problem:** The `Button { dismiss() } label: { Color.black.opacity(0.3).ignoresSafeArea() }` backdrop pattern is used six times. Each is an unlabeled button — VoiceOver hears "button" with no context. Multiple overlays per view create multiple interactive elements alongside the form.
- **Fix:** Extract a reusable `OverlayBackdrop` view with `.accessibilityLabel(Strings.General.cancel(l))` (or `.accessibilityHidden(true)` for decorative uses). Use in all six call sites.

### U11. Inline overlays dismiss on backdrop click, silently losing draft data

- **Where:** Same as U10, plus `ProjectFormView.swift:83-85`, `StatusEntryForm.swift:82-86`.
- **Problem:** Tapping the dimmed backdrop dismisses without confirmation. A user who typed a long status and accidentally clicked outside loses everything.
- **Fix:** If any bound text is non-empty, backdrop tap shows "Discard changes?" confirmation OR just doesn't dismiss (force explicit Cancel). Cheapest: don't auto-dismiss when there's unsaved text.

### U12. FocusMate start-time grid is confusing

- **Where:** `Breadcrumb/Views/PomodoroConfigView.swift:139-156` (`computeAvailableBoundaries`).
- **Problem:** Returns only past 15-min boundaries where `boundary + duration > now`. For a 25-min session late in a quarter-hour, one button. No "now" option, no future start times. Label "Session Start" with a grid of past times is unintuitive.
- **Fix:** Add the next upcoming 15-min boundary. Label the current-time boundary as "Now" or "Already started N min ago". Consider allowing future starts (FocusMate.com schedules at upcoming boundaries).

### U13. HistoryView rows have weak expand affordance

- **Where:** `Breadcrumb/Views/HistoryEntryRow.swift:9-38`.
- **Problem:** `DisclosureGroup` inside `List` renders the chevron on one side; entries truncate to one line with no obvious "this expands" cue. No total-entry count shown.
- **Fix:** Add entry count to List header ("14 Einträge / entries"). Make the whole row tappable to expand, or show a trailing expand icon.

### U14. StatusEntry form duplicated between standalone and session-end

- **Where:** `Breadcrumb/Views/StatusEntryForm.swift` vs `Breadcrumb/Views/PomodoroSessionEndView.swift:131-168`.
- **Problem:** Two independent implementations of the status-entry form. They'll drift. The Pomodoro variant requires project selection when none is bound but doesn't validate the way `StatusEntryForm` does.
- **Fix:** Extract shared `StatusDraftFields` view taking bindings + optional project picker. Both call sites compose it. This also collapses into the BUGS.md H2 fix (single insert path).

### U15. Settings / Pomodoro config steppers are cramped

- **Where:** `Breadcrumb/Views/SettingsView.swift:100-116`, `PomodoroConfigView.swift:52-62`.
- **Problem:** Five `Stepper` rows stacked vertically with hand-formatted labels ("Focus Time: 25 min"). No icons. Hard to scan. Conditional reveals (`hasBreaks`, `hasLongBreak`) show a mass of near-identical rows.
- **Fix:** Use `LabeledContent` or prefix each label with a small SF Symbol (`timer`, `cup.and.saucer`, `moon.zzz`). Group into "Work" / "Breaks" subsections.

### U16. Language switch may not update menu bar label promptly

- **Where:** `Breadcrumb/BreadcrumbApp.swift:32-36`.
- **Problem:** `menuBarLabel(language:)` takes language as a parameter. `@Observable` dependency tracking can miss function-argument pass-through — the label may not refresh instantly on language toggle.
- **Fix:** Drop the argument; have `menuBarLabel` read `languageManager.language` directly, making the dependency explicit via stored-property access. Alternatively add `.onChange(of: languageManager.language)` to force re-evaluation.

### U17. Right-click menu reads UserDefaults directly for language

- **Where:** `Breadcrumb/AppDelegate.swift:23-24`.
- **Problem:** Context menu queries UserDefaults because it has no `LanguageManager` reference. Works in practice but design smell.
- **Fix:** Make `LanguageManager` accessible via static `shared` or inject at launch. Or move the right-click menu into a SwiftUI `.contextMenu` on `MenuBarExtra`.

### U18. Keyboard shortcuts are minimal

- **Where:** Across views.
- **Problem:** Only Cmd-, (Settings) and defaultAction/cancelAction in forms. No Cmd-N (new project), no Cmd-U (update status), no global toggle-popover hotkey.
- **Fix:** Add `.keyboardShortcut("n", modifiers: .command)` on new-project, `"u"` on update-status. Consider a user-configurable global hotkey via `NSEvent.addGlobalMonitorForEvents` or `MASShortcut` to open the popover (common for menu bar apps).

### U19. Icon picker has only 12 fixed icons

- **Where:** `Breadcrumb/Views/ProjectFormView.swift:13-17`.
- **Problem:** 12 hardcoded SF Symbols; users run out by their 6th project, identical icons don't aid recognition.
- **Fix:** Expand to 40+ common SF Symbols organized by category, or use a native SF Symbol picker sheet. Optionally add per-project tint color.

### U20. Stats "Details ›" button is tiny caption text

- **Where:** `Breadcrumb/Views/ProjectDetailView.swift:302-316`.
- **Problem:** Bottom-right caption text — users won't discover stats can expand into a breakout window.
- **Fix:** Use `Button("View Details", systemImage: "chart.bar") { … }` with `.buttonStyle(.bordered)`, OR make the entire stats row tappable.

### U21. AI error banner auto-dismisses after 4 seconds

- **Where:** `Breadcrumb/Views/AIExtractButton.swift:71-74`.
- **Problem:** User looking away misses it. Error disappears with no trace.
- **Fix:** Replace auto-dismiss with manual X button, OR keep visible until user edits `freeText` or retries.

### U22. No project search for large lists

- **Where:** `Breadcrumb/Views/ProjectListView.swift`, `ProjectPickerView.swift`.
- **Problem:** Linear list by last-updated. 20+ projects requires scrolling. No search, no favorites, no pinning.
- **Fix:** Add `.searchable($query)` when project count > 5, or small search icon in the header.

---

## Low Priority / Polish

### U23. Hardcoded "Breadcrumb" bypasses `Strings` enum

- **Where:** `Breadcrumb/Views/ProjectListView.swift:33`, `Breadcrumb/Views/AboutView.swift:47`.
- **Problem:** Violates the "all UI text must go through `Strings`" rule.
- **Fix:** Add `Strings.General.appName` returning `"Breadcrumb"` (not translated), use in both sites.

### U24. Inconsistent emoji vs SF Symbol usage

- **Where:** `Breadcrumb/Strings.swift` (`sessionFinished`, `breakOver`, `focusMateComplete`, `pomodoroMode`, `focusMateMode`); `PomodoroRunningView.phaseEmoji`; `FooterView.swift:20`.
- **Problem:** App mixes 🍅 ☕ 👥 ✅ emoji with SF Symbols. Emoji rendering varies across macOS versions; they don't respond to tint/`foregroundStyle`. The headline "✅ Sitzung beendet!" has the checkmark baked into the translation string.
- **Fix:** Use SF Symbols for in-view titles (`timer`, `cup.and.saucer.fill`, `person.2.fill`, `checkmark.circle.fill`) with `.foregroundStyle`. Menu bar emoji is fine (mixed-content label). Split in-view emoji out so strings are pure text and icons are separate views.

### U25. `SoundPicker` reads language from UserDefaults directly

- **Where:** `Breadcrumb/Views/SoundPicker.swift:33-36`.
- **Problem:** Bypasses `LanguageManager`; won't re-render on language switch.
- **Fix:** `@Environment(LanguageManager.self) private var languageManager`, use `languageManager.language`.

### U26. "Optional Fields" disclosure always shown

- **Where:** `Breadcrumb/Views/StatusEntryForm.swift:36`, `PomodoroSessionEndView.swift:160`.
- **Problem:** Users who never use optional fields see persistent visual noise.
- **Fix:** Add `@AppStorage("feature.optionalFields")` (default true). Hide disclosure when false. Toggle lives in Settings.

### U27. `BulletableField` has 300ms focus delay

- **Where:** `Breadcrumb/Views/BulletableField.swift:146-162`.
- **Problem:** `Task.sleep(300ms)` before `plainFocused = true` when collapsing from list to plain mode — noticeable pause. `id: \.offset` in ForEach may shuffle focus IDs on add/remove, causing TextField flicker.
- **Fix:** Use stable IDs (`struct BulletRow { let id: UUID; var text: String }`). Reduce delay to ~50ms.

### U28. German empty-state copy is stilted

- **Where:** `Breadcrumb/Strings.swift:57-58`.
- **Problem:** "Erstelle dein erstes Projekt mit dem + Button" is mechanical German.
- **Fix:** Rewrite to natural German: "Tippe oben auf + um dein erstes Projekt anzulegen" or similar.

### U29. Session-end title lacks progress context

- **Where:** `Breadcrumb/Views/PomodoroSessionEndView.swift:101-128`.
- **Problem:** "✅ Session Complete!" doesn't say which session. In a 4-session cycle, "Session 2 of 4 complete" is more useful.
- **Fix:** Include session number: add `Strings.Pomodoro.sessionFinishedNumbered(l, number: N, total: T)`.

### U30. `SmartTimestampView` toggle not discoverable

- **Where:** `Breadcrumb/Views/SmartTimestampView.swift`.
- **Problem:** Tiny timestamp is a button toggling relative/absolute time on click — no hover cue beyond faint `ToolbarButtonStyle` background. New users won't know this exists.
- **Fix:** Add `.help("Click to toggle relative/absolute time")` localized.

### U31. Inline overlay cards use `nsColor: .windowBackgroundColor`

- **Where:** `StatusEntryForm.swift:58`, `ProjectFormView.swift:61` (and other overlay cards).
- **Problem:** On a vibrant popover (`.menuBarExtraStyle(.window)`), solid `.windowBackgroundColor` layers lose vibrancy and look harsh in Dark Mode.
- **Fix:** Use `.background(.regularMaterial)` or `.background(.thickMaterial, in: RoundedRectangle(cornerRadius: 10))` for a modern, vibrant look.

### U32. Menu bar icon has no tooltip

- **Where:** `Breadcrumb/BreadcrumbApp.swift:32-36`.
- **Problem:** When idle, the label is just `Image(systemName: "bookmark.fill")` with no tooltip. In a crowded menu bar, identifying which icon is Breadcrumb is hard.
- **Fix:** Add `.help("Breadcrumb")` to the menu bar image.

---

## Recommended Work Order

### Batch 1 — High-impact, small changes (commit each)
1. **U3** (Return inserts newline) — remove `.defaultAction` or switch to Cmd-Return.
2. **U1** (toolbar tooltips) — add `.help()` modifiers.
3. **U32** (menu bar tooltip) — one `.help()`.
4. **U2** (menu bar pause indicator) — 3-line change in `menuBarLabel`.
5. **U6** (dead overtime string) — delete unused `overtimeNotificationBody`.

### Batch 2 — Discoverability wins
6. **U5** (edit status entry) — context menu + prefilled form.
7. **U18** (keyboard shortcuts) — Cmd-N, Cmd-U, optional global hotkey.
8. **U20** (stats "Details ›") — promote to bordered button or tappable row.
9. **U30** (timestamp toggle tooltip) — one `.help()`.

### Batch 3 — Workflow improvements
10. **U4** (Pomodoro config persists) — sync back to AppStorage on start.
11. **U7** (raw AI error keys) — add `localizedUnavailableReason`.
12. **U21** (AI error auto-dismiss) — manual dismiss.
13. **U9** (welcome locale default) — locale-based default.

### Batch 4 — Form / overlay refactor
14. **U10/U11** (backdrop a11y + draft protection) — extract `OverlayBackdrop`.
15. **U14** (duplicated status forms) — extract `StatusDraftFields`. Collapses with BUGS.md H2.
16. **U8** (window resizes per content) — split scenes per content type.
17. **U31** (overlay card material) — swap to `.regularMaterial`.

### Batch 5 — Polish
18. **U15** (stepper grouping + icons).
19. **U19** (icon picker expansion).
20. **U13** (HistoryView expand cues + count).
21. **U12** (FocusMate start-time grid).
22. **U16** (language-switch dependency tracking).
23. **U22** (project search).
24. **U23-U29** — remaining polish items.

Per user memory: build + upload DMG per release, commit/push directly to `master`, bump version in `project.yml`.

---

## Hot-Spot Files

Files appearing in multiple findings. Read first when picking up:

- `Breadcrumb/Views/PomodoroSessionEndView.swift` — U14, U29
- `Breadcrumb/Views/StatusEntryForm.swift` — U3, U14, U26, U31
- `Breadcrumb/PomodoroTimer.swift` — U2
- `Breadcrumb/BreadcrumbApp.swift` — U2, U8, U16, U32
- `Breadcrumb/Strings.swift` — U6, U23, U24, U28, U29
- `Breadcrumb/Views/AIExtractButton.swift` — U7, U21
- `Breadcrumb/Services/AIService.swift` — U7
- `Breadcrumb/AppDelegate.swift` — U17
- Overlay backdrop pattern files — U10, U11 (`ContentView.swift`, `ProjectListView.swift`, `ProjectDetailView.swift`, `PomodoroRunningView.swift`)
