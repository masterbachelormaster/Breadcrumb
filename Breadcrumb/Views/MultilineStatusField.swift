import SwiftUI

/// Multi-line editor for the optional "Last step" / "Next step" status fields.
/// Wraps the proven `PlaceholderTextView` (the same `NSTextView`-backed box the
/// main free-text field uses) with the standard framed look, so each field can
/// hold one item per line. Plain Return inserts a newline; Cmd+Return saves the
/// surrounding form. This is a single text box — not a per-row bullet editor.
struct MultilineStatusField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        PlaceholderTextView(placeholder: placeholder, text: $text)
            .frame(minHeight: 40, maxHeight: 100)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(.rect(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(nsColor: .separatorColor)))
    }
}
