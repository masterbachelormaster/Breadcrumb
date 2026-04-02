import Testing
import Foundation
@testable import Breadcrumb

@Suite("PomodoroSession Tests")
struct PomodoroSessionTests {

    @Test("PomodoroSession initializes with correct defaults")
    func sessionDefaults() {
        let session = PomodoroSession(
            plannedDuration: 25 * 60,
            sessionType: .work,
            sessionNumber: 1
        )
        #expect(session.plannedDuration == 1500)
        #expect(session.sessionType == .work)
        #expect(session.sessionNumber == 1)
        #expect(session.completed == false)
        #expect(session.actualDuration == nil)
        #expect(session.endedAt == nil)
        #expect(session.project == nil)
    }

    @Test("PomodoroSession tracks all session types")
    func sessionTypes() {
        let work = PomodoroSession(plannedDuration: 1500, sessionType: .work, sessionNumber: 1)
        let shortBreak = PomodoroSession(plannedDuration: 300, sessionType: .shortBreak, sessionNumber: 1)
        let longBreak = PomodoroSession(plannedDuration: 900, sessionType: .longBreak, sessionNumber: 4)

        #expect(work.sessionType == .work)
        #expect(shortBreak.sessionType == .shortBreak)
        #expect(longBreak.sessionType == .longBreak)
    }
}
