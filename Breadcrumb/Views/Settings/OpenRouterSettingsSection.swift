import SwiftUI

struct OpenRouterSettingsSection: View {
    @Environment(AIService.self) private var aiService
    @Environment(LanguageManager.self) private var languageManager

    @State private var apiKey = ""
    @State private var lastSavedAPIKey = ""
    @State private var apiKeySaveFailed = false
    @State private var model = ""
    @State private var customPrompt = ""
    @State private var isPromptExpanded = false

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

            DisclosureGroup(Strings.Settings.systemPrompt(l), isExpanded: $isPromptExpanded) {
                VStack(alignment: .leading, spacing: 8) {
                    TextEditor(text: $customPrompt)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 100, maxHeight: 200)
                        .scrollContentBackground(.hidden)
                        .padding(4)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .onChange(of: customPrompt) { _, newValue in
                            UserDefaults.standard.set(newValue, forKey: "ai.openrouter.customSystemPrompt")
                        }

                    Text(Strings.Settings.systemPromptHelp(l))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if customPrompt != defaultPrompt(for: l) {
                        Button(Strings.Settings.resetToDefault(l)) {
                            customPrompt = defaultPrompt(for: l)
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.top, 4)
            }
        }
        .onAppear {
            let storedAPIKey = KeychainHelper.read(key: "openrouter.apiKey") ?? ""
            apiKey = storedAPIKey
            lastSavedAPIKey = storedAPIKey
            apiKeySaveFailed = false
            model = UserDefaults.standard.string(forKey: "ai.openrouter.model") ?? ""
            let stored = UserDefaults.standard.string(forKey: "ai.openrouter.customSystemPrompt")
            customPrompt = (stored?.isEmpty ?? true)
                ? defaultPrompt(for: languageManager.language)
                : stored!
        }
        .onDisappear {
            saveAPIKeyIfNeeded()
        }
    }

    private func defaultPrompt(for language: AppLanguage) -> String {
        Strings.AIExtraction.instructions(language)
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
