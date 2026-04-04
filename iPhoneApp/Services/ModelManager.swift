import Foundation
import Combine

/// モデルファイルのダウンロード・管理を行うサービス
@MainActor
class ModelManager: NSObject, ObservableObject {
    @Published var downloadProgress: Double = 0
    @Published var isDownloading = false
    @Published var isModelReady = false
    @Published var error: String?
    @Published var downloadedSizeText = ""

    private var downloadTask: URLSessionDownloadTask?
    private var urlSession: URLSession?
    private var progressObservation: NSKeyValueObservation?

    override init() {
        super.init()
        let exists = modelFileExists
        isModelReady = exists
        UserDefaults.standard.set(exists, forKey: AppConstants.modelReadyKey)
    }

    // MARK: - File Paths

    var modelDirectoryURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("models", isDirectory: true)
    }

    var modelFilePath: String {
        modelDirectoryURL.appendingPathComponent(AppConstants.modelFileName).path
    }

    var modelFileExists: Bool {
        FileManager.default.fileExists(atPath: modelFilePath)
    }

    // MARK: - Download

    func startDownload() {
        guard !isDownloading else { return }
        error = nil
        isDownloading = true
        downloadProgress = 0
        downloadedSizeText = ""

        // Ensure directory
        try? FileManager.default.createDirectory(at: modelDirectoryURL, withIntermediateDirectories: true)

        guard let url = URL(string: AppConstants.modelDownloadURL) else {
            error = "ダウンロードURLが無効です"
            isDownloading = false
            return
        }

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = 3600 // 1 hour for large model
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        self.urlSession = session

        let task = session.downloadTask(with: url)
        self.downloadTask = task
        task.resume()
    }

    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        isDownloading = false
        downloadProgress = 0
    }

    // MARK: - Delete

    func deleteModel() {
        try? FileManager.default.removeItem(atPath: modelFilePath)
        isModelReady = false
        error = nil
        UserDefaults.standard.set(false, forKey: AppConstants.modelReadyKey)
    }

    // MARK: - Load into LLM Service

    func loadModelIntoService() async throws {
        guard modelFileExists else {
            throw LLMError.modelFileNotFound
        }
        try LocalLLMService.shared.ensureModelLoaded(at: modelFilePath)
        isModelReady = true
        UserDefaults.standard.set(true, forKey: AppConstants.modelReadyKey)
    }
}

// MARK: - URLSessionDownloadDelegate

extension ModelManager: URLSessionDownloadDelegate {
    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        Task { @MainActor in
            do {
                let destination = URL(fileURLWithPath: modelFilePath)
                // Remove existing file
                try? FileManager.default.removeItem(at: destination)
                try FileManager.default.moveItem(at: location, to: destination)

                isDownloading = false
                downloadProgress = 1.0
                self.downloadTask = nil

                // Auto-load and only then mark as ready
                try await loadModelIntoService()
            } catch {
                isModelReady = false
                UserDefaults.standard.set(false, forKey: AppConstants.modelReadyKey)
                self.error = "モデル保存エラー: \(error.localizedDescription)"
                isDownloading = false
            }
        }
    }

    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                                didWriteData bytesWritten: Int64,
                                totalBytesWritten: Int64,
                                totalBytesExpectedToWrite: Int64) {
        Task { @MainActor in
            if totalBytesExpectedToWrite > 0 {
                downloadProgress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            }
            let mb = Double(totalBytesWritten) / 1_000_000
            downloadedSizeText = String(format: "%.0f MB", mb)
        }
    }

    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }
        if (error as NSError).code == NSURLErrorCancelled { return }
        Task { @MainActor in
            self.downloadTask = nil
            self.error = "ダウンロードエラー: \(error.localizedDescription)"
            isDownloading = false
        }
    }
}
