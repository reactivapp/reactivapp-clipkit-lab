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
