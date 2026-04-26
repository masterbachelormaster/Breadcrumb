# Native Dictation Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a native macOS dictation button that triggers system dictation via the responder chain, replacing the custom SpeechRecognizer-based button in status entry forms.

**Architecture:** A new `NativeDictationButton` view calls `NSApp.sendAction(#selector(NSTextView.startDictation(_:)), to: nil, from: nil)` to trigger system dictation on the focused NSTextView. The button is gated by the existing `feature.dictationEnabled` AppStorage flag and replaces `DictationButton` references in the two form views. The old dictation code stays untouched.

**Tech Stack:** Swift 6.0, SwiftUI, macOS 26.0, AppKit (NSApp.sendAction)

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `Breadcrumb/Views/NativeDictationButton.swift` | Create | Mic button view triggering system dictation |
| `Breadcrumb/Views/StatusEntryForm.swift` | Modify | Swap DictationButton → NativeDictationButton |
| `Breadcrumb/Views/PomodoroSessionEndView.swift` | Modify | Swap DictationButton → NativeDictationButton |

---

### Task 1: Create NativeDictationButton

**Files:**
- Create: `Breadcrumb/Views/NativeDictationButton.swift`

- [ ] **Step 1: Create NativeDictationButton.swift**

```swift
import SwiftUI
import AppKit

struct NativeDictationButton: View {
    @AppStorage("feature.dictationEnabled") private var dictationEnabled = false

    var isFocused: Bool

    var body: some View {
        if dictationEnabled {
            Button(
                action: startDictation,
                label: { Image(systemName: "mic.fill") }
            )
            .labelStyle(.iconOnly)
            .foregroundStyle(.secondary)
            .buttonStyle(.borderless)
            .opacity(isFocused ? 1 : 0)
            .allowsHitTesting(isFocused)
        }
    }

    private func startDictation() {
        NSApp.sendAction(#selector(NSTextView.startDictation(_:)), to: nil, from: nil)
    }
}
```

- [ ] **Step 2: Add file to project and build**

Run `xcodegen generate` then build:
```bash
cd /Users/roger/Claude/Code/Breadcrumb
xcodegen generate
xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Debug build
```

Expected: Build succeeds with no errors.

- [ ] **Step 3: Commit**

```bash
git add Breadcrumb/Views/NativeDictationButton.swift
git commit -m "feat: add NativeDictationButton triggering macOS system dictation"
```

---

### Task 2: Swap DictationButton for NativeDictationButton in StatusEntryForm

**Files:**
- Modify: `Breadcrumb/Views/StatusEntryForm.swift`

- [ ] **Step 1: Replace DictationButton with NativeDictationButton**

In `StatusEntryForm.swift`, replace line 35:
```swift
DictationButton(text: $freeText, isFocused: freeTextFocused)
```
with:
```swift
NativeDictationButton(isFocused: freeTextFocused)
```

- [ ] **Step 2: Remove unused SpeechRecognizer environment and stopListening calls**

The `SpeechRecognizer` environment (line 6) and its `stopListening()` calls (lines 56 and 77) are no longer needed in this file. Remove them:

1. Remove line 6:
```swift
@Environment(SpeechRecognizer.self) private var speechRecognizer
```

2. In the cancel button action (line 56), remove:
```swift
speechRecognizer.stopListening()
```

3. In the `save()` method (line 77), remove:
```swift
speechRecognizer.stopListening()
```

- [ ] **Step 3: Build**

```bash
cd /Users/roger/Claude/Code/Breadcrumb
xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Debug build
```

Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
git add Breadcrumb/Views/StatusEntryForm.swift
git commit -m "feat: use NativeDictationButton in StatusEntryForm"
```

---

### Task 3: Swap DictationButton for NativeDictationButton in PomodoroSessionEndView

**Files:**
- Modify: `Breadcrumb/Views/PomodoroSessionEndView.swift`

- [ ] **Step 1: Replace DictationButton with NativeDictationButton**

In `PomodoroSessionEndView.swift`, replace line 147:
```swift
DictationButton(text: $freeText, isFocused: freeTextFocused)
```
with:
```swift
NativeDictationButton(isFocused: freeTextFocused)
```

- [ ] **Step 2: Remove unused SpeechRecognizer environment and stopListening calls**

1. Remove line 8:
```swift
@Environment(SpeechRecognizer.self) private var speechRecognizer
```

2. In `saveAndBreak()` (line 168), remove:
```swift
speechRecognizer.stopListening()
```

3. In `saveAndDone()` (line 200), remove:
```swift
speechRecognizer.stopListening()
```

- [ ] **Step 3: Build**

```bash
cd /Users/roger/Claude/Code/Breadcrumb
xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Debug build
```

Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
git add Breadcrumb/Views/PomodoroSessionEndView.swift
git commit -m "feat: use NativeDictationButton in PomodoroSessionEndView"
```

---

### Task 4: Manual verification

- [ ] **Step 1: Build and install**

```bash
cd /Users/roger/Claude/Code/Breadcrumb
xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Release build
cp -R ~/Library/Developer/Xcode/DerivedData/Breadcrumb-*/Build/Products/Release/Breadcrumb.app /Applications/
open /Applications/Breadcrumb.app
```

- [ ] **Step 2: Verify feature flag off**

Open the app. Go to a project and click "Update Status". Confirm no mic button appears in the text field.

- [ ] **Step 3: Enable dictation and test**

Go to Settings → General → toggle "Dictation (Experimental)" on. Open a status form again. Confirm:
- Mic button appears when the text field is focused
- Clicking the mic button triggers macOS system dictation (the system dictation indicator appears)
- Spoken text is inserted into the text field
- Mic button disappears when the text field loses focus

- [ ] **Step 4: Test in Pomodoro end view**

Start a Pomodoro session, let it finish (or use a short duration). On the session end overlay, confirm the same behavior: mic button visible when focused, triggers system dictation.
