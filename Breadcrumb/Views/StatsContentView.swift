import SwiftUI

struct StatsContentView: View {
    let project: Project

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(project.name)
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text("\(project.completedPomodoroCount)")
                        .font(.system(size: 48, weight: .medium))
                    Text("Abgeschlossene Sitzungen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 4) {
                    Text(formattedFocusTime)
                        .font(.system(size: 48, weight: .medium))
                    Text("Fokuszeit")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Private Methods

    private var formattedFocusTime: String {
        let totalMinutes = Int(project.totalFocusTime) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours) Std. \(minutes) Min."
        }
        return "\(minutes) Min."
    }
}
