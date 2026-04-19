# macOS Keyboard Shortcuts

**Date:** 2026-04-19
**Scope:** Add standard macOS keyboard shortcuts for core actions — form submission, new project, update status.

## Approach

Button-level `.keyboardShortcut` modifiers on existing buttons. No new views, no Commands plumbing, no global hotkeys. Shortcuts are screen-local — they only fire when the relevant button is visible.

## Section 1: Multi-line form submission (Cmd+Return)

The multi-line `freeText` field uses `TextField(axis: .vertical)` with `lineLimit`. Currently, `.keyboardShortcut(.defaultAction)` on Save means Return saves the form instead of inserting a newline.

### Changes

**StatusEntryForm.swift** (Save button, line 52):
- Change `.keyboardShortcut(.defaultAction)` to `.keyboardShortcut(.return, modifiers: .command)`

**PomodoroSessionEndView.swift** (save buttons currently have no shortcut):
- Add `.keyboardShortcut(.return, modifiers: .command)` to "Save & Break" button (workEndContent, line 118)
- Add `.keyboardShortcut(.return, modifiers: .command)` to "Save & Done" button (focusMateEndContent, line 93)

### Not changed

Single-line forms keep `.keyboardShortcut(.defaultAction)` (Return to save):
- ProjectFormView (project name)
- EditLabelFormView (label)
- AddURLFormView (URL + label)
- PomodoroConfigView (steppers only, no text)

## Section 2: Navigation shortcuts

**ProjectListView.swift** ("+" new project button, line 36):
- Add `.keyboardShortcut("n", modifiers: .command)`
- Only active when the project list screen is visible

**ProjectDetailView.swift** ("Update Status" button, line 130):
- Add `.keyboardShortcut("u", modifiers: .command)`
- Only active when viewing a specific project

## Section 3: Discoverability via tooltips

No traditional menu bar to display shortcuts, so `.help()` tooltips communicate them on hover.

### New Strings entries (both German and English)

| Key | German | English |
|-----|--------|---------|
| `Strings.Projects.newProjectHint(l)` | `"Neues Projekt (⌘N)"` | `"New Project (⌘N)"` |
| `Strings.Status.updateStatusHint(l)` | `"Status aktualisieren (⌘U)"` | `"Update Status (⌘U)"` |
| `Strings.General.saveHint(l)` | `"Sichern (⌘↩)"` | `"Save (⌘↩)"` |
| `Strings.Pomodoro.saveAndBreakHint(l)` | `"Sichern & Pause (⌘↩)"` | `"Save & Break (⌘↩)"` |
| `Strings.Pomodoro.saveAndDoneHint(l)` | `"Sichern & Fertig (⌘↩)"` | `"Save & Done (⌘↩)"` |

### Tooltip placement

- "+" button (ProjectListView): `.help(Strings.Projects.newProjectHint(l))`
- "Update Status" button (ProjectDetailView): `.help(Strings.Status.updateStatusHint(l))`
- Save button (StatusEntryForm): `.help(Strings.General.saveHint(l))`
- "Save & Break" button (PomodoroSessionEndView): `.help(Strings.Pomodoro.saveAndBreakHint(l))`
- "Save & Done" button (PomodoroSessionEndView): `.help(Strings.Pomodoro.saveAndDoneHint(l))`

## Files changed

| File | Change |
|------|--------|
| `Breadcrumb/Views/StatusEntryForm.swift` | Swap `.defaultAction` to Cmd+Return, add `.help()` |
| `Breadcrumb/Views/PomodoroSessionEndView.swift` | Add Cmd+Return + `.help()` on save buttons |
| `Breadcrumb/Views/ProjectListView.swift` | Add Cmd+N + `.help()` on "+" button |
| `Breadcrumb/Views/ProjectDetailView.swift` | Add Cmd+U + `.help()` on "Update Status" button |
| `Breadcrumb/Strings.swift` | Add 5 hint strings (both languages) |

## Summary

Six `.keyboardShortcut` additions/changes and five `.help()` tooltips across four view files and Strings.swift. No architectural changes.
