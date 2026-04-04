import Foundation

enum AppConstants {
    // MARK: - App Info
    static let appVersion = "2.0.0"
    static let appName = "瞬愛 SyunAI"

    // MARK: - Local Model Configuration
    // Gemma 4 E2B の GGUF 公開後に URL とファイル名を差し替えること
    static let modelFileName = "gemma-2-2b-it-Q4_K_M.gguf"
    static let modelDisplayName = "Gemma 2 2B (ローカル)"
    static let modelDownloadURL = "https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf"
    static let modelSizeDescription = "約1.5GB"

    // MARK: - System Prompt
    static let defaultSystemPrompt = """
    あなたはApple Watchで使われる即応AIアシスタント「瞬愛」です。
    ユーザーは手首を上げてすぐ質問します。
    回答は必ず50文字以内で、簡潔かつ正確に答えてください。
    漢字の読み、英語のスペル、簡単な計算、単語の意味など、即座に答えられる質問が中心です。
    日本語で回答してください。
    """

    // MARK: - Inference Settings
    static let maxTokens: Int32 = 200
    static let temperature: Float = 0.7
    static let contextSize: Int32 = 2048
    static let repeatPenalty: Float = 1.1

    // MARK: - UserDefaults Keys
    static let systemPromptKey = "system_prompt"
    static let hapticEnabledKey = "haptic_feedback_enabled"
    static let onboardingCompletedKey = "onboarding_completed"
    static let modelReadyKey = "model_ready"

    // MARK: - WatchConnectivity Keys
    static let wcInferenceRequestKey = "inference_request"
    static let wcInferenceResponseKey = "inference_response"
    static let wcInferenceErrorKey = "inference_error"
    static let wcModelStatusKey = "model_status"
    static let wcModelStatusRequestKey = "model_status_request"

    // MARK: - Quick Prompts (Watch)
    static let quickPrompts: [(emoji: String, label: String, prompt: String)] = [
        ("字", "漢字", "この漢字の読みを教えて: "),
        ("🔤", "英語", "英語のスペルを教えて: "),
        ("📖", "意味", "この言葉の意味を簡潔に: "),
        ("🔢", "計算", "計算して: "),
        ("🌐", "翻訳", "日本語に翻訳して: ")
    ]
}
