import SwiftUI
import AppKit

struct NativeDictationButton: View {
    @AppStorage("feature.dictationEnabled") private var dictationEnabled = false

    var isFocused: Bool

    var body: some View {
        if dictationEnabled {
            Button(
                action: startDictation,
                label: { Image(systemName: "mic.fill") }
            )
            .labelStyle(.iconOnly)
            .foregroundStyle(.secondary)
            .buttonStyle(.borderless)
            .opacity(isFocused ? 1 : 0)
            .allowsHitTesting(isFocused)
        }
    }

    private func startDictation() {
        NSApp.sendAction(NSSelectorFromString("startDictation:"), to: nil, from: nil)
    }
}
