import SwiftUI

struct NotificationSettingsTab: View {
    @Environment(LanguageManager.self) private var languageManager

    @AppStorage("pomodoro.sound.workDone") private var soundWorkDone = "Glass"
    @AppStorage("pomodoro.sound.breakDone") private var soundBreakDone = "Ping"
    @AppStorage("pomodoro.showBannerNotification") private var showBannerNotification = true

    var body: some View {
        let l = languageManager.language

        Form {
            Section(Strings.Settings.soundsGroup(l)) {
                SoundPicker(label: Strings.Settings.soundWorkDone(l), selection: $soundWorkDone)
                SoundPicker(label: Strings.Settings.soundBreakDone(l), selection: $soundBreakDone)
            }

            Section(Strings.Settings.bannerGroup(l)) {
                Toggle(isOn: $showBannerNotification) {
                    HStack(spacing: 6) {
                        Text(Strings.Settings.showBannerNotification(l))
                        InfoButton(text: Strings.Settings.showBannerCaption(l))
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 260)
    }
}
