import SwiftUI

struct WatchInputView: View {
    @EnvironmentObject var viewModel: WatchChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var inputText = ""
    @State private var showQuickPrompts = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    TextField("質問を入力", text: $inputText, axis: .vertical)
                        .lineLimit(1...4)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)

                    // Quick prompt buttons
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 6) {
                        ForEach(AppConstants.quickPrompts, id: \.label) { prompt in
                            Button {
                                inputText = prompt.prompt
                            } label: {
                                VStack(spacing: 2) {
                                    Text(prompt.emoji)
                                        .font(.title3)
                                    Text(prompt.label)
                                        .font(.system(size: 10))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.bordered)
                            .tint(.cyan.opacity(0.8))
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle("質問")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("戻る") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        sendAndDismiss()
                    } label: {
                        Image(systemName: "paperplane.fill")
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                    .tint(.cyan)
                }
            }
        }
    }

    private func sendAndDismiss() {
        let text = inputText
        inputText = ""
        dismiss()
        Task {
            await viewModel.sendMessage(text)
        }
    }
}
