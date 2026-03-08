import SwiftUI

// MARK: - ReelItem

/// Data model for a single reel item. Extend as needed.
public struct ReelItem: Identifiable {
  public let id: String
  public var videoURL: URL?
  public var thumbnailURL: URL?
  public var caption: String
  public var username: String
  public var likes: Int
  public var isLiked: Bool

  public init(
    id: String = UUID().uuidString,
    videoURL: URL? = nil,
    thumbnailURL: URL? = nil,
    caption: String = "",
    username: String = "",
    likes: Int = 0,
    isLiked: Bool = false
  ) {
    self.id = id
    self.videoURL = videoURL
    self.thumbnailURL = thumbnailURL
    self.caption = caption
    self.username = username
    self.likes = likes
    self.isLiked = isLiked
  }
}

// MARK: - ReelsFeed

/// Instagram Reels-style vertical paged feed.
/// Each item fills the entire screen. Swipe up/down to navigate.
public struct ReelsFeed<Item: Identifiable, Content: View>: View {
  let items: [Item]
  @Binding var currentIndex: Int
  let content: (Item) -> Content
  var onIndexChange: ((Int) -> Void)? = nil
  var onReachEnd: (() -> Void)? = nil

  public init(
    items: [Item],
    currentIndex: Binding<Int>,
    onIndexChange: ((Int) -> Void)? = nil,
    onReachEnd: (() -> Void)? = nil,
    @ViewBuilder content: @escaping (Item) -> Content
  ) {
    self.items = items
    self._currentIndex = currentIndex
    self.onIndexChange = onIndexChange
    self.onReachEnd = onReachEnd
    self.content = content
  }

  public var body: some View {
    TabView(selection: $currentIndex) {
      ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
        content(item)
          .tag(index)
          .ignoresSafeArea()
      }
    }
    .tabViewStyle(.page(indexDisplayMode: .never))
    .ignoresSafeArea()
    .onChange(of: currentIndex) { newIndex in
      onIndexChange?(newIndex)
      if newIndex >= items.count - 1 {
        onReachEnd?()
      }
    }
  }
}

// MARK: - Default Reel Cell

/// Drop-in reel cell with overlaid caption, username, and action buttons.
public struct ReelCell: View {
  public let item: ReelItem
  public var onLike: (() -> Void)?
  public var onShare: (() -> Void)?
  public var onComment: (() -> Void)?

  public init(
    item: ReelItem,
    onLike: (() -> Void)? = nil,
    onShare: (() -> Void)? = nil,
    onComment: (() -> Void)? = nil
  ) {
    self.item = item
    self.onLike = onLike
    self.onShare = onShare
    self.onComment = onComment
  }

  public var body: some View {
    ZStack {
      // Background / video placeholder
      Color.black.ignoresSafeArea()

      if let url = item.videoURL {
        VideoPlayerLayer(url: url)
          .ignoresSafeArea()
      }

      // Overlay gradient
      LinearGradient(
        gradient: Gradient(colors: [.clear, .black.opacity(Theme.current.layout.overlay.dim)]),
        startPoint: .center,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      // HUD overlay
      VStack {
        Spacer()
        HStack(alignment: .bottom) {
          // Left: metadata
          VStack(alignment: .leading, spacing: 6) {
            Text("@\(item.username)")
              .font(.custom(Manrope.semiBold, size: 15))
              .foregroundStyle(.white)

            Text(item.caption)
              .font(.custom(Manrope.regular, size: 14))
              .foregroundStyle(.white.opacity(0.9))
              .lineLimit(2)
          }
          .frame(maxWidth: .infinity, alignment: .leading)

          // Right: actions
          VStack(spacing: 20) {
            ReelActionButton(
              icon: item.isLiked ? "heart.fill" : "heart",
              label: formatCount(item.likes),
              tint: item.isLiked ? .red : .white,
              action: onLike
            )
            ReelActionButton(icon: "bubble.right", label: "Reply", action: onComment)
            ReelActionButton(icon: "paperplane", label: "Share", action: onShare)
          }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
      }
    }
  }

  private func formatCount(_ n: Int) -> String {
    n >= 1000 ? String(format: "%.1fK", Double(n) / 1000) : "\(n)"
  }
}

// MARK: - ReelActionButton

private struct ReelActionButton: View {
  let icon: String
  let label: String
  var tint: Color = .white
  var action: (() -> Void)?

  var body: some View {
    Button(action: { action?() }) {
      VStack(spacing: 4) {
        Image(systemName: icon)
          .font(.system(size: 26, weight: .semibold))
          .foregroundStyle(tint)
        Text(label)
          .font(.custom(Manrope.medium, size: 12))
          .foregroundStyle(.white)
      }
    }
  }
}
