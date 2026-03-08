import AVFoundation
internal import Combine
import SwiftUI
import UIKit

struct ClipStakesVideoRecorder: View {
    let minDuration: TimeInterval
    let maxDuration: TimeInterval
    let onRecorded: (ClipStakesRecordedVideo) -> Void

    @StateObject private var controller = ClipStakesCameraController()
    @State private var simulatorRecording = false
    @State private var simulatorElapsed: TimeInterval = 0
    @State private var simulatorError: String?

    private let simulatorTicker = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    private var recordingCanvasHeight: CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        return max(360, min(560, screenHeight * 0.62))
    }

    var body: some View {
        VStack(spacing: 0) {
            if controller.useSimulatorFallback {
                simulatorBody
            } else {
                cameraBody
            }

            if let message = controller.errorMessage ?? simulatorError {
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 10))
                    Text(message)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
                .foregroundStyle(ClipStakesPalette.neonOrange)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(ClipStakesPalette.neonOrange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
        .onAppear {
            controller.prepare(minDuration: minDuration, maxDuration: maxDuration, onRecorded: onRecorded)
        }
        .onDisappear {
            controller.stopSession()
        }
        .onReceive(simulatorTicker) { _ in
            guard simulatorRecording else { return }
            simulatorElapsed += 0.1
            if simulatorElapsed >= maxDuration {
                stopSimulatorRecording()
            }
        }
    }

    private var cameraBody: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .topLeading) {
                ClipStakesCameraPreview(session: controller.session)
                    .frame(maxWidth: .infinity)
                    .frame(height: recordingCanvasHeight)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                LinearGradient(
                    colors: [Color.black.opacity(0.35), Color.clear, Color.black.opacity(0.45)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))

                HStack(spacing: 8) {
                    recordPill(elapsed: controller.elapsed, mode: .camera)
                    Spacer()
                    if controller.isRecording {
                        Text("REC")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red, in: Capsule())
                    }
                }
                .padding(12)

                if !controller.isSessionRunning, controller.errorMessage == nil {
                    VStack(spacing: 6) {
                        ProgressView()
                            .tint(.white)
                        Text("Preparing camera...")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                if controller.isFinalizing {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.black.opacity(0.45))
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(.white)
                            Text("Finalizing clip...")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            .padding(.horizontal, 2)

            if controller.isFinalizing {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(ClipStakesPalette.neonBlue)
                    Text("Saving your recording")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            } else {
                let canStopRecording = controller.elapsed >= minDuration
                recordButton(
                    isRecording: controller.isRecording,
                    canStop: canStopRecording,
                    remainingSeconds: max(0, Int(ceil(minDuration - controller.elapsed))),
                    onTap: {
                        if controller.isRecording {
                            guard canStopRecording else { return }
                            controller.stopRecording()
                        } else {
                            simulatorError = nil
                            controller.startRecording()
                        }
                    },
                    accentColor: .red
                )
            }

            recorderHint(
                controller.isFinalizing
                    ? "Please wait while the clip is saved."
                    : (controller.isRecording
                        ? "Recording live. Tap again to stop."
                        : "Capture a vertical clip (5-15s).")
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
    }

    private var simulatorBody: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                ClipStakesPalette.neonBlue.opacity(0.15),
                                ClipStakesPalette.mint.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: recordingCanvasHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                VStack(spacing: 8) {
                    Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                        .font(.system(size: 30, weight: .light))
                        .foregroundStyle(.white.opacity(0.4))
                    Text("Simulator Mode")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                    Text("Use a physical iPhone for camera")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.3))
                }

                HStack(spacing: 8) {
                    recordPill(elapsed: simulatorElapsed, mode: .simulator)
                    Spacer()
                    if simulatorRecording {
                        Text("REC")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red, in: Capsule())
                    }
                }
                .padding(12)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            .padding(.horizontal, 2)

            let canStopRecording = simulatorElapsed >= minDuration
            recordButton(
                isRecording: simulatorRecording,
                canStop: canStopRecording,
                remainingSeconds: max(0, Int(ceil(minDuration - simulatorElapsed))),
                onTap: {
                    if simulatorRecording {
                        guard canStopRecording else { return }
                        stopSimulatorRecording()
                    } else {
                        startSimulatorRecording()
                    }
                },
                accentColor: ClipStakesPalette.neonOrange
            )

            recorderHint(
                simulatorRecording
                    ? "Recording simulated clip. Tap again to stop."
                    : "Simulator fallback still enforces 5-15 seconds."
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
    }

    private func recordButton(
        isRecording: Bool,
        canStop: Bool,
        remainingSeconds: Int,
        onTap: @escaping () -> Void,
        accentColor: Color
    ) -> some View {
        let stopDisabled = isRecording && !canStop
        let title: String
        if isRecording {
            title = canStop ? "Stop Recording" : "Keep Recording \(remainingSeconds)s"
        } else {
            title = "Start Recording"
        }

        let iconName: String
        if isRecording {
            iconName = canStop ? "stop.fill" : "timer"
        } else {
            iconName = "record.circle.fill"
        }

        return Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .black))

                Text(title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
            }
            .foregroundStyle(stopDisabled ? .white.opacity(0.7) : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(stopDisabled ? Color.white.opacity(0.25) : (isRecording ? Color.red : accentColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: (isRecording ? Color.red : accentColor).opacity(0.32), radius: 12, y: 4)
            .animation(.easeInOut(duration: 0.2), value: isRecording)
        }
        .buttonStyle(.plain)
        .disabled(stopDisabled)
        .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
    }

    private func recorderHint(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.55))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.top, 2)
    }

    @ViewBuilder
    private func recordPill(elapsed: TimeInterval, mode: ClipStakesCaptureMode) -> some View {
        let isActive = (mode == .camera ? controller.isRecording : simulatorRecording)
        HStack(spacing: 5) {
            Circle()
                .fill(isActive ? Color.red : ClipStakesPalette.mint)
                .frame(width: 6, height: 6)
            Text("\(Int(elapsed))s")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            Text("\(Int(minDuration))-\(Int(maxDuration))s")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private func startSimulatorRecording() {
        simulatorError = nil
        simulatorElapsed = 0
        simulatorRecording = true
    }

    private func stopSimulatorRecording() {
        simulatorRecording = false

        if simulatorElapsed < minDuration {
            simulatorError = "Clip must be at least \(Int(minDuration)) seconds."
            return
        }

        let rounded = min(Int(simulatorElapsed.rounded()), Int(maxDuration))
        onRecorded(
            ClipStakesRecordedVideo(
                fileURL: nil,
                durationSeconds: rounded,
                captureMode: .simulator
            )
        )
    }
}

@MainActor
final class ClipStakesCameraController: NSObject, ObservableObject {
    @Published var errorMessage: String?
    @Published var isSessionRunning = false
    @Published var isRecording = false
    @Published var isFinalizing = false
    @Published var elapsed: TimeInterval = 0
    @Published var useSimulatorFallback = false

    let session = AVCaptureSession()

    private let movieOutput = AVCaptureMovieFileOutput()
    private let sessionQueue = DispatchQueue(label: "clipstakes.camera.session")

    private var isConfigured = false
    private var minDuration: TimeInterval = 5
    private var maxDuration: TimeInterval = 15
    private var recordingStartDate: Date?
    private var timer: Timer?
    private var onRecorded: ((ClipStakesRecordedVideo) -> Void)?

    func prepare(
        minDuration: TimeInterval,
        maxDuration: TimeInterval,
        onRecorded: @escaping (ClipStakesRecordedVideo) -> Void
    ) {
        self.minDuration = minDuration
        self.maxDuration = maxDuration
        self.onRecorded = onRecorded
        self.errorMessage = nil

#if targetEnvironment(simulator)
        useSimulatorFallback = true
#else
        Task {
            let cameraGranted = await requestVideoAccessIfNeeded()

            guard cameraGranted else {
                errorMessage = "Camera permission is required to record clips."
                return
            }

            configureSessionIfNeeded(includeAudio: false)
            startSession()
        }
#endif
    }

    func startRecording() {
        guard isConfigured else { return }
        guard !isFinalizing else { return }
        guard !movieOutput.isRecording else { return }
        guard isSessionRunning else {
            errorMessage = "Camera is still preparing. Try again."
            return
        }

        errorMessage = nil
        isFinalizing = false
        elapsed = 0

        let outputURL = Self.tempMovieURL()
        movieOutput.maxRecordedDuration = CMTime(seconds: maxDuration, preferredTimescale: 600)
        movieOutput.startRecording(to: outputURL, recordingDelegate: self)
    }

    func stopRecording() {
        guard movieOutput.isRecording else { return }
        isFinalizing = true
        movieOutput.stopRecording()
    }

    func stopSession() {
        timer?.invalidate()
        timer = nil

#if !targetEnvironment(simulator)
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
            Task { @MainActor in
                self.isSessionRunning = false
            }
        }
#endif
    }

    // MARK: - Permissions

    private func requestVideoAccessIfNeeded() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            return await requestAccess(for: .video)
        @unknown default:
            return false
        }
    }

    private func requestAccess(for mediaType: AVMediaType) async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: mediaType) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    // MARK: - Session

    private func configureSessionIfNeeded(includeAudio: Bool) {
        guard !isConfigured else { return }

        session.beginConfiguration()
        session.sessionPreset = .high
        session.automaticallyConfiguresApplicationAudioSession = false

        defer {
            session.commitConfiguration()
            isConfigured = true
        }

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput)
        else {
            errorMessage = "Unable to configure camera input."
            return
        }

        session.addInput(videoInput)

        if includeAudio,
           let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }

        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        } else {
            errorMessage = "Unable to configure video output."
        }
    }

    private func startSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard !self.session.isRunning else {
                Task { @MainActor in
                    self.isSessionRunning = true
                }
                return
            }
            self.session.startRunning()
            Task { @MainActor in
                let didStart = self.session.isRunning
                self.isSessionRunning = didStart
                if !didStart, self.errorMessage == nil {
                    self.errorMessage = "Camera did not start. Check permissions and try again."
                }
            }
        }
    }

    private func beginTimer() {
        timer?.invalidate()
        recordingStartDate = Date()

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            guard let start = self.recordingStartDate else { return }

            self.elapsed = Date().timeIntervalSince(start)
            if self.elapsed >= self.maxDuration {
                self.stopRecording()
            }
        }
    }

    private func finishRecording(outputURL: URL, error: Error?) {
        timer?.invalidate()
        timer = nil
        isRecording = false
        isFinalizing = false

        let asset = AVURLAsset(url: outputURL)
        let loadedDuration = CMTimeGetSeconds(asset.duration)
        let measuredDuration = elapsed
        let duration = if loadedDuration.isFinite, loadedDuration > 0 {
            loadedDuration
        } else {
            measuredDuration
        }
        let hasFile = FileManager.default.fileExists(atPath: outputURL.path)
        let hasUsableVideo = hasFile && duration.isFinite && duration > 0

        if let error, !hasUsableVideo {
            errorMessage = "Recording failed. \(error.localizedDescription)"
            return
        }

        guard duration.isFinite, duration >= minDuration else {
            errorMessage = "Clip must be at least \(Int(minDuration)) seconds."
            try? FileManager.default.removeItem(at: outputURL)
            return
        }

        let boundedDuration = max(minDuration, min(duration, maxDuration))

        onRecorded?(
            ClipStakesRecordedVideo(
                fileURL: outputURL,
                durationSeconds: Int(boundedDuration.rounded()),
                captureMode: .camera
            )
        )
    }

    private static func tempMovieURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("clipstakes-\(UUID().uuidString).mov")
    }
}

extension ClipStakesCameraController: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didStartRecordingTo fileURL: URL,
        from connections: [AVCaptureConnection]
    ) {
        Task { @MainActor in
            self.isRecording = true
            self.isFinalizing = false
            self.elapsed = 0
            self.beginTimer()
        }
    }

    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        Task { @MainActor in
            self.finishRecording(outputURL: outputFileURL, error: error)
        }
    }
}

struct ClipStakesCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.previewLayer.videoGravity = .resizeAspectFill
        view.previewLayer.session = session
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        uiView.previewLayer.session = session
    }
}

final class CameraPreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
