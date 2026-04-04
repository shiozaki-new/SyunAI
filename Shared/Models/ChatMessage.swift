import Foundation

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let role: MessageRole
    let timestamp: Date

    init(id: UUID = UUID(), content: String, role: MessageRole, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.role = role
        self.timestamp = timestamp
    }

    /// Convert to Google AI API message format
    var apiMessage: [String: Any] {
        return [
            "role": role == .user ? "user" : "model",
            "parts": [["text": content]]
        ]
    }
}

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}
