import Foundation
import WatchConnectivity

class WatchConnectivityService: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityService()

    @Published var isReachable = false

    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    // MARK: - Request Settings Sync

    func requestSettingsSync() {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(
            [AppConstants.wcSettingsSyncKey: true],
            replyHandler: nil,
            errorHandler: nil
        )
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
        if activationState == .activated {
            requestSettingsSync()
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    // MARK: - Receive Settings

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        processSettings(message)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        processSettings(message)
        replyHandler(["status": "received"])
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        processSettings(userInfo)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        processSettings(applicationContext)
    }

    private func processSettings(_ payload: [String: Any]) {
        DispatchQueue.main.async {
            if let apiKey = payload[AppConstants.wcAPIKeyKey] as? String {
                _ = KeychainService.saveAPIKey(apiKey)
            }
            if let model = payload[AppConstants.wcModelKey] as? String {
                UserDefaults.standard.set(model, forKey: AppConstants.selectedModelKey)
            }
            if let prompt = payload[AppConstants.wcSystemPromptKey] as? String {
                UserDefaults.standard.set(prompt, forKey: AppConstants.systemPromptKey)
            }
        }
    }
}
