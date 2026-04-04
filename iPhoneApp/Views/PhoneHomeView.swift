import SwiftUI

struct PhoneHomeView: View {
    @EnvironmentObject var connectivity: PhoneConnectivityService
    @State private var apiKey = ""
    @State private var savedKey: String?
    @State private var selectedModel = AppConstants.defaultModel
    @State private var isSyncing = false
    @State private var syncSuccess = false
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: AppConstants.onboardingCompletedKey)
    @State private var validationState: ValidationState = .idle
    @State private var showAlert = false
    @State private var alertMessage = ""

    enum ValidationState {
        case idle, validating, valid, invalid(String)
    }

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

                // MARK: - API Key
                Section {
                    if let key = savedKey {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)
                            Text("APIキー設定済み")
                            Spacer()
                            Text("...\(String(key.suffix(8)))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Button("APIキーを変更", role: .destructive) {
                            savedKey = nil
                            apiKey = ""
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Google AI Studio APIキー")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            SecureField("APIキーを入力", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)

                            HStack {
                                Button {
                                    Task { await validateAndSaveKey() }
                                } label: {
                                    HStack {
                                        if case .validating = validationState {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        }
                                        Text("検証して保存")
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.cyan)
                                .disabled(apiKey.isEmpty || isValidating)

                                Spacer()

                                Link(destination: URL(string: "https://aistudio.google.com/apikey")!) {
                                    Label("キー取得", systemImage: "arrow.up.right.square")
                                        .font(.caption)
                                }
                            }

                            if case .invalid(let msg) = validationState {
                                Text(msg)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                } header: {
                    Text("APIキー")
                } footer: {
                    Text("Google AI Studio から無料のAPIキーを取得できます。Gemma モデルを使用します。")
                }

                // MARK: - Model Selection
                Section {
                    Picker("モデル", selection: $selectedModel) {
                        ForEach(AppConstants.availableModels, id: \.id) { model in
                            VStack(alignment: .leading) {
                                Text(model.name)
                                Text(model.description)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .tag(model.id)
                        }
                    }
                    .onChange(of: selectedModel) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: AppConstants.selectedModelKey)
                    }
                } header: {
                    Text("AIモデル")
                }

                // MARK: - Sync
                Section {
                    Button {
                        syncToWatch()
                    } label: {
                        HStack {
                            Image(systemName: syncSuccess ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                                .foregroundColor(syncSuccess ? .green : .cyan)
                            Text(syncSuccess ? "同期完了" : "Watchに設定を送信")
                            if isSyncing {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(savedKey == nil || isSyncing)
                } header: {
                    Text("同期")
                } footer: {
                    Text("APIキーとモデル設定をApple Watchに送信します。")
                }

                // MARK: - How to Use
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        stepRow(number: 1, text: "上のリンクからGoogle AI StudioのAPIキーを取得")
                        stepRow(number: 2, text: "APIキーを入力して「検証して保存」をタップ")
                        stepRow(number: 3, text: "「Watchに設定を送信」をタップ")
                        stepRow(number: 4, text: "Apple Watchで瞬愛を起動して質問")
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("使い方")
                }
            }
            .navigationTitle("瞬愛 SyunAI")
            .onAppear {
                loadSavedKey()
                selectedModel = UserDefaults.standard.string(forKey: AppConstants.selectedModelKey) ?? AppConstants.defaultModel
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingView(isPresented: $showOnboarding)
            }
            .alert("エラー", isPresented: $showAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - Helpers

    private var isValidating: Bool {
        if case .validating = validationState { return true }
        return false
    }

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

    private func loadSavedKey() {
        savedKey = PhoneKeychainService.getAPIKey()
    }

    private func validateAndSaveKey() async {
        validationState = .validating
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        // Quick validation via API call
        let urlString = "\(AppConstants.apiEndpoint)/\(AppConstants.defaultModel):generateContent?key=\(key)"
        guard let url = URL(string: urlString) else {
            validationState = .invalid("無効なキー形式です。")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10

        let body = GemmaRequest(
            contents: [GemmaContent(role: "user", parts: [GemmaPart(text: "Hi")])],
            systemInstruction: nil,
            generationConfig: GenerationConfig(maxOutputTokens: 5, temperature: 0.1)
        )

        do {
            request.httpBody = try JSONEncoder().encode(body)
            let (data, response) = try await URLSession.shared.data(for: request)
            let httpResp = response as? HTTPURLResponse

            switch httpResp?.statusCode {
            case 200:
                _ = PhoneKeychainService.saveAPIKey(key)
                savedKey = key
                apiKey = ""
                validationState = .valid
            case 400:
                // API key is valid but request might be malformed - still save
                let errResp = try? JSONDecoder().decode(GemmaResponse.self, from: data)
                if errResp?.error?.message?.contains("API key") == true {
                    validationState = .invalid("APIキーが無効です。")
                } else {
                    _ = PhoneKeychainService.saveAPIKey(key)
                    savedKey = key
                    apiKey = ""
                    validationState = .valid
                }
            case 401, 403:
                validationState = .invalid("APIキーが無効です。正しいキーを入力してください。")
            default:
                validationState = .invalid("検証に失敗しました (HTTP \(httpResp?.statusCode ?? 0))")
            }
        } catch {
            validationState = .invalid("ネットワークエラー: \(error.localizedDescription)")
        }
    }

    private func syncToWatch() {
        guard let key = savedKey else { return }
        isSyncing = true
        syncSuccess = false

        connectivity.sendSettingsToWatch(
            apiKey: key,
            model: selectedModel,
            systemPrompt: UserDefaults.standard.string(forKey: AppConstants.systemPromptKey) ?? AppConstants.defaultSystemPrompt
        )

        // Visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSyncing = false
            syncSuccess = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                syncSuccess = false
            }
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

            Text("瞬愛 SyunAI")
                .font(.largeTitle.bold())

            Text("Apple Watchで\n瞬時にAIに聞ける")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "bolt.fill", title: "即起動", description: "手首を上げてすぐ質問")
                featureRow(icon: "character.textbox", title: "漢字・スペル", description: "読みやスペルを瞬時に確認")
                featureRow(icon: "globe", title: "翻訳・計算", description: "ちょっとした調べものに")
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
