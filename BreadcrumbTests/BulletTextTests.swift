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

    // MARK: - joinInline

    @Test("joinInline: empty string yields empty string")
    func joinInlineEmpty() {
        #expect(BulletText.joinInline("") == "")
    }

    @Test("joinInline: single item without trailing punctuation is unchanged")
    func joinInlineSingle() {
        #expect(BulletText.joinInline("hello world") == "hello world")
    }

    @Test("joinInline: single item with trailing period is stripped")
    func joinInlineSingleTrimsTrailingPeriod() {
        #expect(BulletText.joinInline("hello.") == "hello")
    }

    @Test("joinInline: two clean items are joined with period-space")
    func joinInlineTwoItems() {
        #expect(BulletText.joinInline("first\nsecond") == "first. second")
    }

    @Test("joinInline: trailing periods are stripped before joining")
    func joinInlineStripsTrailingPeriods() {
        #expect(BulletText.joinInline("do A.\ndo B.") == "do A. do B")
    }

    @Test("joinInline: trailing exclamation and question marks are stripped")
    func joinInlineStripsOtherTerminators() {
        #expect(BulletText.joinInline("wow!\nreally?") == "wow. really")
    }

    @Test("joinInline: multiple trailing terminators are all stripped")
    func joinInlineStripsRepeatedTerminators() {
        #expect(BulletText.joinInline("wow!!!\nok") == "wow. ok")
    }

    @Test("joinInline: leading punctuation is preserved")
    func joinInlinePreservesLeadingPunctuation() {
        #expect(BulletText.joinInline(".NET\nRuby") == ".NET. Ruby")
    }

    @Test("joinInline: whitespace-only lines are filtered out")
    func joinInlineFiltersBlankLines() {
        #expect(BulletText.joinInline("a\n   \nb") == "a. b")
    }

    @Test("joinInline: items that become empty after stripping are filtered")
    func joinInlineFiltersItemsEmptyAfterStrip() {
        #expect(BulletText.joinInline("a\n...\nb") == "a. b")
    }

    @Test("joinInline: is lossy — parse(joinInline(x)) is not a round trip")
    func joinInlineIsLossy() {
        // Documenting the intended lossiness: the newline structure is
        // collapsed into one item, not recovered.
        let original = "do A.\ndo B."
        let collapsed = BulletText.joinInline(original)
        let reparsed = BulletText.parse(collapsed)
        #expect(reparsed == ["do A. do B"])
    }
}
