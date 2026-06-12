import SwiftUI

struct AISettingsTab: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(AIService.self) private var aiService

    @AppStorage("ai.provider") private var aiProvider = AIBackend.local.rawValue

    private var isOpenRouter: Bool { aiProvider == AIBackend.openRouter.rawValue }

    var body: some View {
        let l = languageManager.language

        Form {
            Section {
                // LabeledContent (not a Picker label) so the InfoButton stays clickable
                LabeledContent {
                    Picker("", selection: $aiProvider) {
                        Text(Strings.Settings.aiProviderLocal(l)).tag(AIBackend.local.rawValue)
                        Text(Strings.Settings.aiProviderOpenRouter(l)).tag(AIBackend.openRouter.rawValue)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .onChange(of: aiProvider) {
                        aiService.refreshAvailability()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(Strings.Settings.aiProvider(l))
                        InfoButton(text: Strings.Settings.aiIntro(l))
                    }
                }

                LabeledContent {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(aiService.isAvailable ? Color.green : Color.secondary)
                            .frame(width: 8, height: 8)
                        Text(aiService.isAvailable
                            ? Strings.Settings.aiReady(l)
                            : Strings.Settings.aiNotConfigured(l))
                            .foregroundStyle(.secondary)
                    }
                } label: {
                    Text(Strings.Settings.aiStatus(l))
                }
            } footer: {
                Text(isOpenRouter
                    ? Strings.Settings.aiProviderOpenRouterCaption(l)
                    : Strings.Settings.aiProviderLocalCaption(l))
            }

            if isOpenRouter {
                OpenRouterSettingsSection()
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: isOpenRouter ? 500 : 240)
        .animation(.default, value: isOpenRouter)
    }
}
