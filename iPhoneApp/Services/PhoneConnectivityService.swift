import Foundation
import WatchConnectivity

/// iPhone 側 WatchConnectivity サービス
/// Watch からの推論リクエストを受け取り、ローカル LLM で処理して返す
class PhoneConnectivityService: NSObject, ObservableObject, WCSessionDelegate {
    @Published var isWatchReachable = false
    @Published var isWatchAppInstalled = false

    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    // MARK: - Send Model Status to Watch

    func sendModelStatusToWatch(isReady: Bool) {
        let payload: [String: Any] = [
            AppConstants.wcModelStatusKey: isReady
        ]
        let session = WCSession.default
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        }
        // Also update application context for guaranteed delivery
        try? session.updateApplicationContext(payload)
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
            self.isWatchAppInstalled = session.isWatchAppInstalled
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
        }
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchAppInstalled = session.isWatchAppInstalled
        }
    }

    // MARK: - Handle Watch Requests

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleMessage(message, replyHandler: nil)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        handleMessage(message, replyHandler: replyHandler)
    }

    private func handleMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?) {
        // Watch is requesting model status
        if message[AppConstants.wcModelStatusRequestKey] != nil {
            let isReady = UserDefaults.standard.bool(forKey: AppConstants.modelReadyKey)
            replyHandler?([AppConstants.wcModelStatusKey: isReady])
            return
        }

        // Watch is requesting inference
        guard let userInput = message[AppConstants.wcInferenceRequestKey] as? String else {
            replyHandler?([AppConstants.wcInferenceErrorKey: "不正なリクエストです"])
            return
        }

        // Try local utility first
        if let localResult = LocalUtility.tryHandle(userInput) {
            replyHandler?([AppConstants.wcInferenceResponseKey: localResult])
            return
        }

        // Run LLM inference
        Task {
            do {
                let systemPrompt = UserDefaults.standard.string(forKey: AppConstants.systemPromptKey)
                    ?? AppConstants.defaultSystemPrompt
                let response = try await LocalLLMService.shared.generate(
                    prompt: userInput,
                    systemPrompt: systemPrompt
                )
                replyHandler?([AppConstants.wcInferenceResponseKey: response])
            } catch {
                replyHandler?([AppConstants.wcInferenceErrorKey: error.localizedDescription])
            }
        }
    }
}
