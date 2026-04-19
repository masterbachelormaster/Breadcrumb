# Dictation Button Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a mic button to each text field in the status entry form that uses Apple's Speech framework for on-device speech-to-text, with live partial results.

**Architecture:** A single `SpeechRecognizer` service (same `@Observable @MainActor` pattern as `AIService`) injected via environment. A reusable `DictationButton` view overlaid on each text field, visible only when focused. `PlaceholderTextView` gains a focus-tracking callback so SwiftUI can show/hide the button.

**Tech Stack:** Swift 6.0, SwiftUI, Speech framework (`SFSpeechRecognizer`), AVFoundation (`AVAudioEngine`), macOS 26.0

**Spec:** `docs/superpowers/specs/2026-04-19-dictation-button-design.md`

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `Breadcrumb/Services/SpeechRecognizer.swift` | Create | Speech recognition manager — audio engine, permissions, binding relay |
| `Breadcrumb/Views/DictationButton.swift` | Create | Reusable mic button with pulse animation |
| `Breadcrumb/Strings.swift` | Modify | Add `Strings.Dictation` enum with translations |
| `Breadcrumb/Views/PlaceholderTextView.swift` | Modify | Add `onFocusChange` callback for tracking NSTextView first responder |
| `Breadcrumb/Views/StatusEntryForm.swift` | Modify | Overlay DictationButton on freeText field, auto-stop on dismiss |
| `Breadcrumb/Views/BulletableField.swift` | Modify | Overlay DictationButton on plain and list mode fields |
| `Breadcrumb/BreadcrumbApp.swift` | Modify | Create and inject SpeechRecognizer |
| `project.yml` | Modify | Add Info.plist permission keys |
| `BreadcrumbTests/StringsTests.swift` | Modify | Test new Dictation strings |
| `BreadcrumbTests/SpeechRecognizerTests.swift` | Create | Test SpeechRecognizer state management |

---

### Task 1: Add Dictation strings

**Files:**
- Modify: `Breadcrumb/Strings.swift`
- Modify: `BreadcrumbTests/StringsTests.swift`

- [ ] **Step 1: Add `Strings.Dictation` enum**

Add at the end of `Strings.swift`, before the closing brace of `enum Strings`:

```swift
// MARK: - Dictation

enum Dictation {
    static func buttonLabel(_ l: AppLanguage) -> String {
        l == .german ? "Diktat" : "Dictation"
    }
    static func permissionRequired(_ l: AppLanguage) -> String {
        l == .german ? "Mikrofonzugriff erforderlich" : "Microphone access required"
    }
}
```

- [ ] **Step 2: Add tests for Dictation strings**

Add at the end of `BreadcrumbTests/StringsTests.swift`, before the closing brace of `StringsTests`:

```swift
@Test("Dictation strings return correct translations")
func dictationStrings() {
    #expect(Strings.Dictation.buttonLabel(.german) == "Diktat")
    #expect(Strings.Dictation.buttonLabel(.english) == "Dictation")
    #expect(Strings.Dictation.permissionRequired(.german) == "Mikrofonzugriff erforderlich")
    #expect(Strings.Dictation.permissionRequired(.english) == "Microphone access required")
}
```

- [ ] **Step 3: Run tests**

Run: `xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb 2>&1 | tail -20`
Expected: All tests pass including new `dictationStrings` test.

- [ ] **Step 4: Commit**

```bash
git add Breadcrumb/Strings.swift BreadcrumbTests/StringsTests.swift
git commit -m "feat: add Dictation strings for mic button labels"
```

---

### Task 2: Create SpeechRecognizer service

**Files:**
- Create: `Breadcrumb/Services/SpeechRecognizer.swift`
- Create: `BreadcrumbTests/SpeechRecognizerTests.swift`

- [ ] **Step 1: Write SpeechRecognizer tests**

Create `BreadcrumbTests/SpeechRecognizerTests.swift`:

```swift
import Testing
@testable import Breadcrumb

@Suite("SpeechRecognizer Tests")
@MainActor
struct SpeechRecognizerTests {

    @Test("Initial state is not listening")
    func initialState() {
        let recognizer = SpeechRecognizer()
        #expect(recognizer.isListening == false)
        #expect(recognizer.error == nil)
    }

    @Test("stopListening when not listening is safe")
    func stopWhenNotListening() {
        let recognizer = SpeechRecognizer()
        recognizer.stopListening()
        #expect(recognizer.isListening == false)
    }
}
```

