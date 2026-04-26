import SwiftUI
import AppKit

struct NativeDictationButton: View {
    @AppStorage("feature.dictationEnabled") private var dictationEnabled = false
    @Environment(LanguageManager.self) private var languageManager
    @State private var isDictating = false

    var isFocused: Bool

    var body: some View {
        if dictationEnabled {
            Button(
                Strings.Dictation.buttonLabel(languageManager.language),
                systemImage: isDictating ? "mic.badge.xmark" : "mic.fill",
                action: toggleDictation
            )
            .labelStyle(.iconOnly)
            .foregroundStyle(isDictating ? .red : .secondary)
            .buttonStyle(.borderless)
            .help(Strings.Dictation.buttonLabel(languageManager.language))
            .opacity(isFocused ? 1 : 0)
            .allowsHitTesting(isFocused)
        }
    }

    private func toggleDictation() {
        if isDictating {
            NSApp.sendAction(NSSelectorFromString("cancelOperation:"), to: nil, from: nil)
        } else {
            NSApp.sendAction(NSSelectorFromString("startDictation:"), to: nil, from: nil)
        }
        isDictating.toggle()
    }
}
