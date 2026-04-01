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

    init(name: String, icon: String = "doc.text") {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.isActive = true
        self.createdAt = Date()
        self.entries = []
    }

    var latestEntry: StatusEntry? {
        entries.max(by: { $0.timestamp < $1.timestamp })
    }
}
