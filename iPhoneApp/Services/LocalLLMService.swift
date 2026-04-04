import Foundation
import llama

/// iPhone 上で llama.cpp を使ったローカル推論を行うサービス
@MainActor
class LocalLLMService: ObservableObject {
    @Published var isModelLoaded = false
    @Published var isGenerating = false

    private var model: OpaquePointer?   // llama_model *
    private var context: OpaquePointer? // llama_context *

    static let shared = LocalLLMService()
    private init() {}

    nonisolated static var defaultModelPath: String {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs
            .appendingPathComponent("models", isDirectory: true)
            .appendingPathComponent(AppConstants.modelFileName)
            .path
    }

    // MARK: - Model Lifecycle

    func loadModel(at path: String) throws {
        guard FileManager.default.fileExists(atPath: path) else {
            throw LLMError.modelFileNotFound
        }

        if isModelLoaded {
            unloadModel()
        }

        llama_backend_init()

        var modelParams = llama_model_default_params()
        modelParams.n_gpu_layers = 0 // CPU-only (safe for all iPhones)

        guard let loadedModel = llama_model_load_from_file(path, modelParams) else {
            throw LLMError.modelLoadFailed
        }
        self.model = loadedModel

        var ctxParams = llama_context_default_params()
        ctxParams.n_ctx = UInt32(AppConstants.contextSize)
        let nThreads = Int32(max(1, min(4, ProcessInfo.processInfo.activeProcessorCount - 1)))
        ctxParams.n_threads = nThreads
        ctxParams.n_threads_batch = nThreads

        guard let ctx = llama_init_from_model(loadedModel, ctxParams) else {
            llama_model_free(loadedModel)
            self.model = nil
            throw LLMError.contextCreationFailed
        }
        self.context = ctx
        self.isModelLoaded = true
    }

    func ensureModelLoaded(at path: String? = nil) throws {
        guard !isModelLoaded else { return }
        try loadModel(at: path ?? Self.defaultModelPath)
    }

    func unloadModel() {
        if let ctx = context {
            llama_free(ctx)
            context = nil
        }
        if let mdl = model {
            llama_model_free(mdl)
            model = nil
        }
        isModelLoaded = false
    }

    // MARK: - Inference

    nonisolated func generate(prompt: String, systemPrompt: String, maxTokens: Int32 = AppConstants.maxTokens) async throws -> String {
        let model = await self.model
        let context = await self.context

        guard let model, let context else {
            throw LLMError.modelNotLoaded
        }

        await MainActor.run { [weak self] in self?.isGenerating = true }
        defer { Task { @MainActor [weak self] in self?.isGenerating = false } }

        return try await Task.detached(priority: .userInitiated) {
            let fullPrompt = Self.buildChatPrompt(system: systemPrompt, user: prompt)

            // Tokenize
            let vocab = llama_model_get_vocab(model)
            let promptTokens = Self.tokenize(vocab: vocab!, text: fullPrompt, addBos: true)
            guard !promptTokens.isEmpty else { throw LLMError.tokenizationFailed }

            // Clear memory (KV cache)
            let memory = llama_get_memory(context)
            if let memory {
                llama_memory_clear(memory, true)
            }

            // Process prompt tokens in a batch
            let nPrompt = Int32(promptTokens.count)
            var batch = llama_batch_init(nPrompt, 0, 1)
            defer { llama_batch_free(batch) }

            batch.n_tokens = nPrompt
            for i in 0..<Int(nPrompt) {
                batch.token[i] = promptTokens[i]
                batch.pos[i] = Int32(i)
                batch.n_seq_id[i] = 1
                batch.seq_id[i]![0] = 0
                batch.logits[i] = (i == Int(nPrompt) - 1) ? 1 : 0
            }

            guard llama_decode(context, batch) == 0 else {
                throw LLMError.decodeFailed
            }

            // Set up sampler chain: temperature → greedy
            let sparams = llama_sampler_chain_default_params()
            guard let sampler = llama_sampler_chain_init(sparams) else {
                throw LLMError.generationFailed
            }
            defer { llama_sampler_free(sampler) }

            llama_sampler_chain_add(sampler, llama_sampler_init_temp(AppConstants.temperature))
            llama_sampler_chain_add(sampler, llama_sampler_init_greedy())

            // Generate tokens one by one
            var outputTokens: [llama_token] = []
            let eosToken = llama_vocab_eos(vocab!)
            var nCur = nPrompt

            for _ in 0..<maxTokens {
                let newToken = llama_sampler_sample(sampler, context, -1)

                if newToken == eosToken { break }
                outputTokens.append(newToken)

                // Prepare next single-token batch
                batch.n_tokens = 1
                batch.token[0] = newToken
                batch.pos[0] = nCur
                batch.n_seq_id[0] = 1
                batch.seq_id[0]![0] = 0
                batch.logits[0] = 1
                nCur += 1

                guard llama_decode(context, batch) == 0 else { break }
            }

            return Self.detokenize(vocab: vocab!, tokens: outputTokens)
        }.value
    }

    // MARK: - Chat Prompt Formatting (Gemma format)

    private nonisolated static func buildChatPrompt(system: String, user: String) -> String {
        var prompt = "<start_of_turn>user\n"
        if !system.isEmpty {
            prompt += "\(system)\n\n"
        }
        prompt += "\(user)<end_of_turn>\n<start_of_turn>model\n"
        return prompt
    }

    // MARK: - Tokenization

    private nonisolated static func tokenize(vocab: OpaquePointer, text: String, addBos: Bool) -> [llama_token] {
        let utf8Count = Int32(text.utf8.count)
        let nMax = utf8Count + (addBos ? 1 : 0) + 16
        var tokens = [llama_token](repeating: 0, count: Int(nMax))

        let nTokens = llama_tokenize(vocab, text, utf8Count, &tokens, nMax, addBos, true)
        guard nTokens >= 0 else { return [] }
        return Array(tokens.prefix(Int(nTokens)))
    }

    private nonisolated static func detokenize(vocab: OpaquePointer, tokens: [llama_token]) -> String {
        var result = ""
        var buffer = [CChar](repeating: 0, count: 256)

        for token in tokens {
            let n = llama_token_to_piece(vocab, token, &buffer, Int32(buffer.count), 0, true)
            if n > 0 {
                buffer[Int(n)] = 0
                result += String(cString: buffer)
            }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Errors

enum LLMError: LocalizedError {
    case modelFileNotFound
    case modelLoadFailed
    case contextCreationFailed
    case modelNotLoaded
    case tokenizationFailed
    case decodeFailed
    case generationFailed

    var errorDescription: String? {
        switch self {
        case .modelFileNotFound: return "モデルファイルが見つかりません"
        case .modelLoadFailed: return "モデルの読み込みに失敗しました"
        case .contextCreationFailed: return "推論コンテキストの作成に失敗しました"
        case .modelNotLoaded: return "モデルが読み込まれていません"
        case .tokenizationFailed: return "テキストのトークン化に失敗しました"
        case .decodeFailed: return "推論処理に失敗しました"
        case .generationFailed: return "テキスト生成に失敗しました"
        }
    }
}
