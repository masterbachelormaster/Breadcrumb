# OpenRouter Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add OpenRouter as an alternative AI backend alongside the local Apple LLM, so AI extraction works on any Mac and with any OpenRouter model.

**Architecture:** Protocol-based provider pattern. `AIService` remains the `@Observable @MainActor` environment service, delegating to an `AIProvider` protocol. Two implementations: `LocalAIProvider` (FoundationModels) and `OpenRouterProvider` (HTTP/JSON). User picks backend in Settings.

**Tech Stack:** Swift 6.0, SwiftUI (macOS 14+), Foundation networking (URLSession async), Security framework (Keychain), Swift Testing.

**Spec:** `docs/superpowers/specs/2026-04-06-openrouter-integration-design.md`

**Swift skills:** Always invoke `swiftui-pro`, `swift-concurrency-pro`, and `swiftdata-pro` (if touching models) before writing or reviewing any code. See `CLAUDE.md` for details.

---

### Task 1: Shared Types — AIProvider Protocol, ExtractedStatus, AIBackend

**Files:**
- Create: `Breadcrumb/Services/AIProvider.swift`
- Test: `BreadcrumbTests/AIProviderTests.swift`

- [ ] **Step 1: Write the test file**

```swift
import Testing
@testable import Breadcrumb

@Suite("AIProvider Types Tests")
struct AIProviderTypesTests {

    @Test("ExtractedStatus initializes with correct values")
    func extractedStatusInit() {
        let status = ExtractedStatus(
            lastAction: "Wrote intro",
            nextStep: "Add data section",
            openQuestions: "Which dataset?"
        )
        #expect(status.lastAction == "Wrote intro")
        #expect(status.nextStep == "Add data section")
        #expect(status.openQuestions == "Which dataset?")
    }

    @Test("ExtractedStatus supports empty fields")
    func extractedStatusEmpty() {
        let status = ExtractedStatus(lastAction: "", nextStep: "", openQuestions: "")
        #expect(status.lastAction.isEmpty)
        #expect(status.nextStep.isEmpty)
        #expect(status.openQuestions.isEmpty)
    }

    @Test("AIBackend raw values match UserDefaults keys")
    func aiBackendRawValues() {
        #expect(AIBackend.local.rawValue == "local")
        #expect(AIBackend.openRouter.rawValue == "openRouter")
    }

    @Test("AIBackend has all expected cases")
    func aiBackendCases() {
        let allCases = AIBackend.allCases
        #expect(allCases.count == 2)
        #expect(allCases.contains(.local))
        #expect(allCases.contains(.openRouter))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodegen generate && xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb 2>&1 | tail -20`
Expected: FAIL — `ExtractedStatus`, `AIBackend` not defined.

- [ ] **Step 3: Write the implementation**

Create `Breadcrumb/Services/AIProvider.swift`:

```swift
import Foundation

// MARK: - Shared Output Type

struct ExtractedStatus: Sendable {
    var lastAction: String
    var nextStep: String
    var openQuestions: String
}

// MARK: - Backend Selection

enum AIBackend: String, CaseIterable, Sendable {
    case local
    case openRouter
}

// MARK: - Provider Protocol

protocol AIProvider: Sendable {
    func extractStatus(from text: String, language: AppLanguage) async throws -> ExtractedStatus
}
```

- [ ] **Step 4: Run xcodegen and tests**

Run: `xcodegen generate && xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb 2>&1 | tail -20`
Expected: All tests PASS, including new AIProviderTests.

- [ ] **Step 5: Commit**

```bash
git add Breadcrumb/Services/AIProvider.swift BreadcrumbTests/AIProviderTests.swift
git commit -m "feat: add AIProvider protocol, ExtractedStatus, and AIBackend types"
```

---

### Task 2: KeychainHelper

**Files:**
- Create: `Breadcrumb/Services/KeychainHelper.swift`
- Test: `BreadcrumbTests/KeychainHelperTests.swift`

- [ ] **Step 1: Write the test file**

```swift
import Testing
@testable import Breadcrumb

@Suite("KeychainHelper Tests")
struct KeychainHelperTests {

    private let testKey = "com.roger.breadcrumb.test.keychainHelper"

    @Test("Save and read a value")
    func saveAndRead() {
        // Clean up any leftover from previous test runs
        KeychainHelper.delete(key: testKey)

        let saved = KeychainHelper.save(key: testKey, value: "test-api-key-123")
        #expect(saved)

        let retrieved = KeychainHelper.read(key: testKey)
        #expect(retrieved == "test-api-key-123")

        // Clean up
        KeychainHelper.delete(key: testKey)
    }

    @Test("Read returns nil for missing key")
    func readMissing() {
        KeychainHelper.delete(key: testKey)
        let result = KeychainHelper.read(key: testKey)
        #expect(result == nil)
    }

    @Test("Save overwrites existing value")
    func saveOverwrites() {
        KeychainHelper.delete(key: testKey)

        _ = KeychainHelper.save(key: testKey, value: "first")
        _ = KeychainHelper.save(key: testKey, value: "second")

        let result = KeychainHelper.read(key: testKey)
        #expect(result == "second")

        KeychainHelper.delete(key: testKey)
    }

    @Test("Delete removes the value")
    func deleteKey() {
        _ = KeychainHelper.save(key: testKey, value: "to-delete")
        KeychainHelper.delete(key: testKey)

        let result = KeychainHelper.read(key: testKey)
        #expect(result == nil)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodegen generate && xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb 2>&1 | tail -20`
Expected: FAIL — `KeychainHelper` not defined.

