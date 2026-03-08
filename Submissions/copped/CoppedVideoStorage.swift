import Foundation

actor CoppedVideoStorage {
    struct PublishResult {
        let videoURL: URL
        let usedLocalFallback: Bool
    }

    static let shared = CoppedVideoStorage()

    private let session: URLSession
    private let localStorageRoot: URL

    private init() {
        let fileManager = FileManager.default
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 180
        session = URLSession(configuration: configuration)

        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory

        localStorageRoot = baseDirectory
            .appendingPathComponent("copped", isDirectory: true)
            .appendingPathComponent("r2-fallback", isDirectory: true)

        try? fileManager.createDirectory(at: localStorageRoot, withIntermediateDirectories: true)
    }

    func publishVideo(sourceURL: URL?, upload: CoppedUploadURLResponse) async -> PublishResult {
        guard let sourceURL else {
            return PublishResult(videoURL: upload.videoURL, usedLocalFallback: false)
        }

        if shouldAttemptRemoteUpload(to: upload.uploadURL),
           await uploadToPresignedURL(sourceFileURL: sourceURL, destinationURL: upload.uploadURL) {
            return PublishResult(videoURL: upload.videoURL, usedLocalFallback: false)
        }

        if let localURL = copyIntoPersistentStorage(sourceURL: sourceURL, key: upload.key) {
            return PublishResult(videoURL: localURL, usedLocalFallback: true)
        }

        return PublishResult(videoURL: sourceURL, usedLocalFallback: true)
    }

    private func shouldAttemptRemoteUpload(to uploadURL: URL) -> Bool {
        guard let scheme = uploadURL.scheme?.lowercased() else { return false }
        guard scheme == "https" || scheme == "http" else { return false }

        if let host = uploadURL.host?.lowercased(),
           host == "upload.copped.app" {
            // Mock backend placeholder: skip noisy failing network calls.
            return false
        }

        return true
    }

    private func uploadToPresignedURL(sourceFileURL: URL, destinationURL: URL) async -> Bool {
        let isQuickTime = sourceFileURL.pathExtension.lowercased() == "mov"

        for attempt in 0..<2 {
            var request = URLRequest(url: destinationURL)
            request.httpMethod = "PUT"
            request.setValue(isQuickTime ? "video/quicktime" : "video/mp4", forHTTPHeaderField: "Content-Type")

            do {
                let (_, response) = try await session.upload(for: request, fromFile: sourceFileURL)
                if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                    print("CoppedVideoStorage: upload succeeded [attempt=\(attempt + 1)] [status=\(httpResponse.statusCode)] [url=\(destinationURL.absoluteString)]")
                    return true
                }
                if let httpResponse = response as? HTTPURLResponse {
                    print("CoppedVideoStorage: upload failed [attempt=\(attempt + 1)] [status=\(httpResponse.statusCode)] [url=\(destinationURL.absoluteString)]")
                } else {
                    print("CoppedVideoStorage: upload failed [attempt=\(attempt + 1)] [status=non-http] [url=\(destinationURL.absoluteString)]")
                }
            } catch {
                print("CoppedVideoStorage: upload error [attempt=\(attempt + 1)] [url=\(destinationURL.absoluteString)] [error=\(error.localizedDescription)]")
            }

            if attempt == 0 {
                try? await Task.sleep(nanoseconds: 600_000_000)
            }
        }

        return false
    }

    private func copyIntoPersistentStorage(sourceURL: URL, key: String) -> URL? {
        let fileManager = FileManager.default
        let sourceExtension = sourceURL.pathExtension
        let keyExtension = URL(fileURLWithPath: key).pathExtension
        let destinationKey: String
        if !sourceExtension.isEmpty, sourceExtension.caseInsensitiveCompare(keyExtension) != .orderedSame {
            destinationKey = (key as NSString).deletingPathExtension + ".\(sourceExtension)"
        } else {
            destinationKey = key
        }

        let destinationURL = localStorageRoot.appendingPathComponent(destinationKey, isDirectory: false)
        let directoryURL = destinationURL.deletingLastPathComponent()

        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }

            if sourceURL.standardizedFileURL == destinationURL.standardizedFileURL {
                return destinationURL
            }

            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL
        } catch {
            return nil
        }
    }
}
