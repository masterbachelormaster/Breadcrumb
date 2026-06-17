import Testing
@testable import Breadcrumb

@Suite("AI extraction prompt format")
struct AIExtractionPromptTests {

    @Test("Next-step instructions request one item per line, not \". \" joining")
    func nextStepUsesLines() {
        let prompt = Strings.AIExtraction.nextStepInstructions(.english)
        #expect(prompt.contains("per line"))
        #expect(prompt.contains("Separate items") == false)
    }

    @Test("Last-action instructions request one item per line, not \". \" joining")
    func lastActionUsesLines() {
        let prompt = Strings.AIExtraction.lastActionInstructions(.english)
        #expect(prompt.contains("per line"))
        #expect(prompt.contains("Separate items") == false)
    }
}