- [ ] **Step 3: Write the implementation**

Create `Breadcrumb/Services/KeychainHelper.swift`:

```swift
import Foundation
import Security

enum KeychainHelper {

    private static let service = "com.roger.breadcrumb"

    @discardableResult
    static func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Try to update first
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data,
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess { return true }

        // If not found, add new
        var addQuery = query
        addQuery[kSecValueData as String] = data
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        return addStatus == errSecSuccess
    }

    static func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    static func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}
```

- [ ] **Step 4: Run xcodegen and tests**

Run: `xcodegen generate && xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb 2>&1 | tail -20`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add Breadcrumb/Services/KeychainHelper.swift BreadcrumbTests/KeychainHelperTests.swift
git commit -m "feat: add KeychainHelper for secure API key storage"
```

---

### Task 3: LocalAIProvider

**Files:**
- Create: `Breadcrumb/Services/LocalAIProvider.swift`

No unit test for this task — `LocalAIProvider` wraps FoundationModels which requires macOS 26+ and a real device with Apple Intelligence. The existing `AIExtractButton` integration provides coverage. We test the protocol conformance indirectly via the types test in Task 1.

- [ ] **Step 1: Write the implementation**

Create `Breadcrumb/Services/LocalAIProvider.swift`:

```swift
import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(macOS 26, *)
struct LocalAIProvider: AIProvider {
    func extractStatus(from text: String, language: AppLanguage) async throws -> ExtractedStatus {
        let instructions = Strings.AIExtraction.instructions(language)
        let session = LanguageModelSession(instructions: Instructions(instructions))

        switch language {
        case .german:
            let response = try await session.respond(to: text, generating: ExtractedStatusDE.self)
            let result = response.content
            return ExtractedStatus(
                lastAction: result.lastAction,
                nextStep: result.nextStep,
                openQuestions: result.openQuestions
            )
        case .english:
            let response = try await session.respond(to: text, generating: ExtractedStatusEN.self)
            let result = response.content
            return ExtractedStatus(
                lastAction: result.lastAction,
                nextStep: result.nextStep,
                openQuestions: result.openQuestions
            )
        }
    }
}
#endif
```

- [ ] **Step 2: Run xcodegen and build**

Run: `xcodegen generate && xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Debug build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add Breadcrumb/Services/LocalAIProvider.swift
git commit -m "feat: add LocalAIProvider wrapping FoundationModels"
```

---

### Task 4: OpenRouterProvider

**Files:**
- Create: `Breadcrumb/Services/OpenRouterProvider.swift`
- Test: `BreadcrumbTests/OpenRouterProviderTests.swift`

- [ ] **Step 1: Write the test file**

Tests verify JSON parsing and error mapping without making real HTTP calls.

```swift
import Testing
import Foundation
@testable import Breadcrumb

@Suite("OpenRouterProvider Tests")
struct OpenRouterProviderTests {

    @Test("Parses valid JSON response into ExtractedStatus")
    func parseValidJSON() throws {
        let json = """
        {
            "lastAction": "Wrote the introduction",
            "nextStep": "Add methodology section. Review references",
            "openQuestions": "Which framework to use?"
        }
        """
        let data = Data(json.utf8)
        let status = try JSONDecoder().decode(ExtractedStatus.self, from: data)
        #expect(status.lastAction == "Wrote the introduction")
        #expect(status.nextStep == "Add methodology section. Review references")
        #expect(status.openQuestions == "Which framework to use?")
    }

    @Test("Parses JSON with empty fields")
    func parseEmptyFields() throws {
        let json = """
        {
            "lastAction": "",
            "nextStep": "Start writing",
            "openQuestions": ""
        }
        """
        let data = Data(json.utf8)
        let status = try JSONDecoder().decode(ExtractedStatus.self, from: data)
        #expect(status.lastAction.isEmpty)
        #expect(status.nextStep == "Start writing")
        #expect(status.openQuestions.isEmpty)
    }

    @Test("buildRequest creates correct URLRequest")
    func buildRequest() throws {
        let provider = OpenRouterProvider(apiKey: "sk-test-123", model: "anthropic/claude-sonnet-4")
        let request = provider.buildRequest(
            systemPrompt: "You are a parser",
            userMessage: "I finished the intro"
        )
        #expect(request.url?.absoluteString == "https://openrouter.ai/api/v1/chat/completions")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-test-123")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.timeoutInterval == 30)

        let body = try JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
        #expect(body["model"] as? String == "anthropic/claude-sonnet-4")

        let responseFormat = body["response_format"] as! [String: String]
        #expect(responseFormat["type"] == "json_object")
    }

    @Test("mapHTTPError maps 401 to authenticationFailed")
    func map401() {
        let error = OpenRouterProvider.mapHTTPError(statusCode: 401, body: "")
        if case .authenticationFailed = error {
            // pass
        } else {
            Issue.record("Expected .authenticationFailed, got \(error)")
        }
    }

    @Test("mapHTTPError maps 429 to generationFailed")
    func map429() {
        let error = OpenRouterProvider.mapHTTPError(statusCode: 429, body: "")
        if case .generationFailed = error {
            // pass
        } else {
            Issue.record("Expected .generationFailed, got \(error)")
        }
    }

