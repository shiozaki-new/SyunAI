import Foundation
import SwiftUI
import WatchKit

@MainActor
class WatchChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isModelReady = false
    @Published var isPhoneReachable = false

    private let connectivityService = WatchConnectivityService.shared

    init() {
        loadMessages()
        checkModelStatus()

        // Observe connectivity changes
        connectivityService.onModelStatusUpdate = { [weak self] ready in
            Task { @MainActor in
                self?.isModelReady = ready
            }
        }
        connectivityService.onReachabilityChange = { [weak self] reachable in
            Task { @MainActor in
                self?.isPhoneReachable = reachable
            }
        }
    }

    // MARK: - Send Message

    func sendMessage(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let userMessage = ChatMessage(content: trimmed, role: .user)
        messages.append(userMessage)
        isLoading = true
        errorMessage = nil

        // Try local utility first (date, calculation, etc.)
        if let localResult = LocalUtility.tryHandle(trimmed) {
            let assistantMessage = ChatMessage(content: localResult, role: .assistant)
            messages.append(assistantMessage)
            isLoading = false
            playHaptic()
            saveMessages()
            return
        }

        // Relay to iPhone for LLM inference
        do {
            let response = try await requestInference(userInput: trimmed)
            let assistantMessage = ChatMessage(content: response, role: .assistant)
            messages.append(assistantMessage)
            playHaptic()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
        saveMessages()
    }

    // MARK: - iPhone Inference Relay

    private func requestInference(userInput: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            connectivityService.sendInferenceRequest(userInput) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Model Status

    func checkModelStatus() {
        isPhoneReachable = connectivityService.isReachable
        connectivityService.requestModelStatus { [weak self] ready in
            Task { @MainActor in
                self?.isModelReady = ready
            }
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

    // MARK: - Haptics

    private func playHaptic() {
        let enabled = UserDefaults.standard.bool(forKey: AppConstants.hapticEnabledKey)
        guard enabled else { return }
        WKInterfaceDevice.current().play(.success)
    }
}

// MARK: - Errors

enum SyunAIError: LocalizedError {
    case phoneNotReachable
    case modelNotReady
    case inferenceTimeout
    case inferenceError(String)

    var errorDescription: String? {
        switch self {
        case .phoneNotReachable: return "iPhoneに接続できません。近くにiPhoneがあるか確認してください。"
        case .modelNotReady: return "モデルが準備されていません。iPhoneアプリでモデルをダウンロードしてください。"
        case .inferenceTimeout: return "応答がタイムアウトしました。"
        case .inferenceError(let msg): return msg
        }
    }
}
