import SwiftUI

struct WatchMessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 20) }

            Text(message.content)
                .font(.system(size: 13))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(backgroundColor)
                .foregroundColor(.white)
                .cornerRadius(10)
                .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .assistant { Spacer(minLength: 20) }
        }
    }

    private var backgroundColor: Color {
        message.role == .user ? .cyan.opacity(0.7) : .gray.opacity(0.4)
    }
}
