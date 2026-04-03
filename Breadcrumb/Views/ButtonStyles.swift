import SwiftUI

// MARK: - Toolbar Button Style

struct ToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ToolbarButtonBody(configuration: configuration)
    }
}

private struct ToolbarButtonBody: View {
    let configuration: ButtonStyleConfiguration
    @State private var isHovered = false

    var body: some View {
        configuration.label
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(minWidth: 28, minHeight: 28)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(backgroundColor(isPressed: configuration.isPressed))
            )
            .onHover { isHovered = $0 }
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if isPressed {
            return Color.primary.opacity(0.15)
        } else if isHovered {
            return Color.primary.opacity(0.06)
        } else {
            return .clear
        }
    }
}

// MARK: - List Row Button Style

struct ListRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
