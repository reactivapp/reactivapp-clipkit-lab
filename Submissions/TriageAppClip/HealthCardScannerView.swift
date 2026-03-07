import SwiftUI
import VisionKit
import Vision

/// A SwiftUI view that uses DataScannerViewController to live-scan text from the
/// camera and extract an Ontario Health Card (OHIP) number via regex.
///
/// OHIP format: 10 digits (####-###-###) optionally followed by a 2-letter version code.
struct HealthCardScannerView: View {
    @Binding var scannedNumber: String
    @Environment(\.dismiss) private var dismiss

    @State private var recognizedText: String = ""
    @State private var debugRawTexts: [String] = []
    @State private var errorMessage: String? = nil

    /// Regex: 10 digits (with optional spaces/hyphens between groups of 4-3-3),
    /// plus an optional 2-letter version code.
    private static let ohipPattern = #"\b(\d{4})[\s\-]*(\d{3})[\s\-]*(\d{3})[\s\-]*([A-Za-z]{2})?\b"#

    var body: some View {
        NavigationView {
            Group {
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    DataScannerRepresentable(onTextFound: handleRecognizedText)
                        .ignoresSafeArea()
                        .overlay(alignment: .top) {
                            debugOverlay
                        }
                        .overlay(alignment: .bottom) {
                            scanOverlay
                        }
                } else {
                    unsupportedView
                }
            }
            .navigationTitle("Scan Health Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Debug Overlay

    private var debugOverlay: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DEBUG — Raw OCR Text")
                .font(.caption2.bold())
                .foregroundColor(.yellow)
            if debugRawTexts.isEmpty {
                Text("(no text detected)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                    .italic()
            } else {
                ForEach(Array(debugRawTexts.enumerated()), id: \.offset) { _, text in
                    Text(text)
                        .font(.caption2.monospaced())
                        .foregroundColor(.white)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.top, 60)
    }

    // MARK: - Overlay

    private var scanOverlay: some View {
        VStack(spacing: 8) {
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            if !recognizedText.isEmpty {
                Text(recognizedText)
                    .font(.headline.monospacedDigit())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else {
                Text("Point camera at health card number")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.bottom, 40)
    }

    // MARK: - Unsupported Fallback

    private var unsupportedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.badge.ellipsis")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Camera scanning is not available on this device.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Text("Please enter your health card number manually.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(32)
    }

    // MARK: - Text Processing

    private func handleRecognizedText(_ texts: [String]) {
        debugRawTexts = texts
        let combined = texts.joined(separator: " ")

        guard let regex = try? NSRegularExpression(pattern: Self.ohipPattern, options: []) else {
            return
        }

        let range = NSRange(combined.startIndex..., in: combined)
        guard let match = regex.firstMatch(in: combined, options: [], range: range) else {
            return
        }

        // Extract the three digit groups
        guard let g1Range = Range(match.range(at: 1), in: combined),
              let g2Range = Range(match.range(at: 2), in: combined),
              let g3Range = Range(match.range(at: 3), in: combined) else {
            return
        }

        let group1 = String(combined[g1Range])
        let group2 = String(combined[g2Range])
        let group3 = String(combined[g3Range])

        var formatted = "\(group1)-\(group2)-\(group3)"

        // Optional version code (2 letters)
        if match.range(at: 4).location != NSNotFound,
           let vcRange = Range(match.range(at: 4), in: combined) {
            let versionCode = String(combined[vcRange]).uppercased()
            formatted += "-\(versionCode)"
        }

        recognizedText = formatted
        scannedNumber = formatted
        dismiss()
    }
}

// MARK: - DataScannerViewController UIKit Representable

private struct DataScannerRepresentable: UIViewControllerRepresentable {
    let onTextFound: ([String]) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onTextFound: onTextFound)
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onTextFound: ([String]) -> Void

        init(onTextFound: @escaping ([String]) -> Void) {
            self.onTextFound = onTextFound
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            processItems(allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            processItems(allItems)
        }

        private func processItems(_ items: [RecognizedItem]) {
            let texts = items.compactMap { item -> String? in
                if case .text(let text) = item {
                    return text.transcript
                }
                return nil
            }
            guard !texts.isEmpty else { return }
            onTextFound(texts)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
            print("DataScanner became unavailable: \(error.localizedDescription)")
        }
    }
}
