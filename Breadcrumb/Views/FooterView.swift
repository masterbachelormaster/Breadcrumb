import SwiftUI

struct FooterView: View {
    var onNavigate: (ContentView.Screen) -> Void
    var onStartStandalonePomodoro: () -> Void

    @Environment(LanguageManager.self) private var languageManager
    @Environment(WindowManager.self) private var windowManager

    var body: some View {
        HStack(spacing: 0) {
            Button(Strings.Projects.archiveTitle(languageManager.language), systemImage: "archivebox") {
                onNavigate(.archivedProjects)
            }
            .labelStyle(.iconOnly)
            .font(.callout)
            .frame(maxWidth: .infinity)
            .buttonStyle(ToolbarButtonStyle())
            .help(Strings.Projects.archiveTitle(languageManager.language))

            Button(action: onStartStandalonePomodoro) {
                Text("🍅")
                    .font(.callout)
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(ToolbarButtonStyle())
            .help(Strings.Pomodoro.pomodoro(languageManager.language))

            Menu {
                Button(Strings.General.settingsEllipsis(languageManager.language), systemImage: "gearshape") {
                    windowManager.open(.settings)
                }
                Divider()
                Button(Strings.General.quit(languageManager.language), systemImage: "power") {
                    NSApplication.shared.terminate(nil)
                }
            } label: {
                Label(Strings.General.moreOptions(languageManager.language), systemImage: "ellipsis.circle")
                    .labelStyle(.iconOnly)
                    .font(.callout)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .frame(maxWidth: .infinity)
            .buttonStyle(ToolbarButtonStyle())
            .help(Strings.General.moreOptions(languageManager.language))
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .background(.bar)
    }
}
