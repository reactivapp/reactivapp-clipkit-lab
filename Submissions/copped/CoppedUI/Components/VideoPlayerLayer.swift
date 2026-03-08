import SwiftUI
import AVFoundation

// MARK: - VideoPlayerLayer

/// Muted, auto-playing, looping video layer.
/// Wraps AVPlayer in a UIViewRepresentable for SwiftUI.
public struct VideoPlayerLayer: View {
  let url: URL
  var isMuted: Bool = true
  var loops: Bool = true
  var onPlaybackStarted: (() -> Void)? = nil
  var onPlaybackEnded: (() -> Void)? = nil
  var onError: ((Error) -> Void)? = nil

  public init(
    url: URL,
    isMuted: Bool = true,
    loops: Bool = true,
    onPlaybackStarted: (() -> Void)? = nil,
    onPlaybackEnded: (() -> Void)? = nil,
    onError: ((Error) -> Void)? = nil
  ) {
    self.url = url
    self.isMuted = isMuted
    self.loops = loops
    self.onPlaybackStarted = onPlaybackStarted
    self.onPlaybackEnded = onPlaybackEnded
    self.onError = onError
  }

  public var body: some View {
    _AVPlayerView(url: url, isMuted: isMuted, loops: loops,
                  onPlaybackStarted: onPlaybackStarted, onPlaybackEnded: onPlaybackEnded, onError: onError)
  }
}

// MARK: - _AVPlayerView

private struct _AVPlayerView: UIViewRepresentable {
  let url: URL
  let isMuted: Bool
  let loops: Bool
  var onPlaybackStarted: (() -> Void)?
  var onPlaybackEnded: (() -> Void)?
  var onError: ((Error) -> Void)?

  func makeUIView(context: Context) -> _PlayerUIView {
    let view = _PlayerUIView(url: url, isMuted: isMuted, loops: loops,
                              onPlaybackStarted: onPlaybackStarted, onPlaybackEnded: onPlaybackEnded, onError: onError)
    return view
  }

  func updateUIView(_ uiView: _PlayerUIView, context: Context) {
    uiView.onPlaybackStarted = onPlaybackStarted
    uiView.onPlaybackEnded = onPlaybackEnded
    uiView.onError = onError
    if uiView.currentURL != url {
      uiView.load(url: url, isMuted: isMuted, loops: loops)
    }
  }
}

// MARK: - _PlayerUIView

final class _PlayerUIView: UIView {
  private var player: AVPlayer?
  private var playerLayer: AVPlayerLayer?
  private var loopObserver: NSObjectProtocol?
  private var statusObserver: NSKeyValueObservation?
  private(set) var currentURL: URL?
  var onPlaybackStarted: (() -> Void)?
  var onPlaybackEnded: (() -> Void)?
  var onError: ((Error) -> Void)?

  override class var layerClass: AnyClass { AVPlayerLayer.self }

  init(url: URL, isMuted: Bool, loops: Bool,
       onPlaybackStarted: (() -> Void)? = nil, onPlaybackEnded: (() -> Void)? = nil, onError: ((Error) -> Void)? = nil) {
    self.onPlaybackStarted = onPlaybackStarted
    self.onPlaybackEnded = onPlaybackEnded
    self.onError = onError
    super.init(frame: .zero)
    load(url: url, isMuted: isMuted, loops: loops)
  }

  required init?(coder: NSCoder) { fatalError() }

  func load(url: URL, isMuted: Bool, loops: Bool) {
    currentURL = url
    loopObserver.map { NotificationCenter.default.removeObserver($0) }
    statusObserver?.invalidate()

    let item = AVPlayerItem(url: url)
    let player = AVPlayer(playerItem: item)
    player.isMuted = isMuted
    player.play()
    self.player = player

    let layer = self.layer as! AVPlayerLayer
    layer.player = player
    layer.videoGravity = .resizeAspectFill

    statusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
      DispatchQueue.main.async {
        switch item.status {
        case .readyToPlay:
          self?.onPlaybackStarted?()
        case .failed:
          if let error = item.error {
            self?.onError?(error)
          }
        default:
          break
        }
      }
    }

    loopObserver = NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: item,
      queue: .main
    ) { [weak self, weak player] _ in
      self?.onPlaybackEnded?()
      if loops {
        player?.seek(to: .zero)
        player?.play()
      }
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    (layer as? AVPlayerLayer)?.frame = bounds
  }

  deinit {
    loopObserver.map { NotificationCenter.default.removeObserver($0) }
    statusObserver?.invalidate()
  }
}

// MARK: - VideoProgressBar

/// Thin progress bar overlay for video playback position.
public struct VideoProgressBar: View {
  @Binding var progress: Double // 0.0 – 1.0
  var color: Color = .white
  var trackColor: Color = .white.opacity(0.3)
  var height: CGFloat = 2

  public init(progress: Binding<Double>, color: Color = .white, height: CGFloat = 2) {
    self._progress = progress
    self.color = color
    self.height = height
  }

  public var body: some View {
    GeometryReader { geo in
      ZStack(alignment: .leading) {
        Rectangle()
          .fill(trackColor)
          .frame(height: height)

        Rectangle()
          .fill(color)
          .frame(width: geo.size.width * CGFloat(progress), height: height)
      }
    }
    .frame(height: height)
  }
}
