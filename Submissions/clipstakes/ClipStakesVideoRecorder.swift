import AVFoundation
internal import Combine
import SwiftUI

struct ClipStakesVideoRecorder: View {
    let minDuration: TimeInterval
    let maxDuration: TimeInterval
    let onRecorded: (ClipStakesRecordedVideo) -> Void

    @StateObject private var controller = ClipStakesCameraController()
    @State private var simulatorRecording = false
    @State private var simulatorElapsed: TimeInterval = 0
    @State private var simulatorError: String?

    private let simulatorTicker = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 16) {
            if controller.useSimulatorFallback {
                simulatorBody
            } else {
                cameraBody
            }

            if let message = controller.errorMessage ?? simulatorError {
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
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
            ZStack {
                ClipStakesCameraPreview(session: controller.session)
                    .frame(height: 330)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                VStack {
                    HStack {
                        recordPill(elapsed: controller.elapsed, mode: .camera)
                        Spacer()
                    }
                    .padding(12)
                    Spacer()
                }
            }
            .overlay {
                if !controller.isSessionRunning {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Preparing camera...")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)

            Button {
                if controller.isRecording {
                    controller.stopRecording()
                } else {
                    simulatorError = nil
                    controller.startRecording()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(controller.isRecording ? Color.red : Color.white)
                        .frame(width: 74, height: 74)

                    if controller.isRecording {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white)
                            .frame(width: 24, height: 24)
                    } else {
                        Circle()
                            .strokeBorder(Color.red, lineWidth: 6)
                            .frame(width: 34, height: 34)
                    }
                }
                .shadow(color: .black.opacity(0.2), radius: 8, y: 3)
            }
            .buttonStyle(.plain)

            Text("Record a real clip (5–15s) on device")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    private var simulatorBody: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.35), Color.green.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 330)

                VStack(spacing: 10) {
                    Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                        .font(.system(size: 38))
                        .foregroundStyle(.white)
                    Text("Simulator Recording Mode")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Use a physical iPhone for camera capture")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.85))
                }

                VStack {
                    HStack {
                        recordPill(elapsed: simulatorElapsed, mode: .simulator)
                        Spacer()
                    }
                    .padding(12)
                    Spacer()
                }
            }
            .padding(.horizontal, 16)

            Button {
                if simulatorRecording {
                    stopSimulatorRecording()
                } else {
                    startSimulatorRecording()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(simulatorRecording ? Color.orange : Color.white)
                        .frame(width: 74, height: 74)

                    if simulatorRecording {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white)
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "video.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.blue)
                    }
                }
                .shadow(color: .black.opacity(0.2), radius: 8, y: 3)
            }
            .buttonStyle(.plain)

            Text("Fallback recording still enforces 5–15s")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func recordPill(elapsed: TimeInterval, mode: ClipStakesCaptureMode) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill((mode == .camera ? controller.isRecording : simulatorRecording) ? Color.red : Color.green)
                .frame(width: 8, height: 8)
            Text("\(Int(elapsed))s")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
            Text("\(Int(minDuration))–\(Int(maxDuration))s")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .glassEffect(.regular.interactive(), in: Capsule())
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
            let micGranted = await requestMicrophoneAccessIfNeeded()

            guard cameraGranted else {
                errorMessage = "Camera permission is required to record clips."
                return
            }

            if !micGranted {
                errorMessage = "Microphone permission was denied. Recording will continue without audio."
            }

            configureSessionIfNeeded(includeAudio: micGranted)
            startSession()
        }
#endif
    }

    func startRecording() {
        guard isConfigured else { return }
        guard !movieOutput.isRecording else { return }

        errorMessage = nil
        elapsed = 0

        let outputURL = Self.tempMovieURL()
        movieOutput.maxRecordedDuration = CMTime(seconds: maxDuration, preferredTimescale: 600)
        movieOutput.startRecording(to: outputURL, recordingDelegate: self)
    }

    func stopRecording() {
        guard movieOutput.isRecording else { return }
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

    private func requestMicrophoneAccessIfNeeded() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            return await requestAccess(for: .audio)
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
                self.isSessionRunning = self.session.isRunning
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

        if let error {
            errorMessage = error.localizedDescription
            return
        }

        let asset = AVURLAsset(url: outputURL)
        let duration = CMTimeGetSeconds(asset.duration)

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
            .appendingPathComponent("clipstakes-\(UUID().uuidString).mp4")
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
