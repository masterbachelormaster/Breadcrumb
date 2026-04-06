import Testing
@testable import Breadcrumb

@Suite("AIProvider Types Tests")
struct AIProviderTypesTests {

    @Test("ExtractedStatus initializes with correct values")
    func extractedStatusInit() {
        let status = ExtractedStatus(
            lastAction: "Wrote intro",
            nextStep: "Add data section",
            openQuestions: "Which dataset?"
        )
        #expect(status.lastAction == "Wrote intro")
        #expect(status.nextStep == "Add data section")
        #expect(status.openQuestions == "Which dataset?")
    }

    @Test("ExtractedStatus supports empty fields")
    func extractedStatusEmpty() {
        let status = ExtractedStatus(lastAction: "", nextStep: "", openQuestions: "")
        #expect(status.lastAction.isEmpty)
        #expect(status.nextStep.isEmpty)
        #expect(status.openQuestions.isEmpty)
    }

    @Test("AIBackend raw values match UserDefaults keys")
    func aiBackendRawValues() {
        #expect(AIBackend.local.rawValue == "local")
        #expect(AIBackend.openRouter.rawValue == "openRouter")
    }

    @Test("AIBackend has all expected cases")
    func aiBackendCases() {
        let allCases = AIBackend.allCases
        #expect(allCases.count == 2)
        #expect(allCases.contains(.local))
        #expect(allCases.contains(.openRouter))
    }
}