- [ ] **Step 2: Create SpeechRecognizer**

Create `Breadcrumb/Services/SpeechRecognizer.swift`:

```swift
import Speech
import AVFoundation
import SwiftUI

@Observable
@MainActor
final class SpeechRecognizer {
    var isListening = false
    var error: String?

    private var audioEngine: AVAudioEngine?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?

    private var currentBinding: Binding<String>?
    private var textBeforeListening = ""

    func startListening(into binding: Binding<String>, language: AppLanguage) {
        if isListening {
            stopListening()
        }

        let locale = language == .german ? Locale(identifier: "de-DE") : Locale(identifier: "en-US")
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            error = "Speech recognition not available"
            return
        }

        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                guard let self else { return }
                switch status {
                case .authorized:
                    self.beginRecognition(into: binding, recognizer: recognizer)
                default:
                    self.error = "Permission denied"
                }
            }
        }
    }

    func stopListening() {
        recognitionTask?.cancel()
        recognitionTask = nil
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        speechRecognizer = nil
        currentBinding = nil
        isListening = false
    }

    private func beginRecognition(into binding: Binding<String>, recognizer: SFSpeechRecognizer) {
        speechRecognizer = recognizer
        currentBinding = binding
        textBeforeListening = binding.wrappedValue

        let engine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true

        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        do {
            engine.prepare()
            try engine.start()
        } catch {
            self.error = "Audio engine failed to start"
            return
        }

        self.audioEngine = engine

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    let transcription = result.bestTranscription.formattedString
                    let prefix = self.textBeforeListening
                    if prefix.isEmpty {
                        self.currentBinding?.wrappedValue = transcription
                    } else {
                        self.currentBinding?.wrappedValue = prefix + " " + transcription
                    }
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.stopListening()
                }
            }
        }

        isListening = true
    }
}
```

- [ ] **Step 3: Run xcodegen and build**

```bash
xcodegen generate
xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Debug build 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Run tests**

Run: `xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb 2>&1 | tail -20`
Expected: All tests pass including `SpeechRecognizerTests`.

- [ ] **Step 5: Commit**

```bash
git add Breadcrumb/Services/SpeechRecognizer.swift BreadcrumbTests/SpeechRecognizerTests.swift
git commit -m "feat: add SpeechRecognizer service for on-device speech-to-text"
```

---

### Task 3: Create DictationButton view

**Files:**
- Create: `Breadcrumb/Views/DictationButton.swift`

- [ ] **Step 1: Create DictationButton**

Create `Breadcrumb/Views/DictationButton.swift`:

```swift
import SwiftUI

struct DictationButton: View {
    @Environment(SpeechRecognizer.self) private var speechRecognizer
    @Environment(LanguageManager.self) private var languageManager

    @Binding var text: String
    var isFocused: Bool

    @State private var isPulsing = false

