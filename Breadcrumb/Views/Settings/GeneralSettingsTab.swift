import SwiftUI
import ServiceManagement

struct GeneralSettingsTab: View {
    @Environment(LanguageManager.self) private var languageManager
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @AppStorage("feature.dictationEnabled") private var dictationEnabled = false
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false

    var body: some View {
        @Bindable var languageManager = languageManager
        let l = languageManager.language

        Form {
            Section {
                Picker(Strings.Settings.language(l), selection: $languageManager.language) {
                    ForEach(AppLanguage.allCases, id: \.self) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                Toggle(Strings.Settings.launchAtLogin(l), isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
                Toggle(isOn: $dictationEnabled) {
                    HStack(spacing: 6) {
                        Text(Strings.Settings.dictation(l))
                        InfoButton(text: Strings.Settings.dictationCaption(l))
                    }
                }
            }

            Section {
                HStack {
                    Button(Strings.Settings.showIntroAgain(l)) {
                        hasSeenWelcome = false
                    }
                    .disabled(!hasSeenWelcome)
                    InfoButton(text: Strings.Settings.showIntroAgainCaption(l))
                    Spacer()
                    if !hasSeenWelcome {
                        Label(Strings.Settings.introResetDone(l), systemImage: "checkmark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 280)
    }
}
