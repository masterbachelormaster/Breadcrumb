import SwiftUI

struct OpenRouterSettingsSection: View {
    @Environment(AIService.self) private var aiService
    @Environment(LanguageManager.self) private var languageManager

    @State private var apiKey = ""
    @State private var model = ""

    var body: some View {
        let l = languageManager.language

        Section(Strings.Settings.aiProviderOpenRouter(l)) {
            SecureField(
                Strings.Settings.apiKey(l),
                text: $apiKey,
                prompt: Text(Strings.Settings.apiKeyPlaceholder(l))
            )
            .onChange(of: apiKey) {
                KeychainHelper.save(key: "openrouter.apiKey", value: apiKey)
            }
            .onSubmit { aiService.refreshAvailability() }

            Text(Strings.Settings.apiKeyHelp(l))
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField(
                Strings.Settings.model(l),
                text: $model,
                prompt: Text(Strings.Settings.modelPlaceholder(l))
            )
            .onChange(of: model) {
                UserDefaults.standard.set(model, forKey: "ai.openrouter.model")
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
            apiKey = KeychainHelper.read(key: "openrouter.apiKey") ?? ""
            model = UserDefaults.standard.string(forKey: "ai.openrouter.model") ?? ""
        }
        .onDisappear {
            aiService.refreshAvailability()
        }
    }
}