    var body: some View {
        if isFocused {
            Button(
                Strings.Dictation.buttonLabel(languageManager.language),
                systemImage: speechRecognizer.isListening ? "mic.fill" : "mic",
                action: toggle
            )
            .labelStyle(.iconOnly)
            .foregroundStyle(speechRecognizer.isListening ? .red : .secondary)
            .scaleEffect(isPulsing ? 1.15 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
            .buttonStyle(.borderless)
            .help(
                speechRecognizer.error != nil
                    ? Strings.Dictation.permissionRequired(languageManager.language)
                    : Strings.Dictation.buttonLabel(languageManager.language)
            )
            .disabled(speechRecognizer.error != nil)
            .transition(.opacity)
            .onChange(of: speechRecognizer.isListening) { _, newValue in
                isPulsing = newValue
            }
            .onChange(of: isFocused) { _, focused in
                if !focused && speechRecognizer.isListening {
                    speechRecognizer.stopListening()
                }
            }
        }
    }

    private func toggle() {
        if speechRecognizer.isListening {
            speechRecognizer.stopListening()
        } else {
            speechRecognizer.startListening(into: $text, language: languageManager.language)
        }
    }
}
```

- [ ] **Step 2: Run xcodegen and build**

```bash
xcodegen generate
xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Debug build 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED (may warn about unused `isActiveOnThisField` — remove if so).

- [ ] **Step 3: Commit**

```bash
git add Breadcrumb/Views/DictationButton.swift
git commit -m "feat: add DictationButton view with pulse animation"
```

---

### Task 4: Add focus tracking to PlaceholderTextView

**Files:**
- Modify: `Breadcrumb/Views/PlaceholderTextView.swift`

- [ ] **Step 1: Add onFocusChange callback**

Add a new property to `PlaceholderTextView`:

```swift
struct PlaceholderTextView: NSViewRepresentable {
    var placeholder: String
    @Binding var text: String
    var focusOnAppear: Bool = false
    var onFocusChange: ((Bool) -> Void)?
```

Add focus notification observers in `makeNSView`, after setting `context.coordinator.textView = textView`:

```swift
context.coordinator.textView = textView

NotificationCenter.default.addObserver(
    context.coordinator,
    selector: #selector(Coordinator.textViewDidBecomeFirstResponder),
    name: NSTextView.didBecomeKeyNotification,
    object: nil
)
NotificationCenter.default.addObserver(
    context.coordinator,
    selector: #selector(Coordinator.textViewDidResignFirstResponder),
    name: NSTextView.didResignKeyNotification,
    object: nil
)
```

Wait — `NSTextView` doesn't post `didBecomeKeyNotification`. We need to override `becomeFirstResponder` and `resignFirstResponder` on the custom `PlaceholderNSTextView` instead.

Add to `PlaceholderNSTextView`:

```swift
class PlaceholderNSTextView: NSTextView {
    var placeholderString: String = "" {
        didSet { needsDisplay = true }
    }

    var onFocusChange: ((Bool) -> Void)?

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result { onFocusChange?(true) }
        return result
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result { onFocusChange?(false) }
        return result
    }

    // existing draw(_:) method stays unchanged
```

Wire the callback in `makeNSView`, after creating the textView:

```swift
let textView = PlaceholderNSTextView()
textView.onFocusChange = { [weak context] focused in
    Task { @MainActor in
        context?.coordinator.parent.onFocusChange?(focused)
    }
}
```

And update `updateNSView` to keep the callback in sync:

```swift
func updateNSView(_ scrollView: NSScrollView, context: Context) {
    guard let textView = scrollView.documentView as? PlaceholderNSTextView else { return }
    if textView.string != text {
        textView.string = text
    }
    if textView.placeholderString != placeholder {
        textView.placeholderString = placeholder
    }
    textView.onFocusChange = { [weak context] focused in
        Task { @MainActor in
            context?.coordinator.parent.onFocusChange?(focused)
        }
    }
    // existing focusOnAppear logic unchanged
```

- [ ] **Step 2: Build**

```bash
xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Debug build 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED. Existing callers of `PlaceholderTextView` don't pass `onFocusChange`, which defaults to `nil`.

- [ ] **Step 3: Commit**

```bash
git add Breadcrumb/Views/PlaceholderTextView.swift
git commit -m "feat: add onFocusChange callback to PlaceholderTextView"
```

---

### Task 5: Integrate DictationButton into StatusEntryForm

**Files:**
- Modify: `Breadcrumb/Views/StatusEntryForm.swift`

- [ ] **Step 1: Add focus state and overlay DictationButton on freeText**

Add a `@State` for focus tracking and stop-on-dismiss. In `StatusEntryForm`:

```swift
struct StatusEntryForm: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(SpeechRecognizer.self) private var speechRecognizer
    let project: Project

    @Environment(\.modelContext) private var modelContext

