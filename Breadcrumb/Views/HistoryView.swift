import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(LanguageManager.self) private var languageManager
    let project: Project

    @Environment(\.modelContext) private var modelContext

    var onBack: (() -> Void)? = nil

    @State private var entryToDelete: StatusEntry?

    private var sortedEntries: [StatusEntry] {
        project.entries.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            if let onBack {
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text(Strings.General.back(languageManager.language))
                        }
                        .font(.body)
                    }
                    .buttonStyle(ToolbarButtonStyle())

                    Spacer()

                    Text(Strings.Status.history(languageManager.language))
                        .font(.headline)

                    Spacer()

                    Color.clear.frame(width: 60, height: 1)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            // Content
            if sortedEntries.isEmpty {
                ContentUnavailableView(
                    Strings.Status.noEntries(languageManager.language),
                    systemImage: "clock",
                    description: Text(Strings.Status.noEntriesDescription(languageManager.language))
                )
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(sortedEntries) { entry in
                        HistoryEntryRow(entry: entry)
                    }
                    .onDelete(perform: confirmDeleteEntries)
                }
            }
        }
        .confirmationDialog(
            Strings.Confirm.deleteEntryTitle(languageManager.language),
            isPresented: .init(
                get: { entryToDelete != nil },
                set: { if !$0 { entryToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(Strings.General.delete(languageManager.language), role: .destructive) {
                if let entry = entryToDelete {
                    modelContext.delete(entry)
                    modelContext.saveWithLogging()
                }
            }
        } message: {
            Text(Strings.Confirm.deleteEntryMessage(languageManager.language))
        }
    }

    private func confirmDeleteEntries(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        entryToDelete = sortedEntries[index]
    }
}
