import SwiftUI
import SwiftData

struct PomodoroSessionEndView: View {
    @Environment(PomodoroTimer.self) private var timer
    @Environment(LanguageManager.self) private var languageManager
    @Environment(\.modelContext) private var modelContext
    @Environment(SpeechRecognizer.self) private var speechRecognizer

    let wasBreak: Bool
    var isCycleComplete: Bool = false
    var isFocusMate: Bool = false
    var onSaveAndBreak: (PomodoroSession) -> Void
    var onContinueWorking: () -> Void
    var onSkip: () -> Void
    var onStartNextSession: () -> Void
    var onStopCompletely: () -> Void
    var onStopAfterSave: () -> Void
    var onSnooze: (Int) -> Void

    @State private var freeText = ""
    @State private var freeTextFocused = false
    @State private var lastAction = ""
    @State private var nextStep = ""
    @State private var openQuestions = ""
    @State private var showOptionalFields = false
    @State private var selectedProject: Project?

    @Query(filter: #Predicate<Project> { $0.isActive })
    private var activeProjects: [Project]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if wasBreak {
                    breakEndContent
                } else if isFocusMate {
                    focusMateEndContent
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
    }

    @ViewBuilder
    private var breakEndContent: some View {
        let l = languageManager.language
        if isCycleComplete {
            Text(Strings.Pomodoro.allSessionsComplete(l))
                .font(.headline)
            Button(Strings.Pomodoro.stopCompletely(l)) { onStopCompletely() }
                .buttonStyle(.borderedProminent)
        } else {
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
    }

    @ViewBuilder
    private var focusMateEndContent: some View {
        let l = languageManager.language
        Text(Strings.Pomodoro.focusMateComplete(l))
            .font(.headline)

        statusEntryForm

        HStack {
            Button(Strings.Pomodoro.saveAndDone(l)) { saveAndDone() }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
                .help(Strings.Pomodoro.saveAndDoneHint(l))
                .disabled(selectedProject == nil && timer.boundProject == nil)
            Button(Strings.Pomodoro.skip(l)) { onStopCompletely() }
                .buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    private var workEndContent: some View {
        let l = languageManager.language
        Text(Strings.Pomodoro.sessionFinished(l))
            .font(.headline)

        HStack(spacing: 8) {
            Button(Strings.Pomodoro.snooze5(l), action: { onSnooze(5) })
                .buttonStyle(.bordered)
            Button(Strings.Pomodoro.snooze10(l), action: { onSnooze(10) })
                .buttonStyle(.bordered)
        }

        statusEntryForm

        HStack {
            Button(Strings.Pomodoro.saveAndBreak(l), action: saveAndBreak)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
                .help(Strings.Pomodoro.saveAndBreakHint(l))
                .disabled(selectedProject == nil && timer.boundProject == nil)
            Button(Strings.Pomodoro.continueWorking(l), action: { onContinueWorking() })
                .buttonStyle(.bordered)
        }
        HStack(spacing: 16) {
            Button(Strings.Pomodoro.skip(l), action: { onSkip() })
            Button(Strings.Pomodoro.stopCompletely(l), action: { onStopCompletely() })
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .buttonStyle(ToolbarButtonStyle())
    }

    @ViewBuilder
    private var statusEntryForm: some View {
        let l = languageManager.language

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
        ZStack(alignment: .bottomTrailing) {
            PlaceholderTextView(
                placeholder: Strings.Status.whereAreYou(l),
                text: $freeText,
                focusOnAppear: !wasBreak,
                onFocusChange: { freeTextFocused = $0 }
            )
            .frame(minHeight: 50, maxHeight: 100)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(.rect(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(nsColor: .separatorColor)))

            DictationButton(text: $freeText, isFocused: freeTextFocused)
                .padding(6)
        }

        AIExtractButton(
            freeText: $freeText,
            lastAction: $lastAction,
            nextStep: $nextStep,
            openQuestions: $openQuestions,
            showOptionalFields: $showOptionalFields
        )

        DisclosureGroup(Strings.Status.optionalFields(l), isExpanded: $showOptionalFields) {
            VStack(spacing: 8) {
                BulletableField(label: Strings.Status.lastStep(l), text: $lastAction)
                BulletableField(label: Strings.Status.nextStep(l), text: $nextStep)
                BulletableField(label: Strings.Status.openQuestions(l), text: $openQuestions)
            }
            .padding(.top, 4)
        }
    }

    private func saveAndBreak() {
        speechRecognizer.stopListening()
        let project = selectedProject ?? timer.boundProject

        // Create PomodoroSession record
        let session = PomodoroSession(
            plannedDuration: TimeInterval(timer.originalDurationSeconds),
            sessionType: .work,
            sessionNumber: timer.currentSessionNumber
        )
        session.completed = timer.remainingSeconds <= 0
        session.endedAt = .now
        session.actualDuration = TimeInterval(timer.originalDurationSeconds - timer.remainingSeconds + timer.overtimeSeconds)
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
            modelContext.insert(entry)
        }

        onSaveAndBreak(session)
    }

    private func saveAndDone() {
        speechRecognizer.stopListening()
        let project = selectedProject ?? timer.boundProject

        let session = PomodoroSession(
            plannedDuration: TimeInterval(timer.originalDurationSeconds),
            sessionType: .work,
            sessionNumber: timer.currentSessionNumber
        )
        session.completed = true
        session.endedAt = .now
        session.actualDuration = TimeInterval(timer.phaseDurationSeconds - timer.remainingSeconds)
        session.project = project
        session.isFocusMate = true

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
            modelContext.insert(entry)
        }

        modelContext.insert(session)
        modelContext.saveWithLogging()
        onStopAfterSave()
    }
}