    @Test("mapHTTPError maps 500 to networkError")
    func map500() {
        let error = OpenRouterProvider.mapHTTPError(statusCode: 500, body: "")
        if case .networkError = error {
            // pass
        } else {
            Issue.record("Expected .networkError, got \(error)")
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodegen generate && xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb 2>&1 | tail -20`
Expected: FAIL — `OpenRouterProvider` not defined, `ExtractedStatus` doesn't conform to `Decodable`.

- [ ] **Step 3: Add Codable conformance to ExtractedStatus**

In `Breadcrumb/Services/AIProvider.swift`, update the struct:

```swift
struct ExtractedStatus: Sendable, Codable {
    var lastAction: String
    var nextStep: String
    var openQuestions: String
}
```

- [ ] **Step 4: Write the OpenRouterProvider implementation**

Create `Breadcrumb/Services/OpenRouterProvider.swift`:

```swift
import Foundation

struct OpenRouterProvider: AIProvider {
    let apiKey: String
    let model: String

    func extractStatus(from text: String, language: AppLanguage) async throws -> ExtractedStatus {
        let systemPrompt = Strings.AIExtraction.instructions(language) + "\n\n" + jsonInstructions(language)
        let request = buildRequest(systemPrompt: systemPrompt, userMessage: text)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AIServiceError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.networkError("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            throw Self.mapHTTPError(statusCode: httpResponse.statusCode, body: String(data: data, encoding: .utf8) ?? "")
        }

        return try parseResponse(data)
    }

    // MARK: - Internal (visible for testing)

    func buildRequest(systemPrompt: String, userMessage: String) -> URLRequest {
        var request = URLRequest(url: URL(string: "https://openrouter.ai/api/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "response_format": ["type": "json_object"],
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userMessage],
            ],
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }

    static func mapHTTPError(statusCode: Int, body: String) -> AIServiceError {
        switch statusCode {
        case 401:
            return .authenticationFailed
        case 429:
            return .generationFailed("Rate limit exceeded")
        default:
            return .networkError("HTTP \(statusCode): \(body.prefix(200))")
        }
    }

    // MARK: - Private

    private func parseResponse(_ data: Data) throws -> ExtractedStatus {
        struct OpenRouterResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }

        let apiResponse: OpenRouterResponse
        do {
            apiResponse = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        } catch {
            throw AIServiceError.invalidResponse
        }

        guard let content = apiResponse.choices.first?.message.content else {
            throw AIServiceError.invalidResponse
        }

        guard let contentData = content.data(using: .utf8) else {
            throw AIServiceError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(ExtractedStatus.self, from: contentData)
        } catch {
            throw AIServiceError.invalidResponse
        }
    }

    private func jsonInstructions(_ language: AppLanguage) -> String {
        switch language {
        case .german:
            return """
                Antworte ausschliesslich mit einem JSON-Objekt mit diesen Feldern:
                {"lastAction": "...", "nextStep": "...", "openQuestions": "..."}
                Lass Felder leer ("") wenn nichts zutrifft.
                """
        case .english:
            return """
                Respond only with a JSON object with these fields:
                {"lastAction": "...", "nextStep": "...", "openQuestions": "..."}
                Leave fields empty ("") if nothing applies.
                """
        }
    }
}
```

- [ ] **Step 5: Run xcodegen and tests**

Run: `xcodegen generate && xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb 2>&1 | tail -20`
Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add Breadcrumb/Services/AIProvider.swift Breadcrumb/Services/OpenRouterProvider.swift BreadcrumbTests/OpenRouterProviderTests.swift
git commit -m "feat: add OpenRouterProvider with HTTP/JSON extraction"
```

---

### Task 5: New Error Cases and Strings

**Files:**
- Modify: `Breadcrumb/Services/AIService.swift` (lines 10-37 — error enum)
- Modify: `Breadcrumb/Strings.swift` (lines 429-460 — Errors section, lines 301-341 — Settings section)
- Modify: `BreadcrumbTests/StringsTests.swift`

- [ ] **Step 1: Write the test for new strings**

Add to `BreadcrumbTests/StringsTests.swift` after the existing `snoozeStrings` test (line 118):

```swift
    @Test("AI settings strings return correct translations")
    func aiSettingsStrings() {
        #expect(Strings.Settings.aiProvider(.german) == "KI-Anbieter")
        #expect(Strings.Settings.aiProvider(.english) == "AI Provider")
        #expect(Strings.Settings.aiProviderLocal(.german) == "Apple KI")
        #expect(Strings.Settings.aiProviderLocal(.english) == "Apple AI")
        #expect(Strings.Settings.aiProviderOpenRouter(.german) == "OpenRouter")
        #expect(Strings.Settings.aiProviderOpenRouter(.english) == "OpenRouter")
        #expect(Strings.Settings.apiKey(.german) == "API-Schlüssel")
        #expect(Strings.Settings.apiKey(.english) == "API Key")
        #expect(Strings.Settings.model(.german) == "Modell")
        #expect(Strings.Settings.model(.english) == "Model")
        #expect(Strings.Settings.apiKeyPlaceholder(.german) == "OpenRouter API-Schlüssel eingeben")
        #expect(Strings.Settings.apiKeyPlaceholder(.english) == "Enter OpenRouter API key")
        #expect(Strings.Settings.modelPlaceholder(.german) == "z. B. anthropic/claude-sonnet-4")
        #expect(Strings.Settings.modelPlaceholder(.english) == "e.g. anthropic/claude-sonnet-4")
        #expect(Strings.Settings.apiKeyHelp(.german).contains("openrouter.ai"))
        #expect(Strings.Settings.apiKeyHelp(.english).contains("openrouter.ai"))
        #expect(Strings.Settings.modelHelp(.german).contains("Modell-ID"))
        #expect(Strings.Settings.modelHelp(.english).contains("model ID"))
        #expect(Strings.Settings.aiReady(.german) == "Bereit")
        #expect(Strings.Settings.aiReady(.english) == "Ready")
        #expect(Strings.Settings.aiNotConfigured(.german) == "Nicht konfiguriert")
        #expect(Strings.Settings.aiNotConfigured(.english) == "Not configured")
    }

    @Test("AI error strings for new error cases")
    func aiErrorStrings() {
        #expect(Strings.Errors.networkError(.german, message: "timeout").contains("Netzwerk"))
        #expect(Strings.Errors.networkError(.english, message: "timeout").contains("Network"))
        #expect(Strings.Errors.authenticationFailed(.german).contains("API"))
        #expect(Strings.Errors.authenticationFailed(.english).contains("API"))
        #expect(Strings.Errors.invalidResponse(.german).contains("Antwort"))
        #expect(Strings.Errors.invalidResponse(.english).contains("response"))
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodegen generate && xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb 2>&1 | tail -20`
Expected: FAIL — new `Strings.Settings` and `Strings.Errors` methods not defined.

- [ ] **Step 3: Add new error cases to AIServiceError**

In `Breadcrumb/Services/AIService.swift`, add three cases to the `AIServiceError` enum (after line 15, before `generationFailed`):

```swift
    case networkError(String)
    case authenticationFailed
    case invalidResponse
```

Update the `description(for:)` method to handle them (add before the `generationFailed` case):

```swift
        case .networkError(let message):
            return Strings.Errors.networkError(language, message: message)
        case .authenticationFailed:
            return Strings.Errors.authenticationFailed(language)
        case .invalidResponse:
            return Strings.Errors.invalidResponse(language)
```

- [ ] **Step 4: Add new Strings**

In `Breadcrumb/Strings.swift`, add to the `Settings` enum (after `noSound`, before the closing `}`):

```swift
        static func aiProvider(_ l: AppLanguage) -> String {
            l == .german ? "KI-Anbieter" : "AI Provider"
        }
        static func aiProviderLocal(_ l: AppLanguage) -> String {
            l == .german ? "Apple KI" : "Apple AI"
        }
        static func aiProviderOpenRouter(_ l: AppLanguage) -> String {
            "OpenRouter"
        }
        static func apiKey(_ l: AppLanguage) -> String {
            l == .german ? "API-Schlüssel" : "API Key"
        }
        static func model(_ l: AppLanguage) -> String {
            l == .german ? "Modell" : "Model"
        }
        static func apiKeyPlaceholder(_ l: AppLanguage) -> String {
            l == .german ? "OpenRouter API-Schlüssel eingeben" : "Enter OpenRouter API key"
        }
        static func modelPlaceholder(_ l: AppLanguage) -> String {
            l == .german ? "z. B. anthropic/claude-sonnet-4" : "e.g. anthropic/claude-sonnet-4"
        }
        static func apiKeyHelp(_ l: AppLanguage) -> String {
            l == .german ? "API-Schlüssel von openrouter.ai" : "Get your API key at openrouter.ai"
        }
        static func modelHelp(_ l: AppLanguage) -> String {
            l == .german ? "Beliebige OpenRouter Modell-ID eingeben" : "Enter any OpenRouter model ID"
        }
        static func aiReady(_ l: AppLanguage) -> String {
            l == .german ? "Bereit" : "Ready"
        }
        static func aiNotConfigured(_ l: AppLanguage) -> String {
            l == .german ? "Nicht konfiguriert" : "Not configured"
        }
```

In `Breadcrumb/Strings.swift`, add to the `Errors` enum (after `notSupportedInVersion`, before the closing `}`):

```swift
        static func networkError(_ l: AppLanguage, message: String) -> String {
            l == .german ? "Netzwerkfehler: \(message)" : "Network error: \(message)"
        }
        static func authenticationFailed(_ l: AppLanguage) -> String {
            l == .german ? "Ungültiger API-Schlüssel" : "Invalid API key"
        }
        static func invalidResponse(_ l: AppLanguage) -> String {
            l == .german ? "Ungültige Antwort vom Modell" : "Invalid response from model"
        }
```

- [ ] **Step 5: Run xcodegen and tests**

Run: `xcodegen generate && xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb 2>&1 | tail -20`
Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add Breadcrumb/Services/AIService.swift Breadcrumb/Strings.swift BreadcrumbTests/StringsTests.swift
git commit -m "feat: add new error cases and localized strings for OpenRouter"
```

---

### Task 6: Refactor AIService — Add extractStatus and Provider Delegation

**Files:**
- Modify: `Breadcrumb/Services/AIService.swift`

- [ ] **Step 1: Add cached availability and provider resolution to AIService**

In `Breadcrumb/Services/AIService.swift`, replace the existing `availability`, `isAvailable` computed properties and add the new `extractStatus` method. The full updated class (keeping existing methods intact):

After the existing `private(set) var isGenerating = false` (line 50), add:

```swift
    private(set) var isAvailable = false

    // MARK: - Provider Resolution

    private var activeBackend: AIBackend {
        let stored = UserDefaults.standard.string(forKey: "ai.provider") ?? "local"
        return AIBackend(rawValue: stored) ?? .local
    }

    private func resolveProvider() -> (any AIProvider)? {
        switch activeBackend {
        case .local:
            #if canImport(FoundationModels)
            if #available(macOS 26, *) {
                if case .available = localAvailability {
                    return LocalAIProvider()
                }
            }
            #endif
            return nil
        case .openRouter:
            guard let apiKey = KeychainHelper.read(key: "openrouter.apiKey"),
                  let model = UserDefaults.standard.string(forKey: "ai.openrouter.model"),
                  !apiKey.isEmpty, !model.isEmpty else { return nil }
            return OpenRouterProvider(apiKey: apiKey, model: model)
        }
    }

