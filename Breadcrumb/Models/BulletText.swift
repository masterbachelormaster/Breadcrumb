import Foundation

/// Pure helpers for parsing and serializing bullet-list content stored as
/// newline-separated strings.
///
/// Convention: a `String?` field is "a list" if it contains one or more
/// `\n`. Each non-empty trimmed line is one bullet. There is no persisted
/// "is list?" flag — the mode is implicit from content.
enum BulletText {

    /// Splits a stored value into its bullet items. Filters out empty and
    /// whitespace-only lines, trims each surviving line.
    static func parse(_ value: String) -> [String] {
        value
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// Joins bullet items into a single stored value. Inverse of `parse`
    /// for any input that came from `parse` (or any clean string-array).
    static func serialize(_ items: [String]) -> String {
        items.joined(separator: "\n")
    }
}
