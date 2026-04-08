import SwiftUI

/// Display component for status fields that may contain bullet lists.
/// Renders as plain text when the value has zero or one bullet item, and
/// as a vertical bullet list when there are two or more. Used by
/// `HistoryEntryRow` and `ProjectDetailView.latestEntrySection` for the
/// three optional `StatusEntry` fields.
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