    func refreshAvailability() {
        isAvailable = resolveProvider() != nil
    }

    init() {
        refreshAvailability()
    }
```

Replace the existing `var availability: ServiceAvailability` computed property with a private version for local-only use:

```swift
    private var localAvailability: ServiceAvailability {
        #if canImport(FoundationModels)
        if #available(macOS 26, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return .available
            case .unavailable(.deviceNotEligible):
                return .unavailable("deviceNotEligible")
            case .unavailable(.appleIntelligenceNotEnabled):
                return .unavailable("appleIntelligenceNotEnabled")
            case .unavailable(.modelNotReady):
                return .unavailable("modelNotReady")
            case .unavailable:
                return .unavailable("unavailable")
            @unknown default:
                return .unavailable("unavailable")
            }
        } else {
            return .unavailable("requiresMacOS26")
        }
        #else
        return .unavailable("notSupportedInVersion")
        #endif
    }
```

Remove the old computed `var isAvailable: Bool` (it's now a stored property).

Add the new extraction method in a new MARK section:

```swift
    // MARK: - Extraction

    func extractStatus(from text: String, language: AppLanguage) async throws -> ExtractedStatus {
        guard let provider = resolveProvider() else {
            throw AIServiceError.notAvailable(unavailableReason)
        }
        isGenerating = true
        defer { isGenerating = false }
        return try await provider.extractStatus(from: text, language: language)
    }
