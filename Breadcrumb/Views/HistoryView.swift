import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(LanguageManager.self) private var languageManager
    let project: Project

    @Environment(\.modelContext) private var modelContext

    var onBack: (() -> Void)? = nil

    @State private var entryToDelete: StatusEntry?
    @State private var showingEditForm = false
    @State private var editingEntry: StatusEntry?
    @State private var draftFreeText = ""
    @State private var draftLastAction = ""
    @State private var draftNextStep = ""

    private var sortedEntries: [StatusEntry] {
        project.entries.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        ZStack {
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
                                .contextMenu {
                                    if entry.id == sortedEntries.first?.id {
                                        Button(Strings.Status.editStatus(languageManager.language), systemImage: "pencil") {
                                            draftFreeText = entry.freeText
                                            draftLastAction = entry.lastAction ?? ""
                                            draftNextStep = entry.nextStep ?? ""
                                            editingEntry = entry
                                            showEditOverlay { showingEditForm = true }
                                        }
                                        Divider()
                                    }
                                    Button(Strings.General.delete(languageManager.language), systemImage: "trash", role: .destructive) {
                                        entryToDelete = entry
                                    }
                                }
                        }
                        .onDelete(perform: confirmDeleteEntries)
                    }
                }
            }
            .allowsHitTesting(!showingEditForm)
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

            if showingEditForm {
                FormOverlay(onDismiss: { dismissEditOverlay() }) {
                    StatusEntryForm(
                        project: project,
                        editingEntry: editingEntry,
                        freeText: $draftFreeText,
                        lastAction: $draftLastAction,
                        nextStep: $draftNextStep,
                        onDismiss: { dismissEditOverlay() }
                    )
                }
                .transition(.opacity)
            }
        }
    }

    private func confirmDeleteEntries(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        entryToDelete = sortedEntries[index]
    }

    private func showEditOverlay(_ action: () -> Void) {
        withAnimation(.easeInOut(duration: 0.2)) {
            action()
        }
    }

    private func dismissEditOverlay() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showingEditForm = false
            editingEntry = nil
        }
    }
}
