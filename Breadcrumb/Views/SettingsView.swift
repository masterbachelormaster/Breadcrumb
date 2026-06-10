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
    @AppStorage("pomodoro.showBannerNotification") private var showBannerNotification = true
    @AppStorage("pomodoro.focusMateEndEarlyMinutes") private var focusMateEndEarlyMinutes = 0
    @AppStorage("pomodoro.focusMateEndEarlySeconds") private var focusMateEndEarlySeconds = 0
    @AppStorage("pomodoro.sessionEndPresentation") private var sessionEndPresentation = SessionEndPresentation.window.rawValue
    @AppStorage("ai.provider") private var aiProvider = AIBackend.local.rawValue
    @AppStorage("feature.dictationEnabled") private var dictationEnabled = false
    @AppStorage("feature.focusMateEnabled") private var focusMateEnabled = false

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
                    .fixedSize()
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(Strings.General.settings(l))
                        .font(.headline)
                        .lineLimit(1)
                        .layoutPriority(1)

                    Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            // Content
            Form {
                languageSection
                generalSection
                pomodoroSection
                sessionEndSection
                focusMateSection
                notificationsSection
                aiSection
                if aiProvider == AIBackend.openRouter.rawValue {
                    OpenRouterSettingsSection()
                }
            }
            .formStyle(.grouped)
        }
    }

    // breaks happen only BETWEEN sessions (none after the last)
    private var totalMinutes: Int {
        let breakCount = max(0, totalSessions - 1)
        let longBreakCount: Int
        let shortBreakCount: Int
        if totalSessions >= 3 {
            longBreakCount = breakCount / max(1, sessionsBeforeLongBreak)
            shortBreakCount = breakCount - longBreakCount
        } else if totalSessions == 2 {
            longBreakCount = 0
            shortBreakCount = 1
        } else {
            longBreakCount = 0
            shortBreakCount = 0
        }
        return totalSessions * workMinutes
            + shortBreakCount * shortBreakMinutes
            + longBreakCount * longBreakMinutes
    }

    @ViewBuilder
    private var languageSection: some View {
        @Bindable var languageManager = languageManager
        let l = languageManager.language
        Section(Strings.Settings.language(l)) {
            Picker(Strings.Settings.language(l), selection: $languageManager.language) {
                ForEach(AppLanguage.allCases, id: \.self) { lang in
                    Text(lang.displayName).tag(lang)
                }
            }
            .labelsHidden()
        }
    }

    @ViewBuilder
    private var generalSection: some View {
        let l = languageManager.language
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
            Toggle(isOn: $dictationEnabled) {
                Text(Strings.Settings.dictation(l))
                Text(Strings.Settings.dictationCaption(l))
            }
        }
    }

    @ViewBuilder
    private var pomodoroSection: some View {
        let l = languageManager.language
        Section {
            Stepper(Strings.Pomodoro.totalSessionsLabel(l, count: totalSessions), value: $totalSessions, in: 1...8)
            Stepper(Strings.Pomodoro.focusTimeLabel(l, minutes: workMinutes), value: $workMinutes, in: 5...60)
            if hasBreaks {
                Stepper(Strings.Pomodoro.shortBreakLabel(l, minutes: shortBreakMinutes), value: $shortBreakMinutes, in: 1...15)
                if hasLongBreak {
                    Stepper(Strings.Pomodoro.sessionsBeforeLongBreak(l, count: sessionsBeforeLongBreak), value: $sessionsBeforeLongBreak, in: 2...(totalSessions - 1))
                    Stepper(Strings.Pomodoro.longBreakLabel(l, minutes: longBreakMinutes), value: $longBreakMinutes, in: 5...30)
                }
            }
        } header: {
            Text(Strings.Pomodoro.pomodoro(l))
        } footer: {
            Text(Strings.Pomodoro.cycleSummary(l, sessions: totalSessions, workMinutes: workMinutes, totalMinutes: totalMinutes))
        }
        .animation(.default, value: totalSessions)
        .onChange(of: totalSessions) {
            if sessionsBeforeLongBreak >= totalSessions {
                sessionsBeforeLongBreak = max(2, totalSessions - 1)
            }
        }
    }

    @ViewBuilder
    private var sessionEndSection: some View {
        let l = languageManager.language
        Section {
            Picker(Strings.Pomodoro.sessionEndPrompt(l), selection: $sessionEndPresentation) {
                Text(Strings.Pomodoro.sessionEndPromptWindow(l)).tag(SessionEndPresentation.window.rawValue)
                Text(Strings.Pomodoro.sessionEndPromptMenuBar(l)).tag(SessionEndPresentation.menuBar.rawValue)
            }
            .pickerStyle(.segmented)
        } header: {
            Text(Strings.Settings.sessionEndSection(l))
        } footer: {
            Text(Strings.Pomodoro.sessionEndPromptCaption(l))
        }
    }

    @ViewBuilder
    private var focusMateSection: some View {
        let l = languageManager.language
        Section {
            Toggle(isOn: $focusMateEnabled) {
                Text(Strings.Settings.focusMateUser(l))
                Text(Strings.Settings.focusMateUserCaption(l))
            }
            if focusMateEnabled {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Strings.Pomodoro.focusMateEndEarlyHeader(l))
                    Text(Strings.Pomodoro.focusMateBufferCaption(l))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Stepper(
                    Strings.Pomodoro.focusMateBufferMinutes(l, minutes: focusMateEndEarlyMinutes),
                    value: $focusMateEndEarlyMinutes,
                    in: 0...10
                )
                Stepper(
                    Strings.Pomodoro.focusMateBufferSeconds(l, seconds: focusMateEndEarlySeconds),
                    value: $focusMateEndEarlySeconds,
                    in: 0...50,
                    step: 10
                )
            }
            Link(Strings.Settings.focusMateLink(l), destination: URL(string: "https://www.focusmate.com")!)
                .font(.caption)
        } header: {
            Text(Strings.Pomodoro.focusMateMode(l))
        } footer: {
            Text(Strings.Pomodoro.focusMateSectionFooter(l))
        }
        .animation(.default, value: focusMateEnabled)
    }

    @ViewBuilder
    private var notificationsSection: some View {
        let l = languageManager.language
        Section(Strings.Settings.notifications(l)) {
            SoundPicker(label: Strings.Settings.soundWorkDone(l), selection: $soundWorkDone)
            SoundPicker(label: Strings.Settings.soundBreakDone(l), selection: $soundBreakDone)
            Toggle(isOn: $showBannerNotification) {
                Text(Strings.Settings.showBannerNotification(l))
                Text(Strings.Settings.showBannerCaption(l))
            }
        }
    }

    @ViewBuilder
    private var aiSection: some View {
        let l = languageManager.language
        Section(Strings.Settings.aiSection(l)) {
            Text(Strings.Settings.aiIntro(l))
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker(Strings.Settings.aiProvider(l), selection: $aiProvider) {
                Text(Strings.Settings.aiProviderLocal(l)).tag(AIBackend.local.rawValue)
                Text(Strings.Settings.aiProviderOpenRouter(l)).tag(AIBackend.openRouter.rawValue)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .onChange(of: aiProvider) {
                aiService.refreshAvailability()
            }

            Text(aiProvider == AIBackend.openRouter.rawValue
                ? Strings.Settings.aiProviderOpenRouterCaption(l)
                : Strings.Settings.aiProviderLocalCaption(l))
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
    }
}
