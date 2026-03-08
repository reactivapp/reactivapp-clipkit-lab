import Foundation

actor CoppedVideoStorage {
    static let shared = CoppedVideoStorage()

    private let session: URLSession
    private let localStorageRoot: URL

    private init() {
        let fileManager = FileManager.default
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 12
        configuration.timeoutIntervalForResource = 20
        session = URLSession(configuration: configuration)

        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory

        localStorageRoot = baseDirectory
            .appendingPathComponent("copped", isDirectory: true)
            .appendingPathComponent("r2-fallback", isDirectory: true)

        try? fileManager.createDirectory(at: localStorageRoot, withIntermediateDirectories: true)
    }

    func publishVideo(sourceURL: URL?, upload: CoppedUploadURLResponse) async -> URL {
        guard let sourceURL else {
            return upload.videoURL
        }

        if shouldAttemptRemoteUpload(to: upload.uploadURL),
           await uploadToPresignedURL(sourceFileURL: sourceURL, destinationURL: upload.uploadURL) {
            return upload.videoURL
        }

        if let localURL = copyIntoPersistentStorage(sourceURL: sourceURL, key: upload.key) {
            return localURL
        }

        return sourceURL
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
        var request = URLRequest(url: destinationURL)
        request.httpMethod = "PUT"
        let isQuickTime = sourceFileURL.pathExtension.lowercased() == "mov"
        request.setValue(isQuickTime ? "video/quicktime" : "video/mp4", forHTTPHeaderField: "Content-Type")

        do {
            let (_, response) = try await session.upload(for: request, fromFile: sourceFileURL)
            guard let httpResponse = response as? HTTPURLResponse else { return false }
            return (200...299).contains(httpResponse.statusCode)
        } catch {
            return false
        }
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
