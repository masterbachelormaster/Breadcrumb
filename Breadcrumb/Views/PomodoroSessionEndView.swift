import SwiftUI
import SwiftData

struct PomodoroSessionEndView: View {
    @Environment(PomodoroTimer.self) private var timer
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.modelContext) private var modelContext

    let wasBreak: Bool
    var onSaveAndBreak: (PomodoroSession) -> Void
    var onContinueWorking: () -> Void
    var onSkip: () -> Void
    var onStartNextSession: () -> Void
    var onStopCompletely: () -> Void

    @State private var freeText = ""
    @State private var lastAction = ""
    @State private var nextStep = ""
    @State private var openQuestions = ""
    @State private var showOptionalFields = false
    @State private var selectedProject: Project?
    @FocusState private var isFreeTextFocused: Bool

    @Query(filter: #Predicate<Project> { $0.isActive })
    private var activeProjects: [Project]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if wasBreak {
                    breakEndContent
                } else {
                    workEndContent
                }
            }
            .padding()
        }
        .frame(width: 320)
        .frame(maxHeight: 400)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(.rect(cornerRadius: 10))
        .shadow(radius: 10)
        .onAppear {
            selectedProject = timer.boundProject
        }
        .task {
            if !wasBreak {
                try? await Task.sleep(for: .milliseconds(300))
                isFreeTextFocused = true
            }
        }
    }

    @ViewBuilder
    private var breakEndContent: some View {
        let l = languageManager.language
        Text(Strings.Pomodoro.breakOver(l))
            .font(.headline)
        Text(Strings.Pomodoro.readyForNext(l))
            .font(.subheadline)
            .foregroundStyle(.secondary)

        HStack {
            Button(Strings.Pomodoro.nextSession(l)) { onStartNextSession() }
                .buttonStyle(.borderedProminent)
            Button(Strings.Pomodoro.stopCompletely(l)) { onStopCompletely() }
                .buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    private var workEndContent: some View {
        let l = languageManager.language
        Text(Strings.Pomodoro.sessionFinished(l))
            .font(.headline)

        // Project picker for standalone sessions
        if timer.boundProject == nil {
            Picker(Strings.Projects.project(l), selection: $selectedProject) {
                Text(Strings.Projects.withoutProject(l)).tag(nil as Project?)
                ForEach(activeProjects) { project in
                    Label(project.name, systemImage: project.icon)
                        .tag(project as Project?)
                }
            }
        }

        // Status entry form
        TextField(Strings.Status.whereAreYou(l), text: $freeText, axis: .vertical)
            .lineLimit(3...)
            .textFieldStyle(.roundedBorder)
            .focused($isFreeTextFocused)

        AIExtractButton(
            freeText: $freeText,
            lastAction: $lastAction,
            nextStep: $nextStep,
            openQuestions: $openQuestions,
            showOptionalFields: $showOptionalFields
        )

        DisclosureGroup(Strings.Status.optionalFields(l), isExpanded: $showOptionalFields) {
            VStack(spacing: 8) {
                OptionalFieldView(label: Strings.Status.lastStep(l), text: $lastAction)
                OptionalFieldView(label: Strings.Status.nextStep(l), text: $nextStep)
                OptionalFieldView(label: Strings.Status.openQuestions(l), text: $openQuestions)
            }
            .padding(.top, 4)
        }

        HStack {
            Button(Strings.Pomodoro.saveAndBreak(l)) { saveAndBreak() }
                .buttonStyle(.borderedProminent)
                .disabled(selectedProject == nil && timer.boundProject == nil)
            Button(Strings.Pomodoro.continueWorking(l)) { onContinueWorking() }
                .buttonStyle(.bordered)
        }
        HStack(spacing: 16) {
            Button(Strings.Pomodoro.skip(l)) { onSkip() }
            Button(Strings.Pomodoro.stopCompletely(l)) { onStopCompletely() }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .buttonStyle(ToolbarButtonStyle())
    }

    private func saveAndBreak() {
        let project = selectedProject ?? timer.boundProject

        // Create PomodoroSession record
        let session = PomodoroSession(
            plannedDuration: TimeInterval(timer.originalDurationSeconds),
            sessionType: .work,
            sessionNumber: timer.currentSessionNumber
        )
        session.completed = true
        session.endedAt = .now
        session.actualDuration = TimeInterval(timer.originalDurationSeconds + timer.overtimeSeconds)
        session.project = project

        // Create status entry if text provided
        let trimmed = freeText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty, let project {
            let entry = StatusEntry(
                freeText: trimmed,
                lastAction: lastAction.isEmpty ? nil : lastAction,
                nextStep: nextStep.isEmpty ? nil : nextStep,
                openQuestions: openQuestions.isEmpty ? nil : openQuestions
            )
            entry.project = project
            entry.pomodoroSession = session
            project.entries.append(entry)
        }

        onSaveAndBreak(session)
    }
}
