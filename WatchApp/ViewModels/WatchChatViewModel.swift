import Foundation
import SwiftUI
import WatchKit

@MainActor
class WatchChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasAPIKey = false

    private let connectivityService = WatchConnectivityService.shared
    private let maxHistory = 10

    init() {
        loadMessages()
        checkAPIKey()
    }

    // MARK: - Send Message

    func sendMessage(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMessage = ChatMessage(content: trimmed, role: .user)
        messages.append(userMessage)
        isLoading = true
        errorMessage = nil

        do {
            let response = try await callAPI(userInput: trimmed)
            let assistantMessage = ChatMessage(content: response, role: .assistant)
            messages.append(assistantMessage)
            playHaptic()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
        saveMessages()
    }

    // MARK: - API Call

    private func callAPI(userInput: String) async throws -> String {
        guard let apiKey = KeychainService.getAPIKey() else {
            throw SyunAIError.noAPIKey
        }

        let model = UserDefaults.standard.string(forKey: AppConstants.selectedModelKey) ?? AppConstants.defaultModel
        let systemPrompt = UserDefaults.standard.string(forKey: AppConstants.systemPromptKey) ?? AppConstants.defaultSystemPrompt

        let urlString = "\(AppConstants.apiEndpoint)/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw SyunAIError.invalidURL
        }

        // Build conversation contents
        var contents: [GemmaContent] = []

        // Add recent history
        let recentMessages = messages.suffix(maxHistory).filter { $0.role != .system }
        for msg in recentMessages {
            contents.append(GemmaContent(
                role: msg.role == .user ? "user" : "model",
                parts: [GemmaPart(text: msg.content)]
            ))
        }

        // Add current user input
        contents.append(GemmaContent(
            role: "user",
            parts: [GemmaPart(text: userInput)]
        ))

        let systemInstruction = GemmaContent(
            role: nil,
            parts: [GemmaPart(text: systemPrompt)]
        )

        let request = GemmaRequest(
            contents: contents,
            systemInstruction: systemInstruction,
            generationConfig: GenerationConfig(
                maxOutputTokens: AppConstants.watchMaxTokens,
                temperature: 0.7
            )
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 15

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SyunAIError.networkError
        }

        switch httpResponse.statusCode {
        case 200:
            let gemmaResponse = try JSONDecoder().decode(GemmaResponse.self, from: data)
            if let text = gemmaResponse.candidates?.first?.content?.parts.first?.text {
                return text
            }
            throw SyunAIError.emptyResponse
        case 400:
            let errResp = try? JSONDecoder().decode(GemmaResponse.self, from: data)
            throw SyunAIError.apiError(errResp?.error?.message ?? "Bad Request")
        case 401, 403:
            throw SyunAIError.unauthorized
        case 429:
            throw SyunAIError.rateLimited
        default:
            throw SyunAIError.serverError(httpResponse.statusCode)
        }
    }

    // MARK: - Persistence

    func clearMessages() {
        messages.removeAll()
        saveMessages()
    }

    private func saveMessages() {
        if let data = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(data, forKey: "chat_messages")
        }
    }

    private func loadMessages() {
        guard let data = UserDefaults.standard.data(forKey: "chat_messages"),
              let saved = try? JSONDecoder().decode([ChatMessage].self, from: data) else { return }
        messages = saved
    }

    func checkAPIKey() {
        hasAPIKey = KeychainService.getAPIKey() != nil
    }

    // MARK: - Haptics

    private func playHaptic() {
        let enabled = UserDefaults.standard.bool(forKey: AppConstants.hapticEnabledKey)
        guard enabled else { return }
        WKInterfaceDevice.current().play(.success)
    }
}

// MARK: - Errors

enum SyunAIError: LocalizedError {
    case noAPIKey
    case invalidURL
    case networkError
    case emptyResponse
    case apiError(String)
    case unauthorized
    case rateLimited
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "APIキーが設定されていません。iPhoneアプリから設定してください。"
        case .invalidURL: return "無効なURLです。"
        case .networkError: return "ネットワークエラーです。"
        case .emptyResponse: return "応答が空です。"
        case .apiError(let msg): return "APIエラー: \(msg)"
        case .unauthorized: return "APIキーが無効です。"
        case .rateLimited: return "リクエスト制限に達しました。少し待ってください。"
        case .serverError(let code): return "サーバーエラー(\(code))"
        }
    }
}
