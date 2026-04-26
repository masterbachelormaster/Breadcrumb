# Native Dictation Integration

## Overview

Replace the custom `SpeechRecognizer`-based dictation button with a native macOS dictation button that triggers the system dictation built into macOS via `NSTextView.startDictation(_:)`. The existing experimental dictation code (`SpeechRecognizer`, `DictationButton`) stays in the codebase untouched but is no longer referenced from any view.

## Scope

- New `NativeDictationButton` view that triggers macOS system dictation
- Shown in `StatusEntryForm` and `PomodoroSessionEndView` (same two places as the old button)
- Gated by existing `feature.dictationEnabled` AppStorage flag
- Settings label stays as "Dictation (Experimental)"

## Architecture

### NativeDictationButton

`struct NativeDictationButton: View`

A mic icon button that triggers macOS system dictation through the responder chain.

**Inputs:**
- `isFocused: Bool` — whether the associated text field has focus

**Rendering:**
- Only visible when the field has focus (same pattern as old `DictationButton`)
- Mic icon (`mic.fill`), borderless button style
- No pulse animation — macOS shows its own dictation indicator when active

**Action:**
- Calls `NSApp.sendAction(#selector(NSTextView.startDictation(_:)), to: nil, from: nil)`
- This routes through the macOS responder chain to the focused NSTextView inside `PlaceholderTextView`
- macOS handles all audio capture, speech recognition, and text insertion

### Form Integration

`StatusEntryForm` and `PomodoroSessionEndView` each replace their `DictationButton(...)` call with `NativeDictationButton(...)`. The `feature.dictationEnabled` AppStorage flag controls visibility. No other changes to these forms.

### What Stays Untouched

- `SpeechRecognizer.swift` — no changes
- `DictationButton.swift` — no changes
- `PlaceholderTextView.swift` — no changes
- `BreadcrumbApp.swift` — `SpeechRecognizer` stays in environment (still referenced by old code)
- `SettingsView.swift` — toggle label stays "Dictation (Experimental)"
- `Strings.swift` — existing dictation strings stay
- `project.yml` / `Info.plist` — microphone and speech recognition keys stay (system dictation may use them)

## Files

| File | Change |
|------|--------|
| `NativeDictationButton.swift` (new) | Native dictation button view |
| `StatusEntryForm.swift` (modify) | Swap `DictationButton` for `NativeDictationButton` |
| `PomodoroSessionEndView.swift` (modify) | Swap `DictationButton` for `NativeDictationButton` |

## Out of Scope

- Removing old dictation code (`SpeechRecognizer`, `DictationButton`)
- Changing the settings label or feature flag name
- Dictation outside of status entry forms
- Custom dictation UI or indicators
