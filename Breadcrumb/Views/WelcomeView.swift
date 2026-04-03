import SwiftUI

struct WelcomeView: View {
    @Environment(LanguageManager.self) private var languageManager
    var onDismiss: () -> Void

    var body: some View {
        let l = languageManager.language

        VStack(spacing: 20) {
            Spacer()

            Image("BreadcrumbIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(radius: 6)

            Text(Strings.Welcome.title(l))
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 12) {
                featureRow(
                    icon: "bookmark.fill",
                    title: Strings.Welcome.trackProjects(l),
                    description: Strings.Welcome.trackProjectsDescription(l)
                )
                featureRow(
                    icon: "timer",
                    title: Strings.Welcome.pomodoroTimer(l),
                    description: Strings.Welcome.pomodoroTimerDescription(l)
                )
                featureRow(
                    icon: "clock",
                    title: Strings.Welcome.statusHistory(l),
                    description: Strings.Welcome.statusHistoryDescription(l)
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(Strings.Welcome.letsGo(l)) {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
                .frame(height: 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
