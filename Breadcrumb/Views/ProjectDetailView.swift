import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    let project: Project

    @Environment(\.modelContext) private var modelContext
    @Environment(WindowManager.self) private var windowManager
    @Environment(LanguageManager.self) private var languageManager

    var onBack: () -> Void
    var onStartPomodoro: () -> Void

    @State private var showingStatusForm = false
    @State private var showingEditForm = false
    @State private var showDeleteConfirmation = false
    @State private var isStatsExpanded = false

    // Status form drafts
    @State private var draftFreeText = ""
    @State private var draftLastAction = ""
    @State private var draftNextStep = ""
    @State private var draftOpenQuestions = ""

    // Edit form drafts
    @State private var editDraftName = ""
    @State private var editDraftIcon = "doc.text"

    // Document form state
    @State private var showingURLForm = false
    @State private var showingEditLabel = false
    @State private var editingDocument: LinkedDocument?
    @State private var draftURL = ""
    @State private var draftLabel = ""

    private var hasActiveOverlay: Bool {
        showingStatusForm || showingEditForm || showingURLForm || showingEditLabel
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
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

                    Text(project.name)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer()

                    Menu {
                        Button(Strings.General.edit(languageManager.language), systemImage: "pencil") {
                            editDraftName = project.name
                            editDraftIcon = project.icon
                            showOverlay { showingEditForm = true }
                        }
                        Button(Strings.Projects.archive(languageManager.language), systemImage: "archivebox") {
                            project.isActive = false
                            modelContext.saveWithLogging()
                            onBack()
                        }
                        Divider()
                        Button(Strings.General.delete(languageManager.language), systemImage: "trash", role: .destructive) {
                            showDeleteConfirmation = true
                        }
                    } label: {
                        Label(Strings.General.moreOptions(languageManager.language), systemImage: "ellipsis.circle")
                            .labelStyle(.iconOnly)
                            .font(.body)
                    }
                    .buttonStyle(ToolbarButtonStyle())
                    .help(Strings.General.moreOptions(languageManager.language))
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        DocumentListView(
                            project: project,
                            onAddURL: {
                                draftURL = ""
                                draftLabel = ""
                                showOverlay { showingURLForm = true }
                            },
                            onEditLabel: { doc in
                                editingDocument = doc
                                draftLabel = doc.label ?? doc.originalFilename
                                showOverlay { showingEditLabel = true }
                            }
                        )

                        if let entry = project.latestEntry {
                            latestEntrySection(entry)
                        } else {
                            ContentUnavailableView(
                                Strings.Status.noStatusYet(languageManager.language),
                                systemImage: "text.badge.plus",
                                description: Text(Strings.Status.noStatusYetDescription(languageManager.language))
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
                        Label(Strings.Pomodoro.pomodoro(languageManager.language), systemImage: "timer")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)

                    Button(Strings.Status.updateStatus(languageManager.language)) {
                        showOverlay { showingStatusForm = true }
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut("u", modifiers: .command)
                    .help(Strings.Status.updateStatusHint(languageManager.language))

                    Spacer()

                    Button(Strings.Status.history(languageManager.language)) {
                        windowManager.open(.history(project))
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .confirmationDialog(
                Strings.Confirm.deleteProjectTitle(languageManager.language),
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(Strings.General.delete(languageManager.language), role: .destructive) {
                    modelContext.delete(project)
                    modelContext.saveWithLogging()
                    onBack()
                }
            } message: {
                Text(Strings.Confirm.deleteProjectMessage(languageManager.language, name: project.name))
            }
            .allowsHitTesting(!hasActiveOverlay)

            if showingStatusForm {
                FormOverlay(onDismiss: { dismissOverlay { showingStatusForm = false } }) {
                    StatusEntryForm(
                        project: project,
                        freeText: $draftFreeText,
                        lastAction: $draftLastAction,
                        nextStep: $draftNextStep,
                        openQuestions: $draftOpenQuestions,
                        onDismiss: { dismissOverlay { showingStatusForm = false } }
                    )
                }
                .transition(.opacity)
            }

            if showingEditForm {
                FormOverlay(onDismiss: { dismissOverlay { showingEditForm = false } }) {
                    ProjectFormView(
                        editingProject: project,
                        name: $editDraftName,
                        selectedIcon: $editDraftIcon,
                        onDismiss: { dismissOverlay { showingEditForm = false } }
                    )
                }
                .transition(.opacity)
            }

            if showingURLForm {
                FormOverlay(onDismiss: { dismissOverlay { showingURLForm = false } }) {
                    AddURLFormView(
                        project: project,
                        draftURL: $draftURL,
                        draftLabel: $draftLabel,
                        onDismiss: { dismissOverlay { showingURLForm = false } }
                    )
                }
                .transition(.opacity)
            }

            if showingEditLabel {
                FormOverlay(onDismiss: { dismissOverlay { showingEditLabel = false; editingDocument = nil } }) {
                    EditLabelFormView(
                        editingDocument: editingDocument,
                        draftLabel: $draftLabel,
                        onDismiss: { dismissOverlay { showingEditLabel = false; editingDocument = nil } }
                    )
                }
                .transition(.opacity)
            }

        }
    }

    @ViewBuilder
    private func latestEntrySection(_ entry: StatusEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(Strings.Status.currentStatus(languageManager.language))
                    .font(.headline)
                Spacer()
                SmartTimestampView(date: entry.timestamp, color: AnyShapeStyle(.tertiary))
            }

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
    }

    @ViewBuilder
    private var pomodoroStatsSection: some View {
        Divider()

        // Collapsible header
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isStatsExpanded.toggle()
            }
        } label: {
            HStack {
                Text(Strings.Pomodoro.pomodoro(languageManager.language))
                    .font(.headline)
                Text("\(project.completedPomodoroCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isStatsExpanded ? 90 : 0))
            }
        }
        .buttonStyle(ToolbarButtonStyle())

        // Expandable content
        if isStatsExpanded {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.Pomodoro.completed(languageManager.language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text("\(project.completedPomodoroCount)")
                            .font(.title2)
                            .fontWeight(.medium)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 2) {
                        Text(Strings.Pomodoro.focusTime(languageManager.language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text(project.formattedFocusTime(languageManager.language))
                            .font(.title2)
                            .fontWeight(.medium)
                    }
                }

                Button {
                    windowManager.open(.stats(project))
                } label: {
                    HStack(spacing: 2) {
                        Spacer()
                        Text(Strings.Pomodoro.details(languageManager.language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(ToolbarButtonStyle())
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private func showOverlay(_ action: () -> Void) {
        withAnimation(.easeInOut(duration: 0.2)) {
            action()
        }
    }

    private func dismissOverlay(_ action: () -> Void) {
        withAnimation(.easeInOut(duration: 0.2)) {
            action()
        }
    }

}
