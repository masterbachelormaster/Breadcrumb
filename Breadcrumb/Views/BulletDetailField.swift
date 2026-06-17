import SwiftUI

/// Read-only display for an optional status field ("Last step" / "Next step").
/// Renders the stored value line by line: a line with no leading marker is a
/// top-level item shown as plain text; a line beginning with a list marker
/// (e.g. "- foo") is shown as an indented sub-step bullet (the marker stripped,
/// so there is never a doubled "• -"). "Is a sub-step?" is implicit from
/// content — see `BulletText`. Display only; there is no per-row editor (that
/// was the removed `BulletableField`).
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
            if items.isEmpty {
                Text(value)
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        row(for: item)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func row(for item: String) -> some View {
        if BulletText.isSubItem(item) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("•")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text(BulletText.stripLeadingMarkers(item))
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, 14)
        } else {
            Text(item)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
