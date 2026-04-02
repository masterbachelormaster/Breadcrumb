import SwiftUI

struct WelcomeView: View {
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image("BreadcrumbIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(radius: 6)

            Text("Willkommen bei Breadcrumb")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 12) {
                featureRow(
                    icon: "bookmark.fill",
                    title: "Projekte verfolgen",
                    description: "Halte fest, wo du bei jedem Projekt stehst"
                )
                featureRow(
                    icon: "timer",
                    title: "Pomodoro-Timer",
                    description: "Fokussierte Arbeitssitzungen mit Pausen"
                )
                featureRow(
                    icon: "clock",
                    title: "Status-Historie",
                    description: "Sieh dir an, was du wann gemacht hast"
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            Button("Los geht's!") {
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
