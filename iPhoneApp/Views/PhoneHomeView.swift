import SwiftUI

struct PhoneHomeView: View {
    @EnvironmentObject var connectivity: PhoneConnectivityService
    @EnvironmentObject var modelManager: ModelManager
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: AppConstants.onboardingCompletedKey)

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Watch Status
                Section {
                    HStack {
                        Image(systemName: connectivity.isWatchReachable ? "applewatch.radiowaves.left.and.right" : "applewatch.slash")
                            .foregroundColor(connectivity.isWatchReachable ? .green : .gray)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(connectivity.isWatchReachable ? "Apple Watch 接続中" : "Apple Watch 未接続")
                                .font(.subheadline.bold())
                            if connectivity.isWatchAppInstalled {
                                Text("瞬愛 Watch アプリ検出済み")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("接続状態")
                }

                // MARK: - Model Status
                Section {
                    if modelManager.isModelReady {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("モデル準備完了")
                                    .font(.subheadline.bold())
                                Text(AppConstants.modelDisplayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "brain")
                                .foregroundColor(.cyan)
                        }

                        Button("モデルを削除", role: .destructive) {
                            modelManager.deleteModel()
                            LocalLLMService.shared.unloadModel()
                        }
                        .font(.caption)
                    } else if modelManager.isDownloading {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("モデルダウンロード中...")
                                    .font(.subheadline.bold())
                                Spacer()
                                Text(modelManager.downloadedSizeText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            ProgressView(value: modelManager.downloadProgress)
                                .tint(.cyan)
                            Text("\(Int(modelManager.downloadProgress * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Button("キャンセル", role: .destructive) {
                                modelManager.cancelDownload()
                            }
                            .font(.caption)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "arrow.down.circle")
                                    .foregroundColor(.orange)
                                Text("モデル未準備")
                                    .font(.subheadline.bold())
                            }
                            Text("初回のみモデルのダウンロードが必要です（\(AppConstants.modelSizeDescription)）。Wi-Fi推奨。")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Button {
                                modelManager.startDownload()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.down.to.line")
                                    Text("モデルをダウンロード")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.cyan)
                        }
                    }

                    if let error = modelManager.error {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                } header: {
                    Text("AIモデル（ローカル）")
                } footer: {
                    Text("推論はすべて iPhone 上で実行されます。APIキーや課金は不要です。")
                }

                // MARK: - How It Works
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        stepRow(number: 1, text: "「モデルをダウンロード」をタップ（初回のみ）")
                        stepRow(number: 2, text: "ダウンロード完了を待つ")
                        stepRow(number: 3, text: "Apple Watch で瞬愛を起動して質問")
                        stepRow(number: 4, text: "iPhone がローカルで回答を生成")
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("使い方")
                }

                // MARK: - Info
                Section {
                    HStack {
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.secondary)
                        Text("推論時にネットワーク通信なし")
                            .font(.caption)
                    }
                    HStack {
                        Image(systemName: "yensign.circle")
                            .foregroundColor(.secondary)
                        Text("課金・APIキー不要")
                            .font(.caption)
                    }
                    HStack {
                        Image(systemName: "brain")
                            .foregroundColor(.secondary)
                        Text(AppConstants.modelDisplayName)
                            .font(.caption)
                    }
                } header: {
                    Text("v2 無料運用版")
                }
            }
            .navigationTitle("瞬愛 SyunAI")
            .sheet(isPresented: $showOnboarding) {
                OnboardingView(isPresented: $showOnboarding)
            }
            .onAppear {
                // Auto-load model if already downloaded
                if modelManager.modelFileExists && !LocalLLMService.shared.isModelLoaded {
                    Task {
                        do {
                            try await modelManager.loadModelIntoService()
                            connectivity.sendModelStatusToWatch(isReady: true)
                        } catch {
                            connectivity.sendModelStatusToWatch(isReady: false)
                        }
                    }
                }
            }
            .onChange(of: modelManager.isModelReady) { _, isReady in
                connectivity.sendModelStatusToWatch(isReady: isReady)
            }
        }
    }

    // MARK: - Helpers

    private func stepRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.caption.bold())
                .frame(width: 22, height: 22)
                .background(Circle().fill(.cyan.opacity(0.2)))
            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Onboarding

struct OnboardingView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.cyan)

            Text("瞬愛 SyunAI \(AppConstants.appVersionDisplay)")
                .font(.largeTitle.bold())

            Text("Apple Watchで\n瞬時にAIに聞ける\n完全ローカル・無料")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "bolt.fill", title: "即起動", description: "手首を上げてすぐ質問")
                featureRow(icon: "brain", title: "ローカル推論", description: "APIキー不要・課金なし")
                featureRow(icon: "wifi.slash", title: "オフライン対応", description: "ネットワーク不要で推論")
                featureRow(icon: "person.2.fill", title: "配布可能", description: "友達にそのまま共有")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                UserDefaults.standard.set(true, forKey: AppConstants.onboardingCompletedKey)
                isPresented = false
            } label: {
                Text("はじめる")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.cyan)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.cyan)
                .frame(width: 36)
            VStack(alignment: .leading) {
                Text(title).font(.subheadline.bold())
                Text(description).font(.caption).foregroundColor(.secondary)
            }
        }
    }
}