```

Update `localizedUnavailableReason` to also handle OpenRouter state:

```swift
    func localizedUnavailableReason(for language: AppLanguage) -> String {
        switch activeBackend {
        case .local:
            if case .unavailable(let key) = localAvailability {
                switch key {
                case "deviceNotEligible": return Strings.Errors.deviceNotSupported(language)
                case "appleIntelligenceNotEnabled": return Strings.Errors.enableAppleIntelligence(language)
                case "modelNotReady": return Strings.Errors.modelLoading(language)
                case "requiresMacOS26": return Strings.Errors.requiresMacOS26(language)
                case "notSupportedInVersion": return Strings.Errors.notSupportedInVersion(language)
                default: return Strings.Errors.notAvailable(language)
                }
            }
            return Strings.Errors.notAvailable(language)
        case .openRouter:
            return Strings.Settings.aiNotConfigured(language)
        }
    }
```

Update `unavailableReason` similarly:

```swift
    private var unavailableReason: String {
        switch activeBackend {
        case .local:
            if case .unavailable(let reason) = localAvailability {
                return reason
            }
            return "unavailable"
        case .openRouter:
            return "notConfigured"
        }
    }
```

- [ ] **Step 2: Run xcodegen and build**

Run: `xcodegen generate && xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Debug build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Run all tests**

Run: `xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb 2>&1 | tail -20`
Expected: All tests PASS. (Existing tests should still work since the old methods remain.)

- [ ] **Step 4: Commit**

```bash
git add Breadcrumb/Services/AIService.swift
git commit -m "feat: add provider delegation and extractStatus to AIService"
```

---

### Task 7: Update AIExtractButton to Use extractStatus

**Files:**
- Modify: `Breadcrumb/Views/AIExtractButton.swift`

- [ ] **Step 1: Rewrite AIExtractButton**

Replace the entire contents of `Breadcrumb/Views/AIExtractButton.swift` with:

