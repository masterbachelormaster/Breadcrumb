import Testing
@testable import Breadcrumb

@Suite("AIFillerStripper Tests")
struct AIFillerStripperTests {

    // MARK: - clean (single line) — preserves existing AIExtractButton.cleanFiller behavior

    @Test("clean: passes real content through unchanged")
    func cleanReal() {
        #expect(AIFillerStripper.clean("Reply to Stefan") == "Reply to Stefan")
    }

    @Test("clean: strips German filler 'leer'")
    func cleanLeer() {
        #expect(AIFillerStripper.clean("leer") == "")
    }

    @Test("clean: strips English filler 'nothing'")
    func cleanNothing() {
        #expect(AIFillerStripper.clean("nothing") == "")
    }

    @Test("clean: strips single dash")
    func cleanDash() {
        #expect(AIFillerStripper.clean("-") == "")
    }

    @Test("clean: strips 'no open questions' prefix variants")
    func cleanNoOpenQuestions() {
        #expect(AIFillerStripper.clean("no open questions at this time") == "")
    }

    @Test("clean: strips German 'nichts erledigt' prefix variants")
    func cleanNichtsErledigt() {
        #expect(AIFillerStripper.clean("nichts erledigt bisher") == "")
    }

    @Test("clean: trims surrounding whitespace from real content")
    func cleanTrimsWhitespace() {
        #expect(AIFillerStripper.clean("  hello  ") == "hello")
    }

    // MARK: - cleanLines (multi-line)

    @Test("cleanLines: empty string returns empty")
    func cleanLinesEmpty() {
        #expect(AIFillerStripper.cleanLines("") == "")
    }

    @Test("cleanLines: single non-filler line passes through")
    func cleanLinesSinglePass() {
        #expect(AIFillerStripper.cleanLines("real work") == "real work")
    }

    @Test("cleanLines: single filler line returns empty")
    func cleanLinesSingleFiller() {
        #expect(AIFillerStripper.cleanLines("leer") == "")
    }

    @Test("cleanLines: filler line in the middle is dropped, others preserved")
    func cleanLinesMixed() {
        #expect(AIFillerStripper.cleanLines("do A\nleer\ndo B") == "do A\ndo B")
    }

    @Test("cleanLines: all-filler multi-line returns empty")
    func cleanLinesAllFiller() {
        #expect(AIFillerStripper.cleanLines("leer\nnothing") == "")
    }

    @Test("cleanLines: non-filler multi-line preserved verbatim")
    func cleanLinesAllReal() {
        #expect(AIFillerStripper.cleanLines("a\nb\nc") == "a\nb\nc")
    }

    @Test("cleanLines: per-line whitespace is trimmed")
    func cleanLinesTrim() {
        #expect(AIFillerStripper.cleanLines("  a  \n  b  ") == "a\nb")
    }

    // MARK: - False positive protection: real text must survive

    @Test("clean: preserves 'pending review from Sarah'")
    func preservePendingReview() {
        #expect(AIFillerStripper.clean("pending review from Sarah") == "pending review from Sarah")
    }

    @Test("clean: preserves sentence starting with 'no progress' followed by context")
    func preserveNoProgressWithContext() {
        let real = "no progress on API yet, blocked by auth"
        #expect(AIFillerStripper.clean(real) == real)
    }

    @Test("clean: preserves sentence starting with 'nothing completed' followed by reason")
    func preserveNothingCompletedWithReason() {
        let real = "nothing completed because the server was down"
        #expect(AIFillerStripper.clean(real) == real)
    }

    @Test("clean: preserves sentence starting with 'nothing planned' followed by qualifier")
    func preserveNothingPlannedWithQualifier() {
        let real = "nothing planned until Monday meeting"
        #expect(AIFillerStripper.clean(real) == real)
    }

    @Test("clean: preserves German 'noch nichts von Sarah gehört'")
    func preserveNochNichtsVon() {
        let real = "noch nichts von Sarah gehört"
        #expect(AIFillerStripper.clean(real) == real)
    }

    @Test("clean: preserves German 'nichts weiter als den Entwurf geschrieben'")
    func preserveNichtsWeiterAls() {
        let real = "nichts weiter als den Entwurf geschrieben"
        #expect(AIFillerStripper.clean(real) == real)
    }

    @Test("clean: preserves 'nothing has been merged yet'")
    func preserveNothingHasBeenMerged() {
        let real = "nothing has been merged yet, PR still open"
        #expect(AIFillerStripper.clean(real) == real)
    }

    // MARK: - Standalone filler still stripped after prefix removal

    @Test("clean: still strips standalone 'no progress'")
    func stillStripsNoProgress() {
        #expect(AIFillerStripper.clean("no progress") == "")
    }

    @Test("clean: still strips standalone 'nothing completed'")
    func stillStripsNothingCompleted() {
        #expect(AIFillerStripper.clean("nothing completed") == "")
    }

    @Test("clean: still strips standalone 'nothing planned'")
    func stillStripsNothingPlanned() {
        #expect(AIFillerStripper.clean("nothing planned") == "")
    }

    @Test("clean: still strips standalone 'noch nichts'")
    func stillStripsNochNichts() {
        #expect(AIFillerStripper.clean("noch nichts") == "")
    }

    @Test("clean: still strips standalone 'nichts erledigt'")
    func stillStripsNichtsErledigt() {
        #expect(AIFillerStripper.clean("nichts erledigt") == "")
    }
}
