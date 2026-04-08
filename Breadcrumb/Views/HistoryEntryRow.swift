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
                    BulletDetailField(label: Strings.Status.lastStep(languageManager.language), value: lastAction)
                }
                if let nextStep = entry.nextStep, !nextStep.isEmpty {
                    BulletDetailField(label: Strings.Status.nextStep(languageManager.language), value: nextStep)
                }
                if let openQuestions = entry.openQuestions, !openQuestions.isEmpty {
                    BulletDetailField(label: Strings.Status.openQuestions(languageManager.language), value: openQuestions)
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
