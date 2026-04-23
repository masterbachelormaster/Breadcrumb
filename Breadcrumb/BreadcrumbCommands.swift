import SwiftUI

struct BreadcrumbCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    let windowManager: WindowManager
    let languageManager: LanguageManager

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button(Strings.General.about(languageManager.language)) {
                windowManager.open(.about)
            }
            .task { windowManager.setOpenWindowAction(openWindow) }
        }
        CommandGroup(replacing: .appSettings) {
            Button(Strings.General.settingsEllipsis(languageManager.language)) {
                windowManager.open(.settings)
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}
