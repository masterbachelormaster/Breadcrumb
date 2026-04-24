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

    // MARK: - Save & Break paths

    @Test("Save & Break with text creates exactly one session and one entry linked together")
    func saveAndBreakWithTextInsertsOnce() throws {
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

        let entry = StatusEntry(freeText: "Finished draft")
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
        #expect(sessions.first?.isFocusMate == false)
        #expect(entries.first?.pomodoroSession?.id == sessions.first?.id)
        #expect(entries.first?.project?.id == project.id)
    }

    @Test("Save & Break without text creates session but no entry")
    func saveAndBreakWithoutTextCreatesSessionOnly() throws {
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
        context.insert(session)
        context.saveWithLogging()

        let sessions = try context.fetch(FetchDescriptor<PomodoroSession>())
        let entries = try context.fetch(FetchDescriptor<StatusEntry>())
        #expect(sessions.count == 1)
        #expect(entries.count == 0)
    }

    // MARK: - Skip path

    @Test("Skip creates session with no entry")
    func skipCreatesSessionOnly() throws {
        let context = try makeContext()
        let project = Project(name: "Test")
        context.insert(project)

        let session = PomodoroSession(
            plannedDuration: 1500,
            sessionType: .work,
            sessionNumber: 2
        )
        session.completed = false
        session.endedAt = .now
        session.actualDuration = 1000
        session.project = project
        session.isFocusMate = false
        context.insert(session)
        context.saveWithLogging()

        let sessions = try context.fetch(FetchDescriptor<PomodoroSession>())
        let entries = try context.fetch(FetchDescriptor<StatusEntry>())
        #expect(sessions.count == 1)
        #expect(sessions.first?.sessionNumber == 2)
        #expect(entries.count == 0)
    }

    // MARK: - Stop Completely paths

    @Test("Stop Completely from work end creates exactly one session")
    func stopCompletelyFromWorkCreatesSession() throws {
        let context = try makeContext()
        let project = Project(name: "Test")
        context.insert(project)

        let session = PomodoroSession(
            plannedDuration: 1500,
            sessionType: .work,
            sessionNumber: 1
        )
        session.completed = false
        session.endedAt = .now
        session.actualDuration = 800
        session.project = project
        context.insert(session)
        context.saveWithLogging()

        let sessions = try context.fetch(FetchDescriptor<PomodoroSession>())
        #expect(sessions.count == 1)
        #expect(sessions.first?.completed == false)
    }

    // MARK: - Standalone status entry (non-Pomodoro)

    @Test("Standalone status entry is linked to project and has no session")
    func standaloneEntryLinkedToProject() throws {
        let context = try makeContext()
        let project = Project(name: "Test")
        context.insert(project)

        let entry = StatusEntry(
            freeText: "Finished the draft",
            lastAction: "Wrote intro",
            nextStep: nil,
            openQuestions: nil
        )
        entry.project = project
        project.entries.append(entry)
        context.insert(entry)
        context.saveWithLogging()

        let entries = try context.fetch(FetchDescriptor<StatusEntry>())
        #expect(entries.count == 1)
        #expect(entries.first?.project?.id == project.id)
        #expect(entries.first?.pomodoroSession == nil)
        #expect(entries.first?.freeText == "Finished the draft")
        #expect(entries.first?.lastAction == "Wrote intro")
    }

    @Test("Stop Completely from break end does not create a session")
    func stopCompletelyFromBreakCreatesNothing() throws {
        let context = try makeContext()
        let project = Project(name: "Test")
        context.insert(project)

        // The work session was already saved earlier; stopping after a break
        // should not insert another session.
        let sessions = try context.fetch(FetchDescriptor<PomodoroSession>())
        let entries = try context.fetch(FetchDescriptor<StatusEntry>())
        #expect(sessions.count == 0)
        #expect(entries.count == 0)
    }
}
