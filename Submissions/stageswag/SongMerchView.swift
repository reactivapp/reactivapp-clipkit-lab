import SwiftUI

struct StageswagSongMerchView: View {
    let song: StageswagSong
    let theme: StageswagTheme
    let cartCount: Int
    let onAddToCart: (StageswagCartItem) -> Void
    let onBack: () -> Void
    let onCheckout: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                songHeader
                    .padding(.top, 12)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(song.merchItems) { item in
                        StageswagMerchCard(item: item, theme: theme) { size in
                            let cartItem = StageswagCartItem(merchItem: item, size: size)
                            onAddToCart(cartItem)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .top) {
            backBar
        }
        .safeAreaInset(edge: .bottom) {
            if cartCount > 0 {
                stageswagCartBanner(cartCount: cartCount, theme: theme, onCheckout: onCheckout)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: cartCount)
    }

    private var backBar: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Setlist")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(theme.accentColor)
            }
            Spacer()
            if cartCount > 0 {
                Button(action: onCheckout) {
                    HStack(spacing: 4) {
                        Image(systemName: "bag.fill")
                            .font(.system(size: 14))
                        Text("\(cartCount)")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(theme.accentColor, in: Capsule())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: Rectangle())
    }

    private var songHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [song.accentColor.opacity(0.3), song.accentColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)

                Image(systemName: "music.note")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(song.accentColor)
            }

            VStack(spacing: 4) {
                Text("Track \(song.trackNumber)")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(song.accentColor.opacity(0.7))

                Text(song.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.primary)

                Text("Exclusive merch — only available now")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
    }
}
