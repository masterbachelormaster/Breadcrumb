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
        self.createdAt = .now
    }

    var displayName: String {
        if let label, !label.isEmpty {
            return label
        }
        return originalFilename
    }

    // MARK: - Validation

    /// Checks whether type-appropriate fields are non-nil.
    /// A `.url` document must have a `urlString`; a `.file` document must have `bookmarkData`.
    var isValid: Bool {
        switch type {
        case .url:
            return urlString != nil
        case .file:
            return bookmarkData != nil
        }
    }

    // MARK: - Factory Methods

    /// Creates a validated `.url` document. Returns `nil` if `urlString` is empty.
    static func url(
        string urlString: String,
        label: String? = nil,
        originalFilename: String? = nil
    ) -> LinkedDocument? {
        guard !urlString.isEmpty else { return nil }
        let filename = originalFilename ?? URL(string: urlString)?.host() ?? urlString
        return LinkedDocument(
            type: .url,
            originalFilename: filename,
            urlString: urlString,
            label: label
        )
    }

    /// Creates a validated `.file` document. Returns `nil` if `bookmarkData` is empty.
    static func file(
        bookmark bookmarkData: Data,
        label: String? = nil,
        originalFilename: String
    ) -> LinkedDocument? {
        guard !bookmarkData.isEmpty else { return nil }
        return LinkedDocument(
            type: .file,
            originalFilename: originalFilename,
            bookmarkData: bookmarkData,
            label: label
        )
    }
}
