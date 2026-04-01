import SwiftUI
import SwiftData

struct HistoryView: View {
    let project: Project

    @Environment(\.modelContext) private var modelContext

    private var sortedEntries: [StatusEntry] {
        project.entries.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        Group {
            if sortedEntries.isEmpty {
                ContentUnavailableView(
                    "Keine Einträge",
                    systemImage: "clock",
                    description: Text("Noch keine Status-Einträge vorhanden")
                )
            } else {
                List {
                    ForEach(sortedEntries) { entry in
                        HistoryEntryRow(entry: entry)
                    }
                    .onDelete(perform: deleteEntries)
                }
            }
        }
        .navigationTitle("Historie")
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            let entry = sortedEntries[index]
            modelContext.delete(entry)
        }
    }
}

struct HistoryEntryRow: View {
    let entry: StatusEntry
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.freeText)
                    .font(.body)

                if let lastAction = entry.lastAction, !lastAction.isEmpty {
                    detailField(label: "Letzter Schritt", value: lastAction)
                }
                if let nextStep = entry.nextStep, !nextStep.isEmpty {
                    detailField(label: "Nächster Schritt", value: nextStep)
                }
                if let openQuestions = entry.openQuestions, !openQuestions.isEmpty {
                    detailField(label: "Offene Fragen", value: openQuestions)
                }
            }
            .padding(.vertical, 4)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.timestamp, format: .dateTime.day().month().year().hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(entry.freeText)
                        .font(.subheadline)
                        .lineLimit(1)
                }
                Spacer()
            }
        }
    }

    private func detailField(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
            Text(value)
                .font(.callout)
        }
    }
}
