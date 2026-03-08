import SwiftUI
import UIKit

// MARK: - ShareSheet

/// Thin UIActivityViewController wrapper for SwiftUI.
public struct ShareSheet: UIViewControllerRepresentable {
  let items: [Any]
  var onDismiss: (() -> Void)?

  public init(items: [Any], onDismiss: (() -> Void)? = nil) {
    self.items = items
    self.onDismiss = onDismiss
  }

  public func makeUIViewController(context: Context) -> UIActivityViewController {
    let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
    vc.completionWithItemsHandler = { _, _, _, _ in onDismiss?() }
    return vc
  }

  public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - View Modifier

extension View {
  /// Presents the system share sheet.
  ///
  /// ```swift
  /// view.shareSheet(isPresented: $sharing, items: [videoURL, "Check out my clip!"])
  /// ```
  public func shareSheet(
    isPresented: Binding<Bool>,
    items: [Any],
    onDismiss: (() -> Void)? = nil
  ) -> some View {
    sheet(isPresented: isPresented) {
      ShareSheet(items: items, onDismiss: {
        isPresented.wrappedValue = false
        onDismiss?()
      })
      .presentationDetents([.medium, .large])
    }
  }
}
