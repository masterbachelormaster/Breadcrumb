# OpenRouter Integration Design

**Date:** 2026-04-06
**Status:** Approved

## Goal

Add OpenRouter as an alternative AI backend alongside the existing local Apple LLM (FoundationModels). This enables:

- **Broader device support** — AI extraction works on Macs without Apple Intelligence (pre-macOS 26, Intel Macs)
- **Better quality** — access to stronger models (Claude, GPT-4, etc.)
- **New capabilities** — longer context, more complex reasoning for future features
- **User choice** — global setting to pick preferred backend

## Architecture

```
AIExtractButton -> AIService -> active AIProvider
                                   |-- LocalAIProvider  (FoundationModels, macOS 26+)
                                   |-- OpenRouterProvider (HTTP/JSON, any macOS 14+)
```

`AIService` remains the single `@Observable @MainActor` environment service. It owns UI state (`isGenerating`, `isAvailable`) and delegates to the active provider. Views are unaware of which backend is active.

## Provider Protocol

```swift
protocol AIProvider: Sendable {
    func extractStatus(from text: String, language: AppLanguage) async throws -> ExtractedStatus
}
```

- `Sendable` because values cross the `@MainActor` isolation boundary when `AIService` calls providers
- Use-case focused, not generation-method focused — avoids leaking FoundationModels' `@Generable` into the shared interface
- Future AI features add new methods to the protocol (e.g. `summarize(...)`)

### Shared Output Type

```swift
struct ExtractedStatus: Sendable {
    var lastAction: String
    var nextStep: String
    var openQuestions: String
}
```

Both providers produce this. `LocalAIProvider` maps from `@Generable` types internally. `OpenRouterProvider` decodes JSON into it directly.

### Backend Enum

```swift
enum AIBackend: String, CaseIterable, Sendable {
    case local
    case openRouter
}
```

Stored in `@AppStorage("ai.provider")` in Settings views. `AIService` reads from `UserDefaults` directly (not `@AppStorage`, which cannot be used inside `@Observable` classes per SwiftUI data flow rules).

## Provider Implementations

### LocalAIProvider

```swift
struct LocalAIProvider: AIProvider {
    func extractStatus(from text: String, language: AppLanguage) async throws -> ExtractedStatus
}
```

- Wraps existing FoundationModels guided generation logic extracted from `AIService`
- Uses `ExtractedStatusDE`/`ExtractedStatusEN` `@Generable` types internally
- Maps result to shared `ExtractedStatus`
- Guarded by `#if canImport(FoundationModels)` and `@available(macOS 26, *)`
- Struct with no stored state — automatic `Sendable`

### OpenRouterProvider

```swift
struct OpenRouterProvider: AIProvider {
    let apiKey: String
    let model: String

    func extractStatus(from text: String, language: AppLanguage) async throws -> ExtractedStatus
}
```

- Calls `https://openrouter.ai/api/v1/chat/completions`
- System prompt: `Strings.AIExtraction.instructions(language)`
- User message: the free text
- Uses `response_format: { "type": "json_object" }` for structured JSON output
- Uses `URLSession.shared.data(for:)` (async/await, no GCD)
- `URLRequest.timeoutInterval` = 30 seconds
- Decodes JSON response into `ExtractedStatus`
- Struct with `let` properties — automatic `Sendable`
- In Swift 6.0, nonisolated async methods hop off the caller's actor, so the network call and JSON decoding naturally run off the main thread

### Error Mapping

New cases added to `AIServiceError`:

```swift
case networkError(String)      // connectivity, timeout, unexpected HTTP status
case authenticationFailed      // 401 from OpenRouter (bad API key)
case invalidResponse           // JSON couldn't be parsed into ExtractedStatus
```

Each gets German + English translations in `Strings.Errors`.

HTTP error mapping:
- 401 -> `.authenticationFailed`
- 429 -> `.generationFailed` with rate limit message
- 5xx -> `.networkError` with status description
- Network failure -> `.networkError`
- JSON parse failure -> `.invalidResponse`

No automatic retry — user taps the button again.

## AIService Changes

### Cached Availability

`isAvailable` becomes a stored property (not computed) to avoid reading Keychain on every view body evaluation.

Updated explicitly via `refreshAvailability()`:
- On app launch (`init`)
- When user changes provider, API key, or model in Settings

### New Public Method

```swift
func extractStatus(from text: String, language: AppLanguage) async throws -> ExtractedStatus {
    guard isAvailable else {
        throw AIServiceError.notAvailable(unavailableReason)
    }
    isGenerating = true
    defer { isGenerating = false }
    return try await provider.extractStatus(from: text, language: language)
}
```

Where `provider` is resolved fresh each call (computed, not cached — providers are lightweight value types):
- `.local` -> `LocalAIProvider()` (if FoundationModels available)
- `.openRouter` -> `OpenRouterProvider(apiKey:model:)` (if key + model configured, read from Keychain/UserDefaults at call time)

