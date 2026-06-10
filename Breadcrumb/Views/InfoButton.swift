import SwiftUI

/// Small ⓘ button that reveals an explanation in a popover on click.
struct InfoButton: View {
    let text: String
    @State private var isShowingInfo = false

    var body: some View {
        Button {
            isShowingInfo.toggle()
        } label: {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(text)
        .popover(isPresented: $isShowingInfo, arrowEdge: .bottom) {
            Text(text)
                .font(.callout)
                .multilineTextAlignment(.leading)
                .frame(width: 280, alignment: .leading)
                .padding(12)
        }
    }
}