```swift
import SwiftUI

struct AIExtractButton: View {
    @Environment(AIService.self) private var aiService
    @Environment(LanguageManager.self) private var languageManager

    @Binding var freeText: String
    @Binding var lastAction: String
    @Binding var nextStep: String
    @Binding var openQuestions: String
    @Binding var showOptionalFields: Bool

    @State private var errorMessage: String?
    @State private var extractionTask: Task<Void, Never>?
    @State private var errorDismissTask: Task<Void, Never>?

    var body: some View {
        extractionContent
            .onDisappear {
                extractionTask?.cancel()
                errorDismissTask?.cancel()
            }
    }

    @ViewBuilder
    private var extractionContent: some View {
        let l = languageManager.language
        if aiService.isAvailable && !freeText.trimmingCharacters(in: .whitespaces).isEmpty {
            VStack(spacing: 4) {
                Button {
                    extractionTask = Task { await extract() }
                } label: {
                    if aiService.isGenerating {
                        HStack(spacing: 6) {
                            ProgressView()
                                .controlSize(.small)
                            Text(Strings.AIExtraction.extracting(l))
                                .font(.caption)
                        }
                    } else {
                        Label(Strings.AIExtraction.buttonLabel(l), systemImage: "wand.and.stars")
                            .font(.caption)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(aiService.isGenerating)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private func extract() async {
        errorMessage = nil
        let language = languageManager.language

        do {
            let result = try await aiService.extractStatus(from: freeText, language: language)
            applyResult(lastAction: result.lastAction, nextStep: result.nextStep, openQuestions: result.openQuestions)
            showOptionalFields = true
        } catch is CancellationError {
            // Normal lifecycle event — ignore.
        } catch {
            errorMessage = error.localizedDescription
            errorDismissTask = Task {
                try? await Task.sleep(for: .seconds(4))
                errorMessage = nil
            }
        }
    }

    private func applyResult(lastAction: String, nextStep: String, openQuestions: String) {
        if !lastAction.isEmpty {
            self.lastAction = cleanFiller(lastAction)
        }
        if !nextStep.isEmpty {
            self.nextStep = cleanFiller(nextStep)
        }
        if !openQuestions.isEmpty {
            self.openQuestions = cleanFiller(openQuestions)
        }
    }

    /// The AI model sometimes generates filler text like "Leer" or "Nichts unklar"
    /// instead of an actual empty string. Strip these to prevent garbage in the UI.
    private func cleanFiller(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ".-–—"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let lowered = trimmed.lowercased()

        // Exact matches
        let fillerPhrases: Set<String> = [
            // === GENERAL (applies to any field) ===
            "leer", "leere", "leerer string", "leeres feld", "leerfeld",
            "nichts", "nein", "klar", "n/a", "na",
            "entfaellt", "entfällt",
            "keine", "keins", "keines",
            "nicht vorhanden", "nicht bekannt", "nicht zutreffend",
            "nicht angegeben", "nicht verfuegbar", "nicht verfügbar",
            "nicht relevant", "nicht noetig", "nicht nötig",
            "keine angaben", "keine angabe",
            "null", "leer lassen", "feld leer",
            "hier nichts", "hier leer", "hier keine angabe",
            "empty", "empty string", "empty field",
            "none", "nothing", "no", "clear",
            "not applicable", "not available", "not specified", "not relevant",
            "ok", "okay", "alles gut", "all good",
            "...", "…", "-", "--", "---", "–", "—",
            "[]", "()", "\"\"", "''",

            // === OPEN QUESTIONS / UNCERTAINTIES ===
            "nichts unklar", "nichts offen", "alles klar", "alles soweit klar",
            "soweit alles klar", "alles verstanden", "passt", "passt soweit",
            "keine fragen", "keine offenen fragen", "keine fragen offen",
            "keine offenen fragen vorhanden", "keine fragen vorhanden",
            "keine unsicherheiten", "keine unsicherheit",
            "keine offenen unsicherheiten", "keine unsicherheiten vorhanden",
            "keine aktuellen fragen", "keine aktuellen unsicherheiten",
            "keine offenen punkte", "keine offenen themen",
            "keine weiteren fragen", "keine anmerkungen", "keine probleme",
            "keine bedenken", "keine zweifel", "keine unklarheiten",
            "keine unklarheit", "keine offene frage",
            "keine unklaren punkte",
            "es gibt keine offenen fragen", "es gibt keine unsicherheiten",
            "es gibt nichts unklares", "es gibt keine unklarheiten",
            "keine offenen fragen oder unsicherheiten",
            "momentan keine fragen", "aktuell keine fragen",
            "aktuell keine unsicherheiten", "derzeit keine fragen",
            "derzeit keine unsicherheiten", "zur zeit keine fragen",
            "bisher keine fragen", "im moment keine fragen",
            "soweit keine fragen", "keine fragen im moment",
            "keine fragen aktuell", "keine fragen derzeit",
            "momentan keine unsicherheiten", "bisher keine unsicherheiten",
            "im moment keine unsicherheiten",
            "es sind keine fragen offen", "es bestehen keine unsicherheiten",
            "es bestehen keine fragen", "es bestehen keine offenen fragen",
            "hierzu keine fragen", "dazu keine fragen",
            "keine offenen fragen identifiziert",
            "keine offenen fragen festgestellt",
            "alles wurde geklaert", "alles geklaert", "alles geklärt",
            "nothing unclear", "nothing open", "all clear", "all understood",
            "everything is clear", "everything clear",
            "no questions", "no open questions", "no questions open",
            "no open questions at this time", "no open questions right now",
            "no uncertainties", "no uncertainty",
            "no open issues", "no open items", "no open topics",
            "no further questions", "no comments", "no problems", "no concerns",
            "no doubts", "no unclear points", "no ambiguity",
            "no open questions or uncertainties",
            "no questions identified", "no open questions identified",
            "no open questions identified at this time",
            "there are no open questions", "there are no uncertainties",
            "nothing is unclear", "nothing remains unclear",
            "currently no questions", "currently no uncertainties",
            "no questions at the moment", "no questions currently",
            "no questions right now", "no questions at this time",
            "no uncertainties at the moment", "no uncertainties right now",
            "everything has been clarified", "all clarified",
            "no issues identified", "no concerns identified",

            // === LAST ACTION / COMPLETED TASKS ===
            "nichts erledigt", "nichts abgeschlossen", "nichts gemacht",
            "nichts getan", "nichts passiert", "nichts fertig",
            "noch nichts", "noch nichts erledigt", "noch nichts gemacht",
            "noch nichts abgeschlossen", "noch nichts passiert",
            "noch nichts getan", "noch nichts fertig",
            "bisher nichts erledigt", "bisher nichts gemacht",
            "bisher nichts abgeschlossen", "bisher nichts passiert",
            "keine erledigten aufgaben", "keine abgeschlossenen aufgaben",
            "keine vorherigen aktionen", "keine vorherige aktion",
            "keine bisherigen aktionen", "keine bisherige aktion",
            "keine letzten aktionen", "keine letzte aktion",
            "kein letzter schritt", "keine letzten schritte",
            "keine erledigten schritte", "keine erledigten punkte",
            "keine aktion", "keine aktionen",
            "keine fortschritte", "kein fortschritt",
            "noch nicht begonnen", "nicht begonnen", "nicht gestartet",
            "noch nicht angefangen", "nicht angefangen",
            "es wurde nichts erledigt", "es wurde nichts gemacht",
            "es wurde nichts abgeschlossen",
            "bisher wurde nichts erledigt", "bisher wurde nichts gemacht",
            "hierzu nichts erledigt", "hierzu nichts abgeschlossen",
            "bislang nichts erledigt", "bislang nichts passiert",
            "keine aufgaben erledigt", "keine aufgaben abgeschlossen",
            "keine schritte abgeschlossen", "keine schritte erledigt",
            "keine arbeit erledigt", "keine arbeit gemacht",
            "es gibt nichts erledigtes", "es gibt keine erledigten aufgaben",
            "aktuell nichts erledigt", "derzeit nichts erledigt",
            "momentan nichts erledigt",
            "nothing done", "nothing completed", "nothing finished",
            "nothing accomplished", "nothing happened",
            "not started", "not yet started", "not begun", "not yet begun",
            "no completed tasks", "no tasks completed",
            "no previous actions", "no previous action",
            "no last action", "no last actions",
            "no completed steps", "no steps completed",
            "no progress", "no progress made", "no progress yet",
            "no action taken", "no actions taken",
            "no actions", "no action",
            "nothing happened yet", "nothing has happened",
            "nothing has been done", "nothing was completed",
            "nothing was done", "nothing has been completed",
            "no work done", "no work completed",
            "nothing has been accomplished",
            "haven't started", "hasn't started",
            "not yet completed", "nothing yet",
            "currently nothing done", "currently nothing completed",
            "no tasks done", "no items completed",

            // === NEXT STEPS / PLANNED TASKS ===
            "nichts geplant", "nichts weiter", "nichts weiteres",
            "nichts vorgesehen", "nichts anstehend",
            "keine naechsten schritte", "keine nächsten schritte",
            "kein naechster schritt", "kein nächster schritt",
            "keine weiteren schritte", "keine weiteren aufgaben",
            "keine geplanten schritte", "keine geplanten aufgaben",
            "keine planung", "keine geplanten aktionen",
            "keine aufgaben", "keine schritte",
            "keine weiteren aktionen", "keine weiteren punkte",
            "keine naechste aktion", "keine nächste aktion",
            "keine todos", "keine to-dos",
            "keine offenen aufgaben",
            "momentan nichts geplant", "aktuell nichts geplant",
            "derzeit nichts geplant", "bisher nichts geplant",
            "zur zeit nichts geplant", "im moment nichts geplant",
            "es gibt keine naechsten schritte",
            "es gibt keine nächsten schritte",
            "es gibt keine weiteren schritte",
            "es gibt keine geplanten aufgaben",
            "es sind keine schritte geplant",
            "es ist nichts geplant", "es ist nichts weiter geplant",
            "wird noch festgelegt", "noch festzulegen",
            "noch zu bestimmen", "noch offen", "steht noch aus",
            "noch unklar", "muss noch geklaert werden",
            "muss noch geklärt werden", "muss noch entschieden werden",
            "keine naechsten aufgaben", "keine nächsten aufgaben",
            "hierzu nichts geplant", "dazu nichts geplant",
            "soweit nichts geplant", "bislang nichts geplant",
            "nothing planned", "nothing further", "nothing next",
            "nothing scheduled", "nothing upcoming",
            "no next steps", "no next step",
            "no further steps", "no further actions", "no further tasks",
            "no planned tasks", "no planned steps", "no planned actions",
            "no tasks", "no steps", "no actions planned",
            "no upcoming tasks", "no upcoming steps",
            "no todos", "no to-dos",
            "nothing to do", "nothing to do next",
            "no action needed", "no actions needed",
            "no action required", "no actions required",
            "currently nothing planned", "nothing currently planned",
            "no tasks planned", "no steps planned",
            "there are no next steps", "there are no further steps",
            "there are no planned tasks",
            "no next steps identified", "no further steps identified",
            "to be determined", "tbd", "to be decided",
            "still open", "still pending", "pending",
            "not yet determined", "not yet decided",
            "no next steps at this time",
            "no further actions needed", "no further actions required",
        ]

        if fillerPhrases.contains(lowered) {
            return ""
        }

        // Prefix patterns
        let fillerPrefixes = [
            "keine offenen fragen", "keine weiteren fragen", "keine aktuellen fragen",
            "keine offenen unsicherheit", "keine weiteren unsicherheit",
            "keine unklaren",
            "es gibt keine offenen", "es gibt keine weiteren",
            "es bestehen keine", "hierzu keine",
            "no open question", "no further question", "no uncertaint",
            "there are no open", "there are no further",
            "nichts erledigt", "nichts abgeschlossen", "noch nichts",
            "bisher nichts", "bislang nichts",
            "keine erledigten", "keine abgeschlossenen", "keine bisherigen",
            "keine vorherigen", "keine letzten",
            "es wurde nichts", "es gibt nichts erledigt",
            "nothing done", "nothing completed", "nothing finished",
            "no completed", "no previous", "no progress",
            "nothing has been", "nothing was",
            "nichts geplant", "nichts weiter",
            "keine naechsten", "keine nächsten", "keine weiteren schritte",
            "keine geplanten", "keine weiteren aufgaben",
            "es gibt keine naechsten", "es gibt keine nächsten",
            "es gibt keine weiteren", "es gibt keine geplanten",
            "es ist nichts", "es sind keine",
            "nothing planned", "nothing further",
            "no next step", "no further step", "no planned",
            "no upcoming", "there are no next", "there are no planned",
        ]
        for prefix in fillerPrefixes {
            if lowered.hasPrefix(prefix) {
                return ""
            }
        }

        return trimmed
    }
}
```

