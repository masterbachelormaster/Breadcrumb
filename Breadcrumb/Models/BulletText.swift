import Foundation

/// Pure helpers for parsing and serializing bullet-list content stored as
/// newline-separated strings.
///
/// Convention: a `String?` field is "a list" if it contains one or more
/// `\n`. Each non-empty trimmed line is one bullet. There is no persisted
/// "is list?" flag — the mode is implicit from content.
enum BulletText {

    /// Splits a stored value into its bullet items. Filters out empty and
    /// whitespace-only lines, trims each surviving line. Use this for
    /// **display** contexts (history, detail views) where canonical,
    /// clean output is wanted.
    static func parse(_ value: String) -> [String] {
        value
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// Splits a stored value into its bullet items **without** trimming
    /// or filtering. Use this for **editing** contexts where mid-typing
    /// empty rows and trailing whitespace must be preserved so the cursor
    /// doesn't jump out from under the user.
    static func parseRaw(_ value: String) -> [String] {
        value
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
    }

    /// Joins bullet items into a single stored value. Inverse of `parse`
    /// for any input that came from `parse` (or any clean string-array).
    static func serialize(_ items: [String]) -> String {
        items.joined(separator: "\n")
    }
}
