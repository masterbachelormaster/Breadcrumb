import SwiftUI

struct StatsContentView: View {
    @Environment(LanguageManager.self) private var languageManager
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
                    Text(Strings.Pomodoro.completedSessions(languageManager.language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 4) {
                    Text(project.formattedFocusTime)
                        .font(.system(size: 48, weight: .medium))
                    Text(Strings.Pomodoro.focusTime(languageManager.language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

}
