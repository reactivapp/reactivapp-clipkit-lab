import SwiftUI

// MARK: - Phase State Machine

enum StageswagPhase: Equatable {
    case setlist
    case songMerch(songId: UUID)
    case checkout
    case reward
}

// MARK: - Clip Experience

struct StageswagClipExperience: ClipExperience {
    static let urlPattern = "example.com/stageswag/:showId"
    static let clipName = "StageSwag"
    static let clipDescription = "Setlist-driven merch store — each song unlocks exclusive gear live at the show."
    static let teamName = "StageSwag"
    static let touchpoint: JourneyTouchpoint = .showDay
    static let invocationSource: InvocationSource = .qrCode

    let context: ClipContext

    @State private var phase: StageswagPhase = .setlist
    @State private var cart: [StageswagCartItem] = []
    @State private var selectedTheme: StageswagTheme = .neonNight
    @State private var launchDate = Date()

    var body: some View {
        ZStack {
            StageswagBackground(theme: selectedTheme)

            switch phase {
            case .setlist:
                StageswagSetlistView(
                    songs: StageswagMockData.songs,
                    theme: selectedTheme,
                    launchDate: launchDate,
                    selectedTheme: $selectedTheme,
                    onSongTap: { song in
                        withAnimation(.spring(duration: 0.35)) {
                            phase = .songMerch(songId: song.id)
                        }
                    },
                    cartCount: cart.count,
                    onCheckout: {
                        withAnimation(.spring(duration: 0.35)) {
                            phase = .checkout
                        }
                    }
                )
                .transition(.move(edge: .leading).combined(with: .opacity))

            case .songMerch(let songId):
                if let song = StageswagMockData.songs.first(where: { $0.id == songId }) {
                    StageswagSongMerchView(
                        song: song,
                        theme: selectedTheme,
                        cartCount: cart.count,
                        onAddToCart: { item in
                            withAnimation(.spring(duration: 0.3)) {
                                cart.append(item)
                            }
                        },
                        onBack: {
                            withAnimation(.spring(duration: 0.35)) {
                                phase = .setlist
                            }
                        },
                        onCheckout: {
                            withAnimation(.spring(duration: 0.35)) {
                                phase = .checkout
                            }
                        }
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }

            case .checkout:
                StageswagCheckoutView(
                    cartItems: cart,
                    theme: selectedTheme,
                    onBack: {
                        withAnimation(.spring(duration: 0.35)) {
                            phase = .setlist
                        }
                    },
                    onPay: {
                        withAnimation(.spring(duration: 0.35)) {
                            phase = .reward
                        }
                    }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))

            case .reward:
                StageswagRewardView(theme: selectedTheme)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: phase)
    }
}
