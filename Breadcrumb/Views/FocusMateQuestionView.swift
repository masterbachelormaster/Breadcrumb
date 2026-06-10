import SwiftUI

struct FocusMateQuestionView: View {
    @Environment(LanguageManager.self) private var languageManager
    var onAnswer: (Bool) -> Void

    var body: some View {
        let l = languageManager.language

        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "person.2.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)

            Text(Strings.FocusMateQuestion.title(l))
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text(Strings.FocusMateQuestion.explanation(l))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Link(Strings.FocusMateQuestion.linkLabel(l), destination: URL(string: "https://www.focusmate.com")!)
                .font(.callout)

            Spacer()

            HStack(spacing: 12) {
                Button(Strings.FocusMateQuestion.no(l)) {
                    onAnswer(false)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button(Strings.FocusMateQuestion.yes(l)) {
                    onAnswer(true)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }

            Spacer()
                .frame(height: 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
