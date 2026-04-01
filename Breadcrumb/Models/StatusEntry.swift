import Foundation
import SwiftData

@Model
final class StatusEntry {
    var id: UUID
    var timestamp: Date
    var freeText: String
    var lastAction: String?
    var nextStep: String?
    var openQuestions: String?
    var project: Project?

    init(
        freeText: String,
        lastAction: String? = nil,
        nextStep: String? = nil,
        openQuestions: String? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.freeText = freeText
        self.lastAction = lastAction
        self.nextStep = nextStep
        self.openQuestions = openQuestions
    }
}
