import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var viewModel: WatchChatViewModel
    @State private var showInput = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if !viewModel.isPhoneReachable {
                    phoneNotConnectedView
                } else if !viewModel.isModelReady {
                    modelNotReadyView
                } else if viewModel.messages.isEmpty {
                    emptyStateView
                } else {
                    chatListView
                }
            }
            .navigationTitle("瞬愛")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .font(.caption)
                    }
                }
            }
            .sheet(isPresented: $showInput) {
                WatchInputView()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showSettings) {
                WatchSettingsView()
                    .environmentObject(viewModel)
            }
            .onAppear {
                viewModel.checkModelStatus()
            }
        }
    }

    // MARK: - Phone Not Connected

    private var phoneNotConnectedView: some View {
        VStack(spacing: 8) {
            Image(systemName: "iphone.slash")
                .font(.title2)
                .foregroundColor(.orange)
            Text("iPhoneに\n接続してください")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    // MARK: - Model Not Ready

    private var modelNotReadyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.down.circle")
                .font(.title2)
                .foregroundColor(.orange)
            Text("iPhoneアプリで\nモデルを準備")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title)
                .foregroundColor(.cyan)
            Text("聞いてみよう")
                .font(.headline)
            Button {
                showInput = true
            } label: {
                Label("質問する", systemImage: "mic.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
        }
    }

    // MARK: - Chat List

    private var chatListView: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(viewModel.messages) { message in
                            WatchMessageBubble(message: message)
                                .id(message.id)
                        }
                        if viewModel.isLoading {
                            HStack {
                                ProgressView()
                                    .tint(.cyan)
                                Text("考え中...")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .id("loading")
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    withAnimation {
                        if let lastId = viewModel.messages.last?.id {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }

            // Input button at bottom
            Button {
                showInput = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("質問")
                        .font(.footnote)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
            .padding(.vertical, 4)
        }
        .alert("エラー", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
