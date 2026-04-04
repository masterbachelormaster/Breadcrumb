import SwiftUI

struct BreakoutWindowView: View {
    @Environment(WindowManager.self) private var windowManager
    @Environment(LanguageManager.self) private var languageManager

    var body: some View {
        Group {
            if let content = windowManager.currentContent {
                NavigationStack {
                    contentView(for: content)
                }
            } else {
                Color.clear
            }
        }
        .frame(
            minWidth: minSize.width,
            idealWidth: idealSize.width,
            minHeight: minSize.height,
            idealHeight: idealSize.height
        )
        .onDisappear {
            windowManager.windowClosed()
        }
    }

    // MARK: - Private Methods

    @ViewBuilder
    private func contentView(for content: BreakoutContent) -> some View {
        let l = languageManager.language
        switch content {
        case .settings:
            SettingsView()
                .navigationTitle(Strings.General.settings(l))
        case .about:
            AboutView()
                .navigationTitle(Strings.General.about(l))
        case .history(let project):
            HistoryView(project: project)
                .navigationTitle(Strings.BreakoutWindows.historyTitle(l, projectName: project.name))
        case .stats(let project):
            StatsContentView(project: project)
                .navigationTitle(Strings.BreakoutWindows.statsTitle(l, projectName: project.name))
        }
    }

    private var minSize: CGSize {
        guard let content = windowManager.currentContent else {
            return CGSize(width: 350, height: 300)
        }
        switch content {
        case .settings: return CGSize(width: 450, height: 350)
        case .about: return CGSize(width: 300, height: 250)
        case .history, .stats: return CGSize(width: 400, height: 300)
        }
    }

    private var idealSize: CGSize {
        guard let content = windowManager.currentContent else {
            return CGSize(width: 500, height: 400)
        }
        switch content {
        case .settings: return CGSize(width: 500, height: 400)
        case .about: return CGSize(width: 350, height: 300)
        case .history, .stats: return CGSize(width: 600, height: 500)
        }
    }
}
