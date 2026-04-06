import Testing
import Foundation
@testable import Breadcrumb

@Suite("OpenRouterProvider Tests")
struct OpenRouterProviderTests {

    @Test("Parses valid JSON response into ExtractedStatus")
    func parseValidJSON() throws {
        let json = """
        {
            "lastAction": "Wrote the introduction",
            "nextStep": "Add methodology section. Review references",
            "openQuestions": "Which framework to use?"
        }
        """
        let data = Data(json.utf8)
        let status = try JSONDecoder().decode(ExtractedStatus.self, from: data)
        #expect(status.lastAction == "Wrote the introduction")
        #expect(status.nextStep == "Add methodology section. Review references")
        #expect(status.openQuestions == "Which framework to use?")
    }

    @Test("Parses JSON with empty fields")
    func parseEmptyFields() throws {
        let json = """
        {
            "lastAction": "",
            "nextStep": "Start writing",
            "openQuestions": ""
        }
        """
        let data = Data(json.utf8)
        let status = try JSONDecoder().decode(ExtractedStatus.self, from: data)
        #expect(status.lastAction.isEmpty)
        #expect(status.nextStep == "Start writing")
        #expect(status.openQuestions.isEmpty)
    }

    @Test("buildRequest creates correct URLRequest")
    func buildRequest() throws {
        let provider = OpenRouterProvider(apiKey: "sk-test-123", model: "anthropic/claude-sonnet-4")
        let request = provider.buildRequest(
            systemPrompt: "You are a parser",
            userMessage: "I finished the intro"
        )
        #expect(request.url?.absoluteString == "https://openrouter.ai/api/v1/chat/completions")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-test-123")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.timeoutInterval == 30)

        let body = try JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
        #expect(body["model"] as? String == "anthropic/claude-sonnet-4")

        let responseFormat = body["response_format"] as! [String: String]
        #expect(responseFormat["type"] == "json_object")
    }

    @Test("mapHTTPError maps 401 to authenticationFailed")
    func map401() {
        let error = OpenRouterProvider.mapHTTPError(statusCode: 401, body: "")
        if case .authenticationFailed = error {
            // pass
        } else {
            Issue.record("Expected .authenticationFailed, got \(error)")
        }
    }

    @Test("mapHTTPError maps 429 to generationFailed")
    func map429() {
        let error = OpenRouterProvider.mapHTTPError(statusCode: 429, body: "")
        if case .generationFailed = error {
            // pass
        } else {
            Issue.record("Expected .generationFailed, got \(error)")
        }
    }

    @Test("mapHTTPError maps 500 to networkError")
    func map500() {
        let error = OpenRouterProvider.mapHTTPError(statusCode: 500, body: "")
        if case .networkError = error {
            // pass
        } else {
            Issue.record("Expected .networkError, got \(error)")
        }
    }
}
