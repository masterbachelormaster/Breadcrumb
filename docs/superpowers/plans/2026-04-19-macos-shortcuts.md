# macOS Keyboard Shortcuts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Cmd+Return for multi-line form save, Cmd+N for new project, Cmd+U for update status, with tooltip discoverability.

**Architecture:** Button-level `.keyboardShortcut` modifiers on existing buttons. Five new bilingual hint strings in `Strings.swift`. No new views or state plumbing.

**Tech Stack:** Swift 6.0, SwiftUI, Swift Testing

**Spec:** `docs/superpowers/specs/2026-04-19-macos-shortcuts-design.md`

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `Breadcrumb/Strings.swift` | Modify | Add 5 hint strings (General, Projects, Status, Pomodoro enums) |
| `BreadcrumbTests/StringsTests.swift` | Modify | Test all 5 hint strings in both languages |
| `Breadcrumb/Views/StatusEntryForm.swift` | Modify | Swap `.defaultAction` → Cmd+Return, add `.help()` |
| `Breadcrumb/Views/PomodoroSessionEndView.swift` | Modify | Add Cmd+Return + `.help()` on two save buttons |
| `Breadcrumb/Views/ProjectListView.swift` | Modify | Add Cmd+N, update `.help()` to include shortcut hint |
| `Breadcrumb/Views/ProjectDetailView.swift` | Modify | Add Cmd+U + `.help()` on Update Status button |

---

### Task 1: Add hint strings to Strings.swift

**Files:**
- Modify: `Breadcrumb/Strings.swift:13-14` (General enum), `:60-62` (Projects enum), `:103-106` (Status enum), `:205-207` (Pomodoro enum), `:281-283` (Pomodoro enum)
- Test: `BreadcrumbTests/StringsTests.swift`

- [ ] **Step 1: Write failing tests for all 5 hint strings**

Add a new test to `BreadcrumbTests/StringsTests.swift` at the end of the `StringsTests` struct (before the closing `}`):

```swift
@Test("Keyboard shortcut hint strings")
func keyboardShortcutHints() {
    #expect(Strings.General.saveHint(.german) == "Sichern (⌘↩)")
    #expect(Strings.General.saveHint(.english) == "Save (⌘↩)")
    #expect(Strings.Projects.newProjectHint(.german) == "Neues Projekt (⌘N)")
    #expect(Strings.Projects.newProjectHint(.english) == "New Project (⌘N)")
    #expect(Strings.Status.updateStatusHint(.german) == "Status aktualisieren (⌘U)")
    #expect(Strings.Status.updateStatusHint(.english) == "Update Status (⌘U)")
    #expect(Strings.Pomodoro.saveAndBreakHint(.german) == "Speichern & Pause (⌘↩)")
    #expect(Strings.Pomodoro.saveAndBreakHint(.english) == "Save & Break (⌘↩)")
    #expect(Strings.Pomodoro.saveAndDoneHint(.german) == "Speichern & Fertig (⌘↩)")
    #expect(Strings.Pomodoro.saveAndDoneHint(.english) == "Save & Done (⌘↩)")
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb 2>&1 | tail -20`
Expected: Build failure — `saveHint`, `newProjectHint`, `updateStatusHint`, `saveAndBreakHint`, `saveAndDoneHint` not found.

- [ ] **Step 3: Add hint strings to Strings.swift**

In `Breadcrumb/Strings.swift`, add to `enum General` (after `minutesAbbrev` at line 47):

```swift
static func saveHint(_ l: AppLanguage) -> String {
    l == .german ? "Sichern (⌘↩)" : "Save (⌘↩)"
}
```

Add to `enum Projects` (after `permanentlyDelete` at line 97):

```swift
static func newProjectHint(_ l: AppLanguage) -> String {
    l == .german ? "Neues Projekt (⌘N)" : "New Project (⌘N)"
}
```

Add to `enum Status` (after `history` at line 144):

```swift
static func updateStatusHint(_ l: AppLanguage) -> String {
    l == .german ? "Status aktualisieren (⌘U)" : "Update Status (⌘U)"
}
```

Add to `enum Pomodoro` (after `saveAndBreak` at line 206):

```swift
static func saveAndBreakHint(_ l: AppLanguage) -> String {
    l == .german ? "Speichern & Pause (⌘↩)" : "Save & Break (⌘↩)"
}
```

Add to `enum Pomodoro` (after `saveAndDone` at line 282):

```swift
static func saveAndDoneHint(_ l: AppLanguage) -> String {
    l == .german ? "Speichern & Fertig (⌘↩)" : "Save & Done (⌘↩)"
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb 2>&1 | tail -20`
Expected: All tests pass, including the new `keyboardShortcutHints` test.

- [ ] **Step 5: Commit**

```bash
git add Breadcrumb/Strings.swift BreadcrumbTests/StringsTests.swift
git commit -m "feat: add keyboard shortcut hint strings for both languages"
```

---

### Task 2: Cmd+Return on StatusEntryForm

**Files:**
- Modify: `Breadcrumb/Views/StatusEntryForm.swift:50-53`

- [ ] **Step 1: Change Save button shortcut and add tooltip**

In `Breadcrumb/Views/StatusEntryForm.swift`, replace lines 50-53:

```swift
Button(Strings.General.save(languageManager.language)) { save() }
    .buttonStyle(.borderedProminent)
    .keyboardShortcut(.defaultAction)
    .disabled(freeText.trimmingCharacters(in: .whitespaces).isEmpty)
```

