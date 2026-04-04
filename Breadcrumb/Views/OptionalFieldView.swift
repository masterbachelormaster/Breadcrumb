import SwiftUI

struct OptionalFieldView: View {
    let label: String
    @Binding var text: String

    var body: some View {
        TextField(label, text: $text)
            .textFieldStyle(.roundedBorder)
    }
}
