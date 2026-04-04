import SwiftUI

struct WatchSettingsView: View {
    @EnvironmentObject var viewModel: WatchChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showClearConfirm = false

    var body: some View {
        NavigationStack {
            List {
                Section("接続状態") {
                    HStack {
                        Image(systemName: viewModel.hasAPIKey ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(viewModel.hasAPIKey ? .green : .red)
                        Text(viewModel.hasAPIKey ? "APIキー設定済" : "未設定")
                            .font(.caption)
                    }
                }

                Section("会話") {
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label("会話をクリア", systemImage: "trash")
                            .font(.caption)
                    }
                }

                Section {
                    HStack {
                        Text("瞬愛 SyunAI")
                            .font(.caption2)
                        Spacer()
                        Text("v1.0.0")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .alert("会話をクリア", isPresented: $showClearConfirm) {
                Button("クリア", role: .destructive) { viewModel.clearMessages() }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("すべての会話履歴が削除されます。")
            }
        }
    }
}
