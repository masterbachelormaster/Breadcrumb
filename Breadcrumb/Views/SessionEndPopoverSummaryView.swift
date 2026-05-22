import SwiftUI

struct SessionEndPopoverSummaryView: View {
    @Environment(LanguageManager.self) private var languageManager

    var onOpenPrompt: () -> Void

    var body: some View {
        let l = languageManager.language

        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "checkmark.square.fill")
                .font(.largeTitle)
                .foregroundStyle(.green)

            VStack(spacing: 6) {
                Text(Strings.Pomodoro.sessionEndedOpenPromptTitle(l))
                    .font(.headline)
                Text(Strings.Pomodoro.sessionEndedOpenPromptMessage(l))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onOpenPrompt) {
                Label(Strings.Pomodoro.openSessionEndPrompt(l), systemImage: "macwindow")
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
