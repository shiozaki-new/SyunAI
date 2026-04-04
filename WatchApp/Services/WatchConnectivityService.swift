import Foundation
import WatchConnectivity

/// Watch 側 WatchConnectivity サービス
/// iPhone への推論リクエスト送信とモデルステータス受信を担当
class WatchConnectivityService: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityService()

    @Published var isReachable = false

    var onModelStatusUpdate: ((Bool) -> Void)?
    var onReachabilityChange: ((Bool) -> Void)?

    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    // MARK: - Send Inference Request

    func sendInferenceRequest(_ input: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard WCSession.default.isReachable else {
            completion(.failure(SyunAIError.phoneNotReachable))
            return
        }

        let payload: [String: Any] = [AppConstants.wcInferenceRequestKey: input]

        WCSession.default.sendMessage(payload, replyHandler: { reply in
            if let response = reply[AppConstants.wcInferenceResponseKey] as? String {
                completion(.success(response))
            } else if let error = reply[AppConstants.wcInferenceErrorKey] as? String {
                completion(.failure(SyunAIError.inferenceError(error)))
            } else {
                completion(.failure(SyunAIError.inferenceError("不明なエラー")))
            }
        }, errorHandler: { error in
            completion(.failure(error))
        })
    }

    // MARK: - Request Model Status

    func requestModelStatus(completion: @escaping (Bool) -> Void) {
        guard WCSession.default.isReachable else {
            completion(false)
            return
        }

        WCSession.default.sendMessage(
            [AppConstants.wcModelStatusRequestKey: true],
            replyHandler: { reply in
                let isReady = reply[AppConstants.wcModelStatusKey] as? Bool ?? false
                completion(isReady)
            },
            errorHandler: { _ in
                completion(false)
            }
        )
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            self.onReachabilityChange?(session.isReachable)
        }
        if activationState == .activated {
            requestModelStatus { [weak self] ready in
                self?.onModelStatusUpdate?(ready)
            }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            self.onReachabilityChange?(session.isReachable)
        }
    }

    // MARK: - Receive Messages

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        processIncoming(message)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        processIncoming(message)
        replyHandler(["status": "received"])
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        processIncoming(applicationContext)
    }

    private func processIncoming(_ payload: [String: Any]) {
        if let ready = payload[AppConstants.wcModelStatusKey] as? Bool {
            DispatchQueue.main.async {
                self.onModelStatusUpdate?(ready)
            }
        }
    }
}
