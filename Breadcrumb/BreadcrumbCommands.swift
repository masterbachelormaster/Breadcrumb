import SwiftUI

struct BreadcrumbCommands: Commands {
    let windowManager: WindowManager
    let languageManager: LanguageManager

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button(Strings.General.about(languageManager.language)) {
                windowManager.open(.about)
            }
        }
        CommandGroup(replacing: .appSettings) {
            Button(Strings.General.settingsEllipsis(languageManager.language)) {
                windowManager.openSettings()
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}
