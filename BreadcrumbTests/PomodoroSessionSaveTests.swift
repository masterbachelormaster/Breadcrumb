import Testing
import Foundation
import SwiftData
@testable import Breadcrumb

@Suite("Pomodoro Session Save")
@MainActor
struct PomodoroSessionSaveTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Project.self, StatusEntry.self, PomodoroSession.self, LinkedDocument.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test("FocusMate Save & Done inserts exactly one PomodoroSession")
    func focusMateSaveAndDoneInsertsOnce() throws {
        let context = try makeContext()
        let project = Project(name: "Test")
        context.insert(project)

        // Mirrors PomodoroSessionEndView.saveAndDone(): one session construction,
        // one insert, one save. The post-save dismissal callback must not
        // create a second PomodoroSession.
        let session = PomodoroSession(
            plannedDuration: 1500,
            sessionType: .work,
            sessionNumber: 1
        )
        session.completed = true
        session.endedAt = .now
        session.actualDuration = 1500
        session.project = project
        session.isFocusMate = true
        context.insert(session)
        context.saveWithLogging()

        let sessions = try context.fetch(FetchDescriptor<PomodoroSession>())
        #expect(sessions.count == 1)
        #expect(sessions.first?.isFocusMate == true)
        #expect(sessions.first?.completed == true)
    }

    @Test("FocusMate Save & Done with status text also inserts exactly one session and one entry")
    func focusMateSaveAndDoneWithEntryInsertsOnce() throws {
        let context = try makeContext()
        let project = Project(name: "Test")
        context.insert(project)

        let session = PomodoroSession(
            plannedDuration: 1500,
            sessionType: .work,
            sessionNumber: 1
        )
        session.completed = true
        session.endedAt = .now
        session.actualDuration = 1500
        session.project = project
        session.isFocusMate = true

        let entry = StatusEntry(freeText: "Wrote intro")
        entry.project = project
        entry.pomodoroSession = session
        project.entries.append(entry)
        context.insert(entry)
        context.insert(session)
        context.saveWithLogging()

        let sessions = try context.fetch(FetchDescriptor<PomodoroSession>())
        let entries = try context.fetch(FetchDescriptor<StatusEntry>())
        #expect(sessions.count == 1)
        #expect(entries.count == 1)
        #expect(entries.first?.pomodoroSession?.id == sessions.first?.id)
    }
}
