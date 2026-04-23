import SwiftUI

struct OpenRouterSettingsSection: View {
    @Environment(AIService.self) private var aiService
    @Environment(LanguageManager.self) private var languageManager

    @State private var apiKey = ""
    @State private var lastSavedAPIKey = ""
    @State private var apiKeySaveFailed = false
    @State private var model = ""

    var body: some View {
        let l = languageManager.language

        Section(Strings.Settings.aiProviderOpenRouter(l)) {
            SecureField(
                Strings.Settings.apiKey(l),
                text: $apiKey,
                prompt: Text(Strings.Settings.apiKeyPlaceholder(l))
            )
            .onChange(of: apiKey) { _, _ in
                apiKeySaveFailed = false
            }
            .onSubmit { saveAPIKeyIfNeeded() }

            Text(Strings.Settings.apiKeyHelp(l))
                .font(.caption)
                .foregroundStyle(.secondary)

            if apiKeySaveFailed {
                Text(Strings.Settings.apiKeySaveFailed(l))
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            TextField(
                Strings.Settings.model(l),
                text: $model,
                prompt: Text(Strings.Settings.modelPlaceholder(l))
            )
            .onChange(of: model) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "ai.openrouter.model")
                aiService.refreshAvailability()
            }
            .onSubmit { aiService.refreshAvailability() }

            Text(Strings.Settings.modelHelp(l))
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Circle()
                    .fill(aiService.isAvailable ? Color.green : Color.secondary)
                    .frame(width: 8, height: 8)
                Text(aiService.isAvailable ? Strings.Settings.aiReady(l) : Strings.Settings.aiNotConfigured(l))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            let storedAPIKey = KeychainHelper.read(key: "openrouter.apiKey") ?? ""
            apiKey = storedAPIKey
            lastSavedAPIKey = storedAPIKey
            apiKeySaveFailed = false
            model = UserDefaults.standard.string(forKey: "ai.openrouter.model") ?? ""
        }
        .onDisappear {
            saveAPIKeyIfNeeded()
        }
    }

    @discardableResult
    private func saveAPIKeyIfNeeded() -> Bool {
        guard apiKey != lastSavedAPIKey else { return true }

        let result = KeychainHelper.saveResult(key: "openrouter.apiKey", value: apiKey)
        if result.succeeded {
            lastSavedAPIKey = apiKey
            apiKeySaveFailed = false
            aiService.refreshAvailability()
            return true
        }

        apiKeySaveFailed = true
        return false
    }
}
