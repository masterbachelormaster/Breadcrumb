import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    let project: Project

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showingStatusForm = false
    @State private var showingEditForm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let entry = project.latestEntry {
                    latestEntrySection(entry)
                } else {
                    ContentUnavailableView(
                        "Noch kein Status erfasst",
                        systemImage: "text.badge.plus",
                        description: Text("Halte fest, wo du gerade stehst")
                    )
                }
            }
            .padding()
        }
        .navigationTitle(project.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Bearbeiten", systemImage: "pencil") {
                        showingEditForm = true
                    }
                    Button("Archivieren", systemImage: "archivebox") {
                        project.isActive = false
                        dismiss()
                    }
                    Divider()
                    Button("Löschen", systemImage: "trash", role: .destructive) {
                        modelContext.delete(project)
                        dismiss()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button("Status aktualisieren") {
                    showingStatusForm = true
                }
                .buttonStyle(.borderedProminent)

                Spacer()

                NavigationLink("Historie") {
                    HistoryView(project: project)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingStatusForm) {
            StatusEntryForm(project: project)
        }
        .sheet(isPresented: $showingEditForm) {
            ProjectFormView(editingProject: project)
        }
    }

    @ViewBuilder
    private func latestEntrySection(_ entry: StatusEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Aktueller Stand")
                    .font(.headline)
                Spacer()
                Text(entry.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Text(entry.freeText)
                .font(.body)

            if let lastAction = entry.lastAction, !lastAction.isEmpty {
                fieldRow(label: "Letzter Schritt", value: lastAction)
            }
            if let nextStep = entry.nextStep, !nextStep.isEmpty {
                fieldRow(label: "Nächster Schritt", value: nextStep)
            }
            if let openQuestions = entry.openQuestions, !openQuestions.isEmpty {
                fieldRow(label: "Offene Fragen", value: openQuestions)
            }
        }
    }

    private func fieldRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.callout)
        }
    }
}