with:

```swift
Button(Strings.General.save(languageManager.language)) { save() }
    .buttonStyle(.borderedProminent)
    .keyboardShortcut(.return, modifiers: .command)
    .help(Strings.General.saveHint(languageManager.language))
    .disabled(freeText.trimmingCharacters(in: .whitespaces).isEmpty)
```

- [ ] **Step 2: Build to verify compilation**

Run: `xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Breadcrumb/Views/StatusEntryForm.swift
git commit -m "feat: use Cmd+Return to save multi-line status form"
```

---

### Task 3: Cmd+Return on PomodoroSessionEndView save buttons

**Files:**
- Modify: `Breadcrumb/Views/PomodoroSessionEndView.swift:93-95, 117-119`

- [ ] **Step 1: Add Cmd+Return and tooltip to "Save & Done" button**

In `Breadcrumb/Views/PomodoroSessionEndView.swift`, in `focusMateEndContent` (lines 93-95), replace:

```swift
Button(Strings.Pomodoro.saveAndDone(l)) { saveAndDone() }
    .buttonStyle(.borderedProminent)
    .disabled(selectedProject == nil && timer.boundProject == nil)
```

with:

```swift
Button(Strings.Pomodoro.saveAndDone(l)) { saveAndDone() }
    .buttonStyle(.borderedProminent)
    .keyboardShortcut(.return, modifiers: .command)
    .help(Strings.Pomodoro.saveAndDoneHint(l))
    .disabled(selectedProject == nil && timer.boundProject == nil)
```

- [ ] **Step 2: Add Cmd+Return and tooltip to "Save & Break" button**

In `workEndContent` (lines 117-119), replace:

```swift
Button(Strings.Pomodoro.saveAndBreak(l), action: saveAndBreak)
    .buttonStyle(.borderedProminent)
    .disabled(selectedProject == nil && timer.boundProject == nil)
```

with:

```swift
Button(Strings.Pomodoro.saveAndBreak(l), action: saveAndBreak)
    .buttonStyle(.borderedProminent)
    .keyboardShortcut(.return, modifiers: .command)
    .help(Strings.Pomodoro.saveAndBreakHint(l))
    .disabled(selectedProject == nil && timer.boundProject == nil)
```

- [ ] **Step 3: Build to verify compilation**

Run: `xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add Breadcrumb/Views/PomodoroSessionEndView.swift
git commit -m "feat: add Cmd+Return to Pomodoro session-end save buttons"
```

---

### Task 4: Cmd+N on ProjectListView new project button

**Files:**
- Modify: `Breadcrumb/Views/ProjectListView.swift:36-44`

- [ ] **Step 1: Add Cmd+N shortcut and update tooltip**

In `Breadcrumb/Views/ProjectListView.swift`, replace lines 36-44:

```swift
Button(Strings.Projects.newProject(languageManager.language), systemImage: "plus") {
    draftProjectName = ""
    draftProjectIcon = "doc.text"
    showingNewProject = true
}
.labelStyle(.iconOnly)
.font(.body)
.buttonStyle(ToolbarButtonStyle())
.help(Strings.Projects.newProject(languageManager.language))
```

with:

```swift
Button(Strings.Projects.newProject(languageManager.language), systemImage: "plus") {
    draftProjectName = ""
    draftProjectIcon = "doc.text"
    showingNewProject = true
}
.labelStyle(.iconOnly)
.font(.body)
.buttonStyle(ToolbarButtonStyle())
.keyboardShortcut("n", modifiers: .command)
.help(Strings.Projects.newProjectHint(languageManager.language))
```

- [ ] **Step 2: Build to verify compilation**

Run: `xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Breadcrumb/Views/ProjectListView.swift
git commit -m "feat: add Cmd+N shortcut for new project"
```

---

### Task 5: Cmd+U on ProjectDetailView update status button

**Files:**
- Modify: `Breadcrumb/Views/ProjectDetailView.swift:130-133`

- [ ] **Step 1: Add Cmd+U shortcut and tooltip**

In `Breadcrumb/Views/ProjectDetailView.swift`, replace lines 130-133:

```swift
Button(Strings.Status.updateStatus(languageManager.language)) {
    showingStatusForm = true
}
.buttonStyle(.borderedProminent)
```

with:

```swift
Button(Strings.Status.updateStatus(languageManager.language)) {
    showingStatusForm = true
}
.buttonStyle(.borderedProminent)
.keyboardShortcut("u", modifiers: .command)
.help(Strings.Status.updateStatusHint(languageManager.language))
```

- [ ] **Step 2: Build to verify compilation**

Run: `xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Debug build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Run all tests**

Run: `xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb 2>&1 | tail -20`
Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add Breadcrumb/Views/ProjectDetailView.swift
git commit -m "feat: add Cmd+U shortcut for update status"
```

---

## Manual Verification Checklist

After all tasks, verify in the running app:

1. Open popover → project list → press Cmd+N → new project form opens
2. Click a project → press Cmd+U → status form opens
3. In status form → type multi-line text with Return (inserts newline) → press Cmd+Return (saves)
4. Start a Pomodoro → let it end → Cmd+Return saves the session-end form
5. Hover over "+", "Update Status", and Save buttons → tooltips show shortcut hints
6. Switch language → tooltips update to the other language
