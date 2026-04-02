import Foundation
import SwiftData

enum SessionType: String, Codable {
    case work
    case shortBreak
    case longBreak
}

@Model
final class PomodoroSession {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var plannedDuration: TimeInterval
    var actualDuration: TimeInterval?
    var sessionType: SessionType
    var sessionNumber: Int
    var completed: Bool
    var project: Project?

    init(
        plannedDuration: TimeInterval,
        sessionType: SessionType,
        sessionNumber: Int
    ) {
        self.id = UUID()
        self.startedAt = Date()
        self.endedAt = nil
        self.plannedDuration = plannedDuration
        self.actualDuration = nil
        self.sessionType = sessionType
        self.sessionNumber = sessionNumber
        self.completed = false
    }
}
