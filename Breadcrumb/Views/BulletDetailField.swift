import SwiftUI

/// Read-only display for an optional status field ("Last step" / "Next step").
/// Renders as plain text when the value has zero or one line, and as a
/// vertical bullet list when there are two or more. "Is a list?" is implicit
/// from content (newlines) — see `BulletText`. This is display only; there is
/// no per-row editor (that was the removed `BulletableField`).
struct BulletDetailField: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            let items = BulletText.parse(value)
            if items.count <= 1 {
                Text(items.first ?? value)
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("•")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            Text(item)
                                .font(.callout)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }
}
