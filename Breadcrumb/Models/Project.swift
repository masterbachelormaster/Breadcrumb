import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID
    var name: String
    var icon: String
    var isActive: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \StatusEntry.project)
    var entries: [StatusEntry]

    @Relationship(deleteRule: .cascade, inverse: \PomodoroSession.project)
    var pomodoroSessions: [PomodoroSession]

    init(name: String, icon: String = "doc.text") {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.isActive = true
        self.createdAt = Date()
        self.entries = []
        self.pomodoroSessions = []
    }

    var latestEntry: StatusEntry? {
        entries.max(by: { $0.timestamp < $1.timestamp })
    }

    var completedPomodoroCount: Int {
        pomodoroSessions.filter { $0.sessionType == .work && $0.completed }.count
    }

    var totalFocusTime: TimeInterval {
        pomodoroSessions
            .filter { $0.sessionType == .work && $0.completed }
            .compactMap(\.actualDuration)
            .reduce(0, +)
    }
}