- [ ] **Step 2: Run xcodegen and build**

Run: `xcodegen generate && xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Debug build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED. The button now works with both backends and has no FoundationModels compile-time gate.

- [ ] **Step 3: Run all tests**

Run: `xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb 2>&1 | tail -20`
Expected: All tests PASS.

- [ ] **Step 4: Commit**

```bash
git add Breadcrumb/Views/AIExtractButton.swift
git commit -m "refactor: update AIExtractButton to use provider-agnostic extractStatus"
```

---

### Task 8: OpenRouterSettingsSection View

**Files:**
- Create: `Breadcrumb/Views/Settings/OpenRouterSettingsSection.swift`

- [ ] **Step 1: Create the Settings directory if needed and write the view**

Check if the Settings subdirectory exists. If not, the file creation will handle it. Note: `SettingsView.swift` is currently at `Breadcrumb/Views/SettingsView.swift` (not in a subdirectory).

Create `Breadcrumb/Views/Settings/OpenRouterSettingsSection.swift`:

```swift
import SwiftUI

struct OpenRouterSettingsSection: View {
    @Environment(AIService.self) private var aiService
    @Environment(LanguageManager.self) private var languageManager

    @State private var apiKey = ""
    @State private var model = UserDefaults.standard.string(forKey: "ai.openrouter.model") ?? ""

