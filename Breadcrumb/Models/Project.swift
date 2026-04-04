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

    @Relationship(deleteRule: .cascade, inverse: \LinkedDocument.project)
    var linkedDocuments: [LinkedDocument] = []

    init(name: String, icon: String = "doc.text") {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.isActive = true
        self.createdAt = .now
        self.entries = []
        self.pomodoroSessions = []
        self.linkedDocuments = []
    }

    var latestEntry: StatusEntry? {
        entries.max(by: { $0.timestamp < $1.timestamp })
    }

    var completedPomodoroCount: Int {
        pomodoroSessions.count(where: { $0.sessionType == .work && $0.completed })
    }

    var totalFocusTime: TimeInterval {
        pomodoroSessions
            .filter { $0.sessionType == .work && $0.completed }
            .compactMap(\.actualDuration)
            .reduce(0, +)
    }
}

extension Project {
    func formattedFocusTime(_ l: AppLanguage) -> String {
        let totalMinutes = Int(totalFocusTime) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours) \(Strings.General.hoursAbbrev(l)) \(minutes) \(Strings.General.minutesAbbrev(l))"
        }
        return "\(minutes) \(Strings.General.minutesAbbrev(l))"
    }
}
