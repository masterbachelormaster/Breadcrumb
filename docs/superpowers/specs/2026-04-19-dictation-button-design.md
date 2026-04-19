# Dictation Button for Status Entry Fields

## Overview

Add a microphone button to each text field in the status entry form that lets users speak instead of type. Uses Apple's Speech framework (`SFSpeechRecognizer`) for on-device speech-to-text with no Apple dictation UI. Words appear live as the user speaks.

## Scope

- Dictation available on all four status entry fields: freeText, lastAction, nextStep, openQuestions
- Mic button only visible when the field has focus
- One field can dictate at a time
- Bilingual: recognizes German or English based on app language

## Architecture

### SpeechRecognizer

`@Observable @MainActor final class SpeechRecognizer`

Injected as an environment object from `BreadcrumbApp`, same pattern as `AIService`, `PomodoroTimer`, etc.

**Properties:**
- `isListening: Bool` — whether a recognition session is active
- `error: String?` — set if permissions denied or hardware fails

**Methods:**
- `startListening(into: Binding<String>, language: AppLanguage)` — requests mic + speech recognition permissions on first call, starts `AVAudioEngine` and `SFSpeechAudioBufferRecognitionRequest`, writes partial results directly into the provided binding. Uses `Locale("de-DE")` for German, `Locale("en-US")` for English.
- `stopListening()` — ends the recognition task and stops the audio engine.

**Owned resources:**
- `SFSpeechRecognizer` — configured with the appropriate locale
- `AVAudioEngine` — captures microphone audio
- `SFSpeechRecognitionTask` — the active recognition session (nil when idle)

**Behavior:**
- Calling `startListening` while already listening stops the current session first
- Partial results stream in live — the binding updates as words are recognized
- New speech appends to existing text in the field (doesn't replace)
- If permissions are denied, sets `error` and does not start

### DictationButton

`struct DictationButton: View`

A reusable SwiftUI view placed inside each text field.

**Inputs:**
- `Binding<String>` — the field's text binding
- `SpeechRecognizer` from `@Environment`
- `LanguageManager` from `@Environment`
- `Bool` — whether this field currently has focus

**Rendering:**
- Only visible when the field has focus (fade in/out with `.opacity` transition)
- Uses `Button("Dictation", systemImage: "mic.fill", action: toggle)` for VoiceOver accessibility
- Label text localized via `Strings` enum (both languages)
- Normal state: secondary color mic icon
- Listening state: red mic icon with subtle pulse animation using `.animation(.easeInOut.repeatForever(), value: isListening)`

**Button action:**
- If not listening → `startListening(into:language:)`
- If listening on this field → `stopListening()`

### Field Integration

**PlaceholderTextView (freeText):**
- `DictationButton` overlaid in the bottom-right corner of the text view
- Focus state tracked via NSTextView's first responder status (this is an NSViewRepresentable, not a SwiftUI TextField, so `@FocusState` does not apply)

**BulletableField (lastAction, nextStep, openQuestions):**
- `DictationButton` overlaid in the bottom-right corner
- In plain text mode (0-1 items): appends to the text
- In bullet mode (2+ items): appends to the last bullet item

### Auto-stop

Listening stops automatically when:
- The status entry form is dismissed (cancel or save)
- Focus moves away from the active field

## Permissions

**Required entitlements/Info.plist keys:**
- `NSMicrophoneUsageDescription` — "Breadcrumb uses the microphone for speech-to-text in status updates."
- `NSSpeechRecognitionUsageDescription` — "Breadcrumb uses speech recognition to transcribe your status updates."

**If denied:**
- Mic button appears grayed out / disabled
- Tooltip explains that permissions are needed (localized via `Strings` enum)
- No error dialogs or alerts

**If recognition fails mid-session:**
- Listening stops silently
- Already-transcribed text remains in the field
- Mic button returns to normal state

## Localization

New `Strings` entries:
- `Strings.Dictation.buttonLabel(language)` — "Dictation" / "Diktat" (VoiceOver label)
- `Strings.Dictation.permissionRequired(language)` — "Microphone access required" / "Mikrofonzugriff erforderlich"

Info.plist usage descriptions are static English (standard macOS convention).

## Files

| File | Purpose |
|------|---------|
| `SpeechRecognizer.swift` (new) | Speech recognition manager |
| `DictationButton.swift` (new) | Reusable mic button view |
| `StatusEntryForm.swift` (modify) | Add DictationButton to freeText field |
| `PlaceholderTextView.swift` (modify) | Support overlay and focus tracking for mic button |
| `BulletableField.swift` (modify) | Add DictationButton to bullet fields |
| `BreadcrumbApp.swift` (modify) | Create and inject SpeechRecognizer as environment |
| `Strings.swift` (modify) | Add dictation-related translations |
| `project.yml` (modify) | Add Info.plist keys for microphone and speech recognition |

## Out of Scope

- Waveform / audio level visualization (can be added later)
- Custom speech models or vocabulary
- Dictation outside of the status entry form
