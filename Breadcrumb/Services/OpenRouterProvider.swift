import Foundation

struct OpenRouterProvider: AIProvider {
    let apiKey: String
    let model: String

    func extractStatus(from text: String, language: AppLanguage) async throws -> ExtractedStatus {
        let systemPrompt = Strings.AIExtraction.instructions(language) + "\n\n" + jsonInstructions(language)
        let request = buildRequest(systemPrompt: systemPrompt, userMessage: text)

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

        let cleaned = Self.extractJSONObject(from: content)

        guard let contentData = cleaned.data(using: .utf8) else {
            throw AIServiceError.invalidResponse("Content not UTF-8")
        }

        do {
            return try JSONDecoder().decode(ExtractedStatus.self, from: contentData)
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

    private func jsonInstructions(_ language: AppLanguage) -> String {
        switch language {
        case .german:
            return """
                Antworte ausschliesslich mit einem JSON-Objekt mit diesen Feldern:
                {"lastAction": "erster punkt\\nzweiter punkt", "nextStep": "naechster schritt", "openQuestions": ""}
                Mehrere Punkte pro Feld mit Zeilenumbruch trennen. Lass Felder leer ("") wenn nichts zutrifft.
                """
        case .english:
            return """
                Respond only with a JSON object with these fields:
                {"lastAction": "first item\\nsecond item", "nextStep": "next step", "openQuestions": ""}
                Separate multiple items per field with newlines. Leave fields empty ("") if nothing applies.
                """
        }
    }
}
