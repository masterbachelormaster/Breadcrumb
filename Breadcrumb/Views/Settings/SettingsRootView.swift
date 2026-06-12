import SwiftUI

struct SettingsRootView: View {
    @Environment(LanguageManager.self) private var languageManager
    @Environment(WindowManager.self) private var windowManager

    var body: some View {
        let l = languageManager.language

        TabView {
            Tab(Strings.Settings.general(l), systemImage: "gearshape") {
                GeneralSettingsTab()
            }
            Tab(Strings.Settings.timerTab(l), systemImage: "timer") {
                TimerSettingsTab()
            }
            Tab(Strings.Settings.notificationsTab(l), systemImage: "bell") {
                NotificationSettingsTab()
            }
            Tab(Strings.Settings.aiSection(l), systemImage: "sparkles") {
                AISettingsTab()
            }
        }
        .onDisappear {
            windowManager.settingsWindowClosed()
        }
    }
}
