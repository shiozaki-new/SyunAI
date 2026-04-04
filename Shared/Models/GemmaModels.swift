import Foundation

// MARK: - Google AI Studio (Gemini API) Request/Response Models

struct GemmaRequest: Codable {
    let contents: [GemmaContent]
    let systemInstruction: GemmaContent?
    let generationConfig: GenerationConfig?

    enum CodingKeys: String, CodingKey {
        case contents
        case systemInstruction = "system_instruction"
        case generationConfig
    }
}

struct GemmaContent: Codable {
    let role: String?
    let parts: [GemmaPart]
}

struct GemmaPart: Codable {
    let text: String
}

struct GenerationConfig: Codable {
    let maxOutputTokens: Int?
    let temperature: Double?

    enum CodingKeys: String, CodingKey {
        case maxOutputTokens
        case temperature
    }
}

// MARK: - Response

struct GemmaResponse: Codable {
    let candidates: [GemmaCandidate]?
    let error: GemmaError?
}

struct GemmaCandidate: Codable {
    let content: GemmaContent?
    let finishReason: String?
}

struct GemmaError: Codable {
    let code: Int?
    let message: String?
    let status: String?
}
