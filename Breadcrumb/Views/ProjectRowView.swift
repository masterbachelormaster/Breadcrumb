import SwiftUI

struct ProjectRowView: View {
    @Environment(LanguageManager.self) private var languageManager
    let project: Project

    var body: some View {
        let latestEntry = project.latestEntry
        HStack(spacing: 10) {
            Image(systemName: project.icon)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.headline)
                    .lineLimit(1)

                if let entry = latestEntry {
                    Text(entry.freeText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text(Strings.Status.noStatus(languageManager.language))
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .italic()
                }
            }

            if !project.linkedDocuments.isEmpty {
                HStack(spacing: 2) {
                    Image(systemName: "paperclip")
                    Text("\(project.linkedDocuments.count)")
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            }

            Spacer()

            if let entry = latestEntry {
                SmartTimestampView(date: entry.timestamp, color: AnyShapeStyle(.tertiary))
            }
        }
        .padding(.vertical, 2)
    }
}
