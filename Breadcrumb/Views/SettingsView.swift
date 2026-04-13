import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(AIService.self) private var aiService
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    @AppStorage("pomodoro.workMinutes") private var workMinutes = 25
    @AppStorage("pomodoro.shortBreakMinutes") private var shortBreakMinutes = 5
    @AppStorage("pomodoro.longBreakMinutes") private var longBreakMinutes = 15
    @AppStorage("pomodoro.sessionsBeforeLongBreak") private var sessionsBeforeLongBreak = 4
    @AppStorage("pomodoro.totalSessions") private var totalSessions = 4
    @AppStorage("pomodoro.sound.workDone") private var soundWorkDone = "Glass"
    @AppStorage("pomodoro.sound.breakDone") private var soundBreakDone = "Ping"
    @AppStorage("pomodoro.sound.overtime") private var soundOvertime = "Tink"
    @AppStorage("pomodoro.showBannerNotification") private var showBannerNotification = true
    @AppStorage("pomodoro.autoOpenPopover") private var autoOpenPopover = true
    @AppStorage("ai.provider") private var aiProvider = AIBackend.local.rawValue
    @AppStorage("feature.bulletListsEnabled") private var bulletListsEnabled = true

    var onBack: (() -> Void)? = nil

    private var hasBreaks: Bool { totalSessions > 1 }
    private var hasLongBreak: Bool { totalSessions >= 3 }

    var body: some View {
        @Bindable var languageManager = languageManager
        let l = languageManager.language

        VStack(spacing: 0) {
            // Header
            if let onBack {
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text(Strings.General.back(l))
                        }
                        .font(.body)
                    }
                    .buttonStyle(ToolbarButtonStyle())

                    Spacer()

                    Text(Strings.General.settings(l))
                        .font(.headline)

                    Spacer()

                    Color.clear.frame(width: 60, height: 1)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            // Content
            Form {
                Section(Strings.Settings.language(l)) {
                    Picker(Strings.Settings.language(l), selection: $languageManager.language) {
                        ForEach(AppLanguage.allCases, id: \.self) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .labelsHidden()
                }

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

                Section(Strings.Settings.general(l)) {
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
                    Toggle(Strings.Settings.bulletLists(l), isOn: $bulletListsEnabled)
                }

                Section(Strings.Pomodoro.pomodoro(l)) {
                    Stepper(Strings.Pomodoro.totalSessionsLabel(l, count: totalSessions), value: $totalSessions, in: 1...8)
                    Stepper(Strings.Pomodoro.focusTimeLabel(l, minutes: workMinutes), value: $workMinutes, in: 5...60)
                    if hasBreaks {
                        Stepper(Strings.Pomodoro.shortBreakLabel(l, minutes: shortBreakMinutes), value: $shortBreakMinutes, in: 1...15)
                        if hasLongBreak {
                            Stepper(Strings.Pomodoro.sessionsBeforeLongBreak(l, count: sessionsBeforeLongBreak), value: $sessionsBeforeLongBreak, in: 2...(totalSessions - 1))
                            Stepper(Strings.Pomodoro.longBreakLabel(l, minutes: longBreakMinutes), value: $longBreakMinutes, in: 5...30)
                        }
                    }
                }
                .animation(.default, value: totalSessions)
                .onChange(of: totalSessions) {
                    if sessionsBeforeLongBreak >= totalSessions {
                        sessionsBeforeLongBreak = max(2, totalSessions - 1)
                    }
                }

                Section(Strings.Settings.notifications(l)) {
                    SoundPicker(label: Strings.Settings.soundWorkDone(l), selection: $soundWorkDone)
                    SoundPicker(label: Strings.Settings.soundBreakDone(l), selection: $soundBreakDone)
                    SoundPicker(label: Strings.Settings.soundOvertime(l), selection: $soundOvertime)
                    Toggle(Strings.Settings.showBannerNotification(l), isOn: $showBannerNotification)
                    Toggle(Strings.Settings.autoOpenPopover(l), isOn: $autoOpenPopover)
                }
            }
            .formStyle(.grouped)
        }
    }
}
