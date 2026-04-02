import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    let project: Project

    @Environment(\.modelContext) private var modelContext
    @Environment(WindowManager.self) private var windowManager
    @Environment(\.openWindow) private var openWindow

    var onBack: () -> Void
    var onStartPomodoro: () -> Void

    @State private var showingStatusForm = false
    @State private var showingEditForm = false

    // Status form drafts
    @State private var draftFreeText = ""
    @State private var draftLastAction = ""
    @State private var draftNextStep = ""
    @State private var draftOpenQuestions = ""

    // Edit form drafts
    @State private var editDraftName = ""
    @State private var editDraftIcon = "doc.text"

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Zurück")
                        }
                        .font(.body)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text(project.name)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer()

                    Menu {
                        Button("Bearbeiten", systemImage: "pencil") {
                            if editDraftName.isEmpty {
                                editDraftName = project.name
                                editDraftIcon = project.icon
                            }
                            showingEditForm = true
                        }
                        Button("Archivieren", systemImage: "archivebox") {
                            project.isActive = false
                            onBack()
                        }
                        Divider()
                        Button("Löschen", systemImage: "trash", role: .destructive) {
                            modelContext.delete(project)
                            onBack()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.body)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Content
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

                        if project.completedPomodoroCount > 0 {
                            pomodoroStatsSection
                        }
                    }
                    .padding()
                    .textSelection(.enabled)
                }

                // Footer
                HStack {
                    Button {
                        onStartPomodoro()
                    } label: {
                        Label("Pomodoro", systemImage: "timer")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)

                    Button("Status aktualisieren") {
                        showingStatusForm = true
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()

                    Button("Historie") {
                        windowManager.open(.history(project))
                        openWindow(id: "main")
                    }
                }
                .padding()
            }

            // Inline overlay for status form
            if showingStatusForm {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { showingStatusForm = false }
                StatusEntryForm(
                    project: project,
                    freeText: $draftFreeText,
                    lastAction: $draftLastAction,
                    nextStep: $draftNextStep,
                    openQuestions: $draftOpenQuestions,
                    onDismiss: { showingStatusForm = false }
                )
            }

            // Inline overlay for edit form
            if showingEditForm {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { showingEditForm = false }
                ProjectFormView(
                    editingProject: project,
                    name: $editDraftName,
                    selectedIcon: $editDraftIcon,
                    onDismiss: { showingEditForm = false }
                )
            }
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

    @ViewBuilder
    private var pomodoroStatsSection: some View {
        Divider()
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Pomodoro")
                    .font(.headline)
                Spacer()
                HStack(spacing: 2) {
                    Text("Details")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Abgeschlossen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text("\(project.completedPomodoroCount)")
                        .font(.title2)
                        .fontWeight(.medium)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    Text("Fokuszeit")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text(project.formattedFocusTime)
                        .font(.title2)
                        .fontWeight(.medium)
                }
            }
        }
        .onTapGesture {
            windowManager.open(.stats(project))
            openWindow(id: "main")
        }
    }

}
