import Foundation

struct OpenRouterProvider: AIProvider {
    let apiKey: String
    let model: String
    let customSystemPrompt: String?

    func extractStatus(from text: String, language: AppLanguage) async throws -> ExtractedStatus {
        let request = buildRequest(
            systemPrompt: systemPrompt(language: language),
            userMessage: text
        )

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AIServiceError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.networkError("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            throw Self.mapHTTPError(statusCode: httpResponse.statusCode, body: String(data: data, encoding: .utf8) ?? "")
        }

        return try parseResponse(data)
    }

    // MARK: - Internal (visible for testing)

    func systemPrompt(language: AppLanguage) -> String {
        let instructions = customSystemPrompt.flatMap({ $0.isEmpty ? nil : $0 })
            ?? Strings.AIExtraction.instructions(language)
        return instructions + "\n\n" + jsonWrapperInstructions(language)
    }

    func buildRequest(systemPrompt: String, userMessage: String) -> URLRequest {
        var request = URLRequest(url: URL(string: "https://openrouter.ai/api/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "response_format": ["type": "json_object"],
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userMessage],
            ],
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }

    static func mapHTTPError(statusCode: Int, body: String) -> AIServiceError {
        switch statusCode {
        case 401:
            return .authenticationFailed
        case 429:
            return .generationFailed("Rate limit exceeded")
        default:
            return .networkError("HTTP \(statusCode): \(body.prefix(200))")
        }
    }

    // MARK: - Private

    private func parseResponse(_ data: Data) throws -> ExtractedStatus {
        struct OpenRouterResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }

        let apiResponse: OpenRouterResponse
        do {
            apiResponse = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
        } catch {
            throw AIServiceError.invalidResponse("Could not decode OpenRouter wrapper: \(error.localizedDescription)")
        }

        guard let content = apiResponse.choices.first?.message.content else {
            throw AIServiceError.invalidResponse("No content in OpenRouter response")
        }

        return try Self.parseExtractedStatusContent(content)
    }

    static func parseExtractedStatusContent(_ content: String) throws -> ExtractedStatus {
        let cleaned = Self.extractJSONObject(from: content)

        guard let contentData = cleaned.data(using: .utf8) else {
            throw AIServiceError.invalidResponse("Content not UTF-8")
        }

        do {
            let payload = try JSONDecoder().decode(OpenRouterExtractionPayload.self, from: contentData)
            return ExtractedStatus(lastAction: payload.lastAction, nextStep: payload.nextAction)
        } catch {
            let snippet = String(content.prefix(200))
            throw AIServiceError.invalidResponse("Could not parse JSON. Got: \(snippet)")
        }
    }

    /// Extracts a JSON object from an LLM response that may contain markdown
    /// code fences or surrounding prose. Returns the cleaned string ready
    /// for `JSONDecoder`.
    static func extractJSONObject(from text: String) -> String {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Strip leading ```json or ``` fence
        if s.hasPrefix("```") {
            if let firstNewline = s.firstIndex(of: "\n") {
                s = String(s[s.index(after: firstNewline)...])
            }
        }

        // Strip trailing ``` fence
        if s.hasSuffix("```") {
            s = String(s.dropLast(3))
        }

        s = s.trimmingCharacters(in: .whitespacesAndNewlines)

        // If there's still prose around the JSON, extract from first { to matching last }
        if let firstBrace = s.firstIndex(of: "{"), let lastBrace = s.lastIndex(of: "}") {
            if firstBrace <= lastBrace {
                s = String(s[firstBrace...lastBrace])
            }
        }

        return s
    }

    private func jsonWrapperInstructions(_ language: AppLanguage) -> String {
        switch language {
        case .german:
            return """
                Technische Ausgabeanforderung: Gib das Ergebnis als JSON-Objekt mit den String-Feldern "lastAction" und "nextAction" zurück. Übernimm Inhalt, Bindestriche und Zeilenumbrüche aus den obigen Anweisungen unverändert in die jeweiligen JSON-Stringwerte. Gib keine zusätzlichen Felder oder Erklärungen aus.
                """
        case .english:
            return """
                Technical output requirement: Return the result as a JSON object with the string fields "lastAction" and "nextAction". Preserve the content, dashes, and line breaks requested above exactly inside the corresponding JSON string values. Do not add fields or explanations.
                """
        }
    }

    private struct OpenRouterExtractionPayload: Decodable {
        let lastAction: String
        let nextAction: String

        private enum CodingKeys: String, CodingKey {
            case lastAction
            case nextAction
            case nextStep
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            lastAction = try container.decode(String.self, forKey: .lastAction)
            if let nextAction = try container.decodeIfPresent(String.self, forKey: .nextAction) {
                self.nextAction = nextAction
            } else {
                self.nextAction = try container.decode(String.self, forKey: .nextStep)
            }
        }
    }
}