### Existing Methods

The four existing FoundationModels methods (`generate`, `stream`, guided variants) remain with their `#if canImport` guards. Unused today, available for future local-only features.

## AIExtractButton Changes

- Remove `#if canImport(FoundationModels)` wrapper around entire view body — button now renders on any macOS 14+
- Replace `aiService.generate(prompt:instructions:generating:)` call with `aiService.extractStatus(from:language:)`
- Existing cancellation handling (`extractionTask?.cancel()` on disappear) works for both backends
- Existing error display (4-second dismissal) works for new error types
- `cleanFiller()` logic stays — OpenRouter models may also produce filler text

## Settings UI

### New Section in SettingsView

- **AI Provider picker** — segmented control: "Apple AI" / "OpenRouter"
- Stored in `@AppStorage("ai.provider")`

### OpenRouterSettingsSection (new extracted view)

Shown when OpenRouter is selected:
- **API Key** — `SecureField`, reads/writes via `KeychainHelper`
- **Model** — `TextField` for model ID (e.g. `anthropic/claude-sonnet-4`)
- **Help text** — "Get your API key at openrouter.ai" / "Enter any OpenRouter model ID"
- **Availability indicator** — shows whether the selected backend is ready
- Calls `aiService.refreshAvailability()` when settings change

### Key Storage

- API key: Keychain via `KeychainHelper` (never `@AppStorage` — per Swift hygiene rules, sensitive data must use Keychain)
- Model ID: `@AppStorage("ai.openrouter.model")` (not sensitive)
- Provider choice: `@AppStorage("ai.provider")` (not sensitive)

### KeychainHelper

```swift
enum KeychainHelper {
    static func save(key: String, value: String) -> Bool   // SecItemAdd/SecItemUpdate
    static func read(key: String) -> String?               // SecItemCopyMatching
}
```

Uses Security framework. Service name keyed to bundle ID (`com.roger.breadcrumb`).

## Localization

All new UI strings go through `Strings` enum with both German and English translations:
- Settings labels (provider picker, API key field, model field, help text)
- Error messages (network error, auth failed, invalid response)
- Availability status messages

## Edge Cases

1. **User switches provider mid-generation** — in-flight request completes against old provider. Next request uses new one. `activeProvider` resolved fresh each call.
2. **Empty/invalid API key** — `isAvailable` is `false`, button hidden. No crash, no wasted HTTP call.
3. **Malformed JSON from OpenRouter** — thrown as `.invalidResponse`. Existing 4-second error display handles it.
4. **Rate limiting (429)** — mapped to `.generationFailed`. No automatic retry.
5. **Network timeout** — 30 second timeout, thrown as `.networkError`.
6. **Apple AI selected but unavailable** — same as today. User can now switch to OpenRouter as alternative.
7. **Task cancellation** — `URLSession.data(for:)` respects cooperative cancellation. Existing `extractionTask?.cancel()` on disappear propagates correctly.

## File Changes

### New Files (5)

| File | Purpose |
|------|---------|
| `Services/AIProvider.swift` | `AIProvider` protocol, `ExtractedStatus` struct, `AIBackend` enum |
| `Services/LocalAIProvider.swift` | FoundationModels wrapper |
| `Services/OpenRouterProvider.swift` | HTTP/JSON client for OpenRouter API |
| `Services/KeychainHelper.swift` | Keychain read/write for API key |
| `Views/Settings/OpenRouterSettingsSection.swift` | API key + model config UI |

### Modified Files (4)

| File | Change |
|------|--------|
| `Services/AIService.swift` | Add `extractStatus(from:language:)`, cached `isAvailable`, `refreshAvailability()`, `activeBackend`, provider resolution. Keep existing methods. |
| `Views/AIExtractButton.swift` | Remove `#if canImport(FoundationModels)` gate. Call `extractStatus` instead of `generate`. |
| `Views/Settings/SettingsView.swift` | Add AI provider picker section, embed `OpenRouterSettingsSection`. |
| `Strings.swift` | Add translations for new settings labels, error messages, availability status. |

### Unchanged

- `Models/ExtractedStatus.swift` — `@Generable` types still used internally by `LocalAIProvider`
- `BreadcrumbApp.swift` — `AIService` environment injection unchanged
- `project.yml` — no new dependencies (`Security` framework already available)
- All other views, models, services

### Post-File-Addition

Run `xcodegen generate` after adding new files, before building.

## Constraints

- **Swift 6.0 strict concurrency** — no `@concurrent`, no default main actor isolation. Nonisolated async naturally hops off caller's actor.
- **macOS 14+ deployment target** — OpenRouter path uses only Foundation networking APIs available since macOS 14.
- **No external dependencies** — pure Apple frameworks (Foundation, Security, SwiftUI, optionally FoundationModels).
- **No `@AppStorage` in `@Observable`** — read `UserDefaults` directly in `AIService`.
- **No `@unchecked Sendable`** — providers are value types with immutable/no stored state.
