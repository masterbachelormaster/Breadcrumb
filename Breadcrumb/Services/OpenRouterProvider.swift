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
            throw AIServiceError.invalidResponse
        }

        guard let content = apiResponse.choices.first?.message.content else {
            throw AIServiceError.invalidResponse
        }

        guard let contentData = content.data(using: .utf8) else {
            throw AIServiceError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(ExtractedStatus.self, from: contentData)
        } catch {
            throw AIServiceError.invalidResponse
        }
    }

    private func jsonInstructions(_ language: AppLanguage) -> String {
        switch language {
        case .german:
            return """
                Antworte ausschliesslich mit einem JSON-Objekt mit diesen Feldern:
                {"lastAction": "...", "nextStep": "...", "openQuestions": "..."}
                Lass Felder leer ("") wenn nichts zutrifft.
                """
        case .english:
            return """
                Respond only with a JSON object with these fields:
                {"lastAction": "...", "nextStep": "...", "openQuestions": "..."}
                Leave fields empty ("") if nothing applies.
                """
        }
    }
}
