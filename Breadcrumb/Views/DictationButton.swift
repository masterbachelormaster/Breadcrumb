import SwiftUI

struct DictationButton: View {
    @Environment(SpeechRecognizer.self) private var speechRecognizer
    @Environment(LanguageManager.self) private var languageManager

    @Binding var text: String
    var isFocused: Bool

    var body: some View {
        Button(
            Strings.Dictation.buttonLabel(languageManager.language),
            systemImage: speechRecognizer.isListening ? "mic.fill" : "mic",
            action: toggle
        )
        .labelStyle(.iconOnly)
        .foregroundStyle(speechRecognizer.isListening ? .red : .secondary)
        .symbolEffect(.pulse, isActive: speechRecognizer.isListening)
        .buttonStyle(.borderless)
        .help(
            speechRecognizer.error != nil
                ? Strings.Dictation.permissionRequired(languageManager.language)
                : Strings.Dictation.buttonLabel(languageManager.language)
        )
        .disabled(speechRecognizer.error != nil)
        .opacity(isFocused ? 1 : 0)
        .allowsHitTesting(isFocused)
        .onChange(of: isFocused) { _, focused in
            if !focused && speechRecognizer.isListening {
                speechRecognizer.stopListening()
            }
        }
    }

    private func toggle() {
        if speechRecognizer.isListening {
            speechRecognizer.stopListening()
        } else {
            speechRecognizer.startListening(into: $text, language: languageManager.language)
        }
    }
}
