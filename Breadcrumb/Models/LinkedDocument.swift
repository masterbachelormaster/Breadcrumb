import Foundation
import SwiftData

enum DocumentType: String, Codable {
    case file
    case url
}

@Model
final class LinkedDocument {
    var id: UUID
    var type: DocumentType
    var label: String?
    var urlString: String?
    var bookmarkData: Data?
    var originalFilename: String
    var createdAt: Date
    var project: Project?

    init(
        type: DocumentType,
        originalFilename: String,
        bookmarkData: Data? = nil,
        urlString: String? = nil,
        label: String? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.originalFilename = originalFilename
        self.bookmarkData = bookmarkData
        self.urlString = urlString
        self.label = label
        self.createdAt = Date()
    }

    var displayName: String {
        if let label, !label.isEmpty {
            return label
        }
        return originalFilename
    }
}
