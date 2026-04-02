import SwiftUI
import SwiftData

struct PomodoroSessionEndView: View {
    @Environment(PomodoroTimer.self) private var timer
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

    @Query(filter: #Predicate<Project> { $0.isActive })
    private var activeProjects: [Project]

    var body: some View {
        VStack(spacing: 16) {
            if wasBreak {
                breakEndContent
            } else {
                workEndContent
            }
        }
        .padding()
        .frame(width: 320)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 10)
        .onAppear {
            selectedProject = timer.boundProject
        }
    }

    @ViewBuilder
    private var breakEndContent: some View {
        Text("☕ Pause vorbei!")
            .font(.headline)
        Text("Bereit für die nächste Sitzung?")
            .font(.subheadline)
            .foregroundStyle(.secondary)

        HStack {
            Button("Nächste Sitzung") { onStartNextSession() }
                .buttonStyle(.borderedProminent)
            Button("Aufhören") { onStopCompletely() }
                .buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    private var workEndContent: some View {
        Text("✅ Sitzung beendet!")
            .font(.headline)

        // Project picker for standalone sessions
        if timer.boundProject == nil {
            Picker("Projekt", selection: $selectedProject) {
                Text("Ohne Projekt").tag(nil as Project?)
                ForEach(activeProjects) { project in
                    Label(project.name, systemImage: project.icon)
                        .tag(project as Project?)
                }
            }
        }

        // Status entry form
        VStack(alignment: .leading, spacing: 4) {
            Text("Wo stehst du gerade?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextEditor(text: $freeText)
                .font(.body)
                .frame(minHeight: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.3))
                )
        }

        DisclosureGroup("Optionale Felder", isExpanded: $showOptionalFields) {
            VStack(spacing: 8) {
                optionalField(label: "Letzter Schritt", text: $lastAction)
                optionalField(label: "Nächster Schritt", text: $nextStep)
                optionalField(label: "Offene Fragen", text: $openQuestions)
            }
            .padding(.top, 4)
        }

        HStack {
            Button("Speichern & Pause") { saveAndBreak() }
                .buttonStyle(.borderedProminent)
                .disabled(selectedProject == nil && timer.boundProject == nil)
            Button("Weiterarbeiten") { onContinueWorking() }
                .buttonStyle(.bordered)
        }
        HStack(spacing: 16) {
            Button("Überspringen") { onSkip() }
            Button("Aufhören") { onStopCompletely() }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .buttonStyle(.plain)
    }

    private func optionalField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(label, text: text)
                .textFieldStyle(.roundedBorder)
        }
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
        session.endedAt = Date()
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
