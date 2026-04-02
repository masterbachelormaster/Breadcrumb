import SwiftUI

struct AboutView: View {
    var onBack: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Header
            if let onBack {
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Zurück")
                        }
                        .font(.body)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("Über Breadcrumb")
                        .font(.headline)

                    Spacer()

                    Color.clear.frame(width: 60, height: 1)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            Spacer()

            // Content
            VStack(spacing: 12) {
                Image("BreadcrumbIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 4)

                Text("Breadcrumb")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Behalte den Überblick über deine Projekte.\nFokussiere dich mit dem Pomodoro-Timer.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
    }
}
