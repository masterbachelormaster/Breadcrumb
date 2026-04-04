import SwiftUI

struct FooterView: View {
    var onNavigate: (ContentView.Screen) -> Void
    var onStartStandalonePomodoro: () -> Void

    @Environment(LanguageManager.self) private var languageManager

    var body: some View {
        HStack(spacing: 0) {
            Button(Strings.Projects.archiveTitle(languageManager.language), systemImage: "archivebox") {
                onNavigate(.archivedProjects)
            }
            .labelStyle(.iconOnly)
            .font(.callout)
            .frame(maxWidth: .infinity)
            .buttonStyle(ToolbarButtonStyle())

            Button(action: onStartStandalonePomodoro) {
                Text("🍅")
                    .font(.callout)
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(ToolbarButtonStyle())
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .background(.bar)
    }
}
