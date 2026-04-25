import SwiftUI

struct HistoryEntryRow: View {
    @Environment(LanguageManager.self) private var languageManager
    let entry: StatusEntry
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.freeText)
                    .font(.body)

                if let lastAction = entry.lastAction, !lastAction.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.Status.lastStep(languageManager.language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text(lastAction)
                            .font(.callout)
                    }
                }
                if let nextStep = entry.nextStep, !nextStep.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.Status.nextStep(languageManager.language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text(nextStep)
                            .font(.callout)
                    }
                }
                if let openQuestions = entry.openQuestions, !openQuestions.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.Status.openQuestions(languageManager.language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text(openQuestions)
                            .font(.callout)
                    }
                }
            }
            .padding(.vertical, 4)
            .textSelection(.enabled)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    SmartTimestampView(date: entry.timestamp)
                    Text(entry.freeText)
                        .font(.subheadline)
                        .lineLimit(1)
                }
                Spacer()
            }
        }
    }
}