    var body: some View {
        let l = languageManager.language

        Section(Strings.Settings.aiProviderOpenRouter(l)) {
            SecureField(Strings.Settings.apiKeyPlaceholder(l), text: $apiKey)
                .onChange(of: apiKey) {
                    KeychainHelper.save(key: "openrouter.apiKey", value: apiKey)
                    aiService.refreshAvailability()
                }

            Text(Strings.Settings.apiKeyHelp(l))
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField(Strings.Settings.modelPlaceholder(l), text: $model)
                .onChange(of: model) {
                    UserDefaults.standard.set(model, forKey: "ai.openrouter.model")
                    aiService.refreshAvailability()
                }

            Text(Strings.Settings.modelHelp(l))
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Circle()
                    .fill(aiService.isAvailable ? .green : .secondary)
                    .frame(width: 8, height: 8)
                Text(aiService.isAvailable ? Strings.Settings.aiReady(l) : Strings.Settings.aiNotConfigured(l))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            apiKey = KeychainHelper.read(key: "openrouter.apiKey") ?? ""
            model = UserDefaults.standard.string(forKey: "ai.openrouter.model") ?? ""
        }
    }
}
```

- [ ] **Step 2: Run xcodegen and build**

Run: `xcodegen generate && xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Debug build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add Breadcrumb/Views/Settings/OpenRouterSettingsSection.swift
git commit -m "feat: add OpenRouterSettingsSection view"
```

---

### Task 9: Add AI Provider Section to SettingsView

**Files:**
- Modify: `Breadcrumb/Views/SettingsView.swift` (lines 4-96)

- [ ] **Step 1: Add the provider picker and OpenRouter section**

In `Breadcrumb/Views/SettingsView.swift`, add a new `@AppStorage` property after line 17 (`autoOpenPopover`):

```swift
    @AppStorage("ai.provider") private var aiProvider = AIBackend.local.rawValue
```

Then add the AI Provider section in the Form, after the Language section (after line 60) and before the General section:

```swift
                Section(Strings.Settings.aiProvider(l)) {
                    Picker(Strings.Settings.aiProvider(l), selection: $aiProvider) {
                        Text(Strings.Settings.aiProviderLocal(l)).tag(AIBackend.local.rawValue)
                        Text(Strings.Settings.aiProviderOpenRouter(l)).tag(AIBackend.openRouter.rawValue)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .onChange(of: aiProvider) {
                        aiService.refreshAvailability()
                    }
                }

                if aiProvider == AIBackend.openRouter.rawValue {
                    OpenRouterSettingsSection()
                }
```

Also add `AIService` environment at the top of the struct (after line 5):

```swift
    @Environment(AIService.self) private var aiService
```

- [ ] **Step 2: Run xcodegen and build**

Run: `xcodegen generate && xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Debug build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Run all tests**

Run: `xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb 2>&1 | tail -20`
Expected: All tests PASS.

- [ ] **Step 4: Commit**

```bash
git add Breadcrumb/Views/SettingsView.swift
git commit -m "feat: add AI provider picker to SettingsView"
```

---

### Task 10: Final Integration Test and Cleanup

**Files:**
- All files from previous tasks

- [ ] **Step 1: Run full test suite**

Run: `xcodegen generate && xcodebuild test -project Breadcrumb.xcodeproj -scheme Breadcrumb 2>&1 | tail -30`
Expected: ALL tests PASS.

- [ ] **Step 2: Run release build**

Run: `xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Release build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED with no warnings from our code.

- [ ] **Step 3: Verify the old AI extraction path still works**

Check that `LocalAIProvider` is reachable by verifying the compile:

Run: `xcodebuild -project Breadcrumb.xcodeproj -scheme Breadcrumb -configuration Debug build 2>&1 | grep -i error | head -5`
Expected: No errors. (Full integration testing of the local path requires macOS 26 + Apple Intelligence on a real device.)

- [ ] **Step 4: Commit any final fixups if needed**

If any issues were found and fixed in steps 1-3:

```bash
git add -A
git commit -m "fix: address integration issues from final review"
```

- [ ] **Step 5: Tag completion**

```bash
git log --oneline -10
```

Verify the commit history shows the clean progression of tasks.
