import Foundation
import WatchConnectivity

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

    // MARK: - Send Settings

    func sendSettingsToWatch(apiKey: String, model: String, systemPrompt: String) {
        let payload: [String: Any] = [
            AppConstants.wcAPIKeyKey: apiKey,
            AppConstants.wcModelKey: model,
            AppConstants.wcSystemPromptKey: systemPrompt
        ]

        let session = WCSession.default

        // Guaranteed delivery
        session.transferUserInfo(payload)

        // Also try immediate delivery
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        }
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

    // Handle sync requests from Watch
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if message[AppConstants.wcSettingsSyncKey] != nil {
            // Watch is requesting settings - send if available
            if let apiKey = PhoneKeychainService.getAPIKey() {
                let model = UserDefaults.standard.string(forKey: AppConstants.selectedModelKey) ?? AppConstants.defaultModel
                let prompt = UserDefaults.standard.string(forKey: AppConstants.systemPromptKey) ?? AppConstants.defaultSystemPrompt
                sendSettingsToWatch(apiKey: apiKey, model: model, systemPrompt: prompt)
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        if message[AppConstants.wcSettingsSyncKey] != nil {
            if let apiKey = PhoneKeychainService.getAPIKey() {
                let model = UserDefaults.standard.string(forKey: AppConstants.selectedModelKey) ?? AppConstants.defaultModel
                let prompt = UserDefaults.standard.string(forKey: AppConstants.systemPromptKey) ?? AppConstants.defaultSystemPrompt
                sendSettingsToWatch(apiKey: apiKey, model: model, systemPrompt: prompt)
            }
        }
        replyHandler(["status": "ok"])
    }
}
