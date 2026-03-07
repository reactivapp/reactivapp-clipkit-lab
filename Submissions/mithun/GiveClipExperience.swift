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
                    PaymentView(cause: cause)
                case .confirmation:
                    ImpactConfirmationView(cause: cause)
                }
            }
            .animation(.spring(duration: 0.35), value: donationState.currentScreen)
        }
        .environmentObject(donationState)
    }
}
