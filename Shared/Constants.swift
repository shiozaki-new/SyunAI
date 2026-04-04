import Foundation

enum AppConstants {
    // MARK: - API Configuration
    // Google AI Studio (Gemini API) - supports Gemma models
    static let apiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models"
    static let defaultModel = "gemma-3-4b-it"

    static let availableModels: [(id: String, name: String, description: String)] = [
        ("gemma-3-4b-it", "Gemma 3 4B", "高速・軽量"),
        ("gemma-3-12b-it", "Gemma 3 12B", "バランス型"),
        ("gemma-3-27b-it", "Gemma 3 27B", "高精度")
    ]

    // MARK: - System Prompt
    static let defaultSystemPrompt = """
    あなたはApple Watchで使われる即応AIアシスタント「瞬愛」です。
    ユーザーは手首を上げてすぐ質問します。
    回答は必ず50文字以内で、簡潔かつ正確に答えてください。
    漢字の読み、英語のスペル、簡単な計算、単語の意味など、即座に答えられる質問が中心です。
    日本語で回答してください。
    """

    // MARK: - Token Limits
    static let watchMaxTokens = 200
    static let phoneMaxTokens = 500

    // MARK: - Keychain
    static let keychainService = "com.syunai.apikey"
    static let keychainAccount = "google-ai"

    // MARK: - UserDefaults Keys
    static let selectedModelKey = "selected_model"
    static let systemPromptKey = "system_prompt"
    static let hapticEnabledKey = "haptic_feedback_enabled"
    static let maxHistoryKey = "max_history_count"
    static let onboardingCompletedKey = "onboarding_completed"
    static let lastSyncDateKey = "last_sync_date"

    // MARK: - WatchConnectivity Keys
    static let wcAPIKeyKey = "api_key"
    static let wcModelKey = "selected_model"
    static let wcSystemPromptKey = "system_prompt"
    static let wcSettingsSyncKey = "settings_sync"

    // MARK: - Quick Prompts (Watch)
    static let quickPrompts: [(emoji: String, label: String, prompt: String)] = [
        ("", "漢字", "この漢字の読みを教えて: "),
        ("🔤", "英語", "英語のスペルを教えて: "),
        ("📖", "意味", "この言葉の意味を簡潔に: "),
        ("🔢", "計算", "計算して: "),
        ("🌐", "翻訳", "日本語に翻訳して: ")
    ]
}
