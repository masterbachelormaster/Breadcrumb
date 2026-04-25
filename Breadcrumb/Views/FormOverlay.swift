import SwiftUI

struct FormOverlay<Content: View>: View {
    var onDismiss: () -> Void
    @ViewBuilder var content: () -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Button(action: onDismiss) {
                Color.black.opacity(0.001)
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
            }
            .buttonStyle(.plain)

            content()
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.97)))
        }
        .transition(.opacity)
    }
}
