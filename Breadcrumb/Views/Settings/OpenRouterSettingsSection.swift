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
    }
}
