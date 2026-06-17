import Testing
@testable import Breadcrumb

@Suite("AI extraction prompt format")
struct AIExtractionPromptTests {

    @Test("Next-step instructions request one item per line, not \". \" joining",
          arguments: [AppLanguage.german, AppLanguage.english])
    func nextStepUsesLines(_ language: AppLanguage) {
        let prompt = Strings.AIExtraction.nextStepInstructions(language)
        #expect(prompt.contains("per line"))
        #expect(!prompt.contains("Separate items"))
    }

    @Test("Last-step instructions request one item per line, not \". \" joining",
          arguments: [AppLanguage.german, AppLanguage.english])
    func lastActionUsesLines(_ language: AppLanguage) {
        let prompt = Strings.AIExtraction.lastActionInstructions(language)
        #expect(prompt.contains("per line"))
        #expect(!prompt.contains("Separate items"))
    }
}