    @Binding var freeText: String
    @Binding var lastAction: String
    @Binding var nextStep: String
    @Binding var openQuestions: String
    var onDismiss: () -> Void = {}
    @State private var showOptionalFields = false
    @State private var freeTextFocused = false
```

Replace the `PlaceholderTextView` block (the view, `.frame`, `.background`, `.clipShape`, `.overlay`) with a ZStack that adds the mic button:

```swift
ZStack(alignment: .bottomTrailing) {
    PlaceholderTextView(
        placeholder: Strings.Status.whereAreYou(languageManager.language),
        text: $freeText,
        focusOnAppear: true,
        onFocusChange: { freeTextFocused = $0 }
    )
    .frame(minHeight: 60, maxHeight: 120)
    .background(Color(nsColor: .textBackgroundColor))
    .clipShape(.rect(cornerRadius: 6))
    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(nsColor: .separatorColor)))

    DictationButton(text: $freeText, isFocused: freeTextFocused)
        .padding(6)
}
```

Add auto-stop to the `onDismiss` wrapper. Change the cancel button action and the save function to stop listening:

In the `save()` function, add `speechRecognizer.stopListening()` as the first line:

```swift
private func save() {
    speechRecognizer.stopListening()
    let trimmed = freeText.trimmingCharacters(in: .whitespaces)
    // ... rest unchanged
```

Change the cancel button to also stop:

```swift
Button(Strings.General.cancel(languageManager.language)) {
    speechRecognizer.stopListening()
    onDismiss()
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Debug build 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Breadcrumb/Views/StatusEntryForm.swift
git commit -m "feat: add dictation button to freeText field in StatusEntryForm"
```

---

### Task 6: Integrate DictationButton into BulletableField

**Files:**
- Modify: `Breadcrumb/Views/BulletableField.swift`

- [ ] **Step 1: Add DictationButton to plain mode and list mode**

Add environment and focus tracking state to `BulletableField`:

```swift
struct BulletableField: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(SpeechRecognizer.self) private var speechRecognizer

    @AppStorage("feature.bulletListsEnabled") private var bulletListsEnabled = true

    let label: String
    @Binding var text: String

    @FocusState private var plainFocused: Bool
    @FocusState private var listFocused: Int?
```

The `plainFocused` `@FocusState` already exists. We can use it directly since `DictationButton` accepts a `Bool`.

For list mode, derive focus from `listFocused != nil`.

Update `plainModeField` to wrap in a ZStack with the mic button:

```swift
@ViewBuilder
private var plainModeField: some View {
    ZStack(alignment: .trailing) {
        TextField(label, text: $text)
            .textFieldStyle(.roundedBorder)
            .focused($plainFocused)
        DictationButton(text: $text, isFocused: plainFocused)
            .padding(.trailing, 6)
    }
}
```

Update `listModeField` to add a mic button on the last row. Replace the entire `listModeField` computed property:

```swift
@ViewBuilder
private var listModeField: some View {
    VStack(alignment: .leading, spacing: 4) {
        ForEach(Array(items.enumerated()), id: \.offset) { index, item in
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("•")
                    .foregroundStyle(.secondary)
                ZStack(alignment: .trailing) {
                    TextField(label, text: bindingForItem(at: index))
                        .textFieldStyle(.roundedBorder)
                        .focused($listFocused, equals: index)
                        .onSubmit {
                            guard bulletListsEnabled else { return }
                            insertBullet(after: index)
                        }
                    if index == items.count - 1 {
                        DictationButton(text: $text, isFocused: listFocused != nil)
                            .padding(.trailing, 6)
                    }
                }
                Button {
                    removeBullet(at: index)
                } label: {
                    Image(systemName: "minus.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(Strings.General.delete(languageManager.language))
            }
        }
    }
}
```

Note: In list mode, dictation appends to the `text` binding (the full string), which means new spoken words append after the last newline. This is correct because `BulletText.parseRaw` will place them in the last bullet.

- [ ] **Step 2: Build**

```bash
xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Debug build 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Run tests**

```bash
xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb 2>&1 | tail -20
```

Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add Breadcrumb/Views/BulletableField.swift
git commit -m "feat: add dictation button to BulletableField"
```

---

### Task 7: Integrate DictationButton into PomodoroSessionEndView

**Files:**
- Modify: `Breadcrumb/Views/PomodoroSessionEndView.swift`

- [ ] **Step 1: Add focus state and DictationButton overlay**

Add environment and state to `PomodoroSessionEndView`:

```swift
@Environment(SpeechRecognizer.self) private var speechRecognizer
@State private var freeTextFocused = false
```

Replace the `PlaceholderTextView` block (lines ~145-153) with a ZStack, same pattern as StatusEntryForm:

```swift
ZStack(alignment: .bottomTrailing) {
    PlaceholderTextView(
        placeholder: Strings.Status.whereAreYou(l),
        text: $freeText,
        focusOnAppear: !wasBreak,
        onFocusChange: { freeTextFocused = $0 }
    )
    .frame(minHeight: 50, maxHeight: 100)
    .background(Color(nsColor: .textBackgroundColor))
    .clipShape(.rect(cornerRadius: 6))
    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(nsColor: .separatorColor)))

    DictationButton(text: $freeText, isFocused: freeTextFocused)
        .padding(6)
}
```

The `BulletableField` instances already have their own DictationButton from Task 6, so no changes needed there.

Add `speechRecognizer.stopListening()` at the start of `saveAndBreak()`, `saveAndContinue()`, and `saveAndStop()` methods — whichever save methods exist in this file.

- [ ] **Step 2: Build**

```bash
xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Debug build 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Breadcrumb/Views/PomodoroSessionEndView.swift
git commit -m "feat: add dictation button to PomodoroSessionEndView"
```

---

### Task 8: Inject SpeechRecognizer and add Info.plist keys

**Files:**
- Modify: `Breadcrumb/BreadcrumbApp.swift`
- Modify: `project.yml`

- [ ] **Step 1: Add SpeechRecognizer to BreadcrumbApp**

Add the state property alongside the other services:

```swift
@State private var notificationService = NotificationService()
@State private var speechRecognizer = SpeechRecognizer()
```

Add `.environment(speechRecognizer)` to both scenes. In the `MenuBarExtra` scene, after `.environment(languageManager)`:

```swift
.environment(languageManager)
.environment(speechRecognizer)
```

In the `Window` scene, after `.environment(languageManager)`:

```swift
.environment(languageManager)
.environment(speechRecognizer)
```

- [ ] **Step 2: Add Info.plist permission keys to project.yml**

Add under `info: properties:` in the `Breadcrumb` target, after the existing entries:

```yaml
info:
  path: Breadcrumb/Info.plist
  properties:
    LSUIElement: true
    LSMinimumSystemVersion: $(MACOSX_DEPLOYMENT_TARGET)
    CFBundleDisplayName: Breadcrumb
    CFBundleIconFile: ""
    NSMicrophoneUsageDescription: "Breadcrumb uses the microphone for speech-to-text in status updates."
    NSSpeechRecognitionUsageDescription: "Breadcrumb uses speech recognition to transcribe your status updates."
```

- [ ] **Step 3: Regenerate and build**

```bash
xcodegen generate
xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Debug build 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Run all tests**

```bash
xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb 2>&1 | tail -20
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add Breadcrumb/BreadcrumbApp.swift project.yml
git commit -m "feat: inject SpeechRecognizer and add microphone/speech permission keys"
```

---

### Task 9: Manual testing

- [ ] **Step 1: Install and launch**

```bash
xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Release build 2>&1 | tail -5
cp -R ~/Library/Developer/Xcode/DerivedData/Breadcrumb-*/Build/Products/Release/Breadcrumb.app /Applications/
open /Applications/Breadcrumb.app
```

- [ ] **Step 2: Test dictation on freeText field**

1. Open a project, click "Update Status"
2. Click into the "Where are you?" text field
3. Verify: mic button appears in bottom-right corner
4. Click mic button — grant microphone and speech recognition permissions if prompted
5. Speak a sentence — verify words appear live in the field
6. Click mic button again — verify it stops and text stays
7. Type some text first, then tap mic — verify speech appends after existing text

- [ ] **Step 3: Test dictation on optional fields**

1. Expand "Optional Fields"
2. Click into "Last Step" text field
3. Verify: mic button appears
4. Speak — verify text appears
5. Add a second bullet, verify mic shows on the last bullet row

- [ ] **Step 4: Test auto-stop**

1. Start dictation on freeText
2. Click Cancel — verify dictation stops
3. Start dictation on freeText
4. Click Save — verify dictation stops and entry saves

- [ ] **Step 5: Test in PomodoroSessionEndView**

1. Start a Pomodoro session, let work phase end
2. Verify: mic button appears on the freeText field in the session end view
3. Test dictation works the same as in the status entry form

- [ ] **Step 6: Test language switching**

1. Switch app language to English in Settings
2. Open status form, start dictation
3. Speak in English — verify recognition works
4. Switch back to German, verify German recognition works
