import Testing
@testable import Breadcrumb

@Suite("BulletText Tests")
struct BulletTextTests {

    // MARK: - parse

    @Test("parse: empty string yields empty array")
    func parseEmpty() {
        #expect(BulletText.parse("") == [])
    }

    @Test("parse: plain string with no newlines yields one item")
    func parsePlain() {
        #expect(BulletText.parse("hello world") == ["hello world"])
    }

    @Test("parse: two non-empty lines yield two items")
    func parseTwoLines() {
        #expect(BulletText.parse("first\nsecond") == ["first", "second"])
    }

    @Test("parse: empty lines between items are filtered out")
    func parseFiltersBlankLines() {
        #expect(BulletText.parse("a\n\nb") == ["a", "b"])
    }

    @Test("parse: trailing newline does not produce phantom empty item")
    func parseTrailingNewline() {
        #expect(BulletText.parse("a\nb\n") == ["a", "b"])
    }

    @Test("parse: leading newline does not produce phantom empty item")
    func parseLeadingNewline() {
        #expect(BulletText.parse("\na\nb") == ["a", "b"])
    }

    @Test("parse: per-line whitespace is trimmed")
    func parseTrimsWhitespace() {
        #expect(BulletText.parse("  a  \n  b  ") == ["a", "b"])
    }

    @Test("parse: lines that become empty after trim are filtered out")
    func parseFiltersWhitespaceOnlyLines() {
        #expect(BulletText.parse("a\n   \nb") == ["a", "b"])
    }

    // MARK: - parseRaw

    @Test("parseRaw: preserves trailing empty line so list mode is sticky")
    func parseRawTrailing() {
        #expect(BulletText.parseRaw("a\n") == ["a", ""])
    }

    @Test("parseRaw: preserves trailing whitespace so the cursor does not jump")
    func parseRawTrailingWhitespace() {
        #expect(BulletText.parseRaw("a \nb") == ["a ", "b"])
    }

    @Test("parseRaw: preserves empty rows between items")
    func parseRawEmptyRows() {
        #expect(BulletText.parseRaw("a\n\nb") == ["a", "", "b"])
    }

    // MARK: - serialize

    @Test("serialize: empty array yields empty string")
    func serializeEmpty() {
        #expect(BulletText.serialize([]) == "")
    }

    @Test("serialize: single item yields plain string")
    func serializeSingle() {
        #expect(BulletText.serialize(["only"]) == "only")
    }

    @Test("serialize: multiple items joined with newlines")
    func serializeMultiple() {
        #expect(BulletText.serialize(["a", "b", "c"]) == "a\nb\nc")
    }

    // MARK: - round trip

    @Test("round trip: parse then serialize is idempotent for valid input")
    func roundTrip() {
        let input = "a\nb\nc"
        #expect(BulletText.serialize(BulletText.parse(input)) == "a\nb\nc")
    }
}
