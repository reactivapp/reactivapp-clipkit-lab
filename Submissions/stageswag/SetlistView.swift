import SwiftUI

struct StageswagSetlistView: View {
    let songs: [StageswagSong]
    let theme: StageswagTheme
    let launchDate: Date
    @Binding var selectedTheme: StageswagTheme
    let onSongTap: (StageswagSong) -> Void
    let cartCount: Int
    let onCheckout: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(launchDate)

            ScrollView {
                VStack(spacing: 0) {
                    GeometryReader { geo in
                        let minY = geo.frame(in: .named("stageswagScroll")).minY
                        StageswagParallaxHeader(
                            band: StageswagMockData.band,
                            theme: theme,
                            minY: minY
                        )
                    }
                    .frame(height: 220)

                    VStack(spacing: 14) {
                        StageswagThemePicker(selectedTheme: $selectedTheme)
                            .padding(.top, 16)

                        sectionHeader("TONIGHT'S SETLIST")

                        ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                            let isUnlocked = elapsed >= song.unlockOffset
                            let secondsLeft = max(0, Int(song.unlockOffset - elapsed))

                            StageswagSongRow(
                                song: song,
                                isUnlocked: isUnlocked,
                                secondsUntilUnlock: secondsLeft,
                                theme: theme,
                                onTap: { onSongTap(song) }
                            )
                            .padding(.horizontal, 16)
                            .offset(y: staggerOffset(for: index))
                            .opacity(staggerOpacity(for: index))
                            .animation(.spring(duration: 0.4).delay(Double(index) * 0.05), value: elapsed > 0)
                        }

                        if cartCount > 0 {
                            cartBanner
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            .coordinateSpace(name: "stageswagScroll")
            .scrollIndicators(.hidden)
            .animation(.spring(duration: 0.3), value: cartCount)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(theme.textHighlight.opacity(0.6))
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func staggerOffset(for index: Int) -> CGFloat {
        0
    }

    private func staggerOpacity(for index: Int) -> Double {
        1.0
    }

    private var cartBanner: some View {
        Button(action: onCheckout) {
            HStack(spacing: 10) {
                Image(systemName: "bag.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("View Cart (\(cartCount))")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(theme.accentColor, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}
