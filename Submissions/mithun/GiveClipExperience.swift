import SwiftUI

struct GiveClipExperience: ClipExperience {
    static let urlPattern = "givekit.ca/cause/:causeId"
    static let clipName = "GiveClip"
    static let clipDescription = "Tap a food bank donation bin. Give in 20 seconds. Watch the counter move."
    static let teamName = "Mithun"
    static let touchpoint: JourneyTouchpoint = .onSite
    static let invocationSource: InvocationSource = .nfcTag

    let context: ClipContext
    @StateObject private var donationState: DonationState

    init(context: ClipContext) {
        self.context = context
        let causeId = context.pathParameters["causeId"] ?? "hamilton-food-share"
        _donationState = StateObject(wrappedValue: DonationState(causeId: causeId))
    }

    private var cause: CauseData {
        donationState.cause
    }

    var body: some View {
        ZStack {
            ClipBackground()

            Group {
                switch donationState.currentScreen {
                case .landing:
                    CauseLandingView(cause: cause)
                case .amount:
                    AmountSelectionView(cause: cause)
                case .payment:
                    paymentPlaceholder
                case .confirmation:
                    confirmationPlaceholder
                }
            }
            .animation(.spring(duration: 0.35), value: donationState.currentScreen)
        }
        .environmentObject(donationState)
    }

    // MARK: - Placeholder screens (replaced in Phases 3–4)

    private var paymentPlaceholder: some View {
        ScrollView {
            VStack(spacing: 20) {
                ClipHeader(
                    title: "Confirm Your Gift",
                    subtitle: "$\(donationState.selectedAmount) to \(cause.name)",
                    systemImage: "creditcard"
                )
                .padding(.top, 16)

                ClipActionButton(title: "Give with Apple Pay", icon: "apple.logo") {
                    withAnimation { donationState.currentScreen = .confirmation }
                }
            }
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
    }

    private var confirmationPlaceholder: some View {
        VStack(spacing: 16) {
            Spacer()
            ClipSuccessOverlay(
                message: "You just fed a family in \(cause.city) today."
            )
            Spacer()
        }
    }
}
