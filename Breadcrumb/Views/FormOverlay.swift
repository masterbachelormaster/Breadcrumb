import SwiftUI

struct FormOverlay<Content: View>: View {
    var onDismiss: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            Button(action: onDismiss) {
                Color.black.opacity(0.001)
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
            }
            .buttonStyle(.plain)

            content()
        }
    }
}
