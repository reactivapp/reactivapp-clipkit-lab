import SwiftUI
import UIKit

struct ClipStakesShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

enum ClipStakesClipboard {
    @MainActor
    static func copy(_ value: String) {
        UIPasteboard.general.string = value
    }
}

enum ClipStakesURLLauncher {
    static func isReachable(_ url: URL, timeout: TimeInterval = 2.5) async -> Bool {
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return true
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        let session = URLSession(configuration: configuration)

        var headRequest = URLRequest(url: url)
        headRequest.httpMethod = "HEAD"

        do {
            let (_, response) = try await session.data(for: headRequest)
            return response is HTTPURLResponse
        } catch {
            var rangeRequest = URLRequest(url: url)
            rangeRequest.httpMethod = "GET"
            rangeRequest.setValue("bytes=0-0", forHTTPHeaderField: "Range")
            do {
                let (_, response) = try await session.data(for: rangeRequest)
                return response is HTTPURLResponse
            } catch {
                return false
            }
        }
    }

    @MainActor
    static func open(_ url: URL) async -> Bool {
        await withCheckedContinuation { continuation in
            UIApplication.shared.open(url, options: [:]) { success in
                continuation.resume(returning: success)
            }
        }
    }
}
