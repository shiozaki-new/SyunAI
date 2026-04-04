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
                        Image(systemName: viewModel.isPhoneReachable ? "iphone.radiowaves.left.and.right" : "iphone.slash")
                            .foregroundColor(viewModel.isPhoneReachable ? .green : .red)
                        Text(viewModel.isPhoneReachable ? "iPhone 接続中" : "iPhone 未接続")
                            .font(.caption)
                    }
                    HStack {
                        Image(systemName: viewModel.isModelReady ? "brain" : "arrow.down.circle")
                            .foregroundColor(viewModel.isModelReady ? .green : .orange)
                        Text(viewModel.isModelReady ? "モデル準備完了" : "モデル未準備")
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
                        Text(AppConstants.appVersionDisplay)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Text("ローカル推論・無料版")
                        .font(.caption2)
                        .foregroundColor(.secondary)
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
