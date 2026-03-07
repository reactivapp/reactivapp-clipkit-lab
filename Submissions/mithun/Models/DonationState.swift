import SwiftUI
internal import Combine

enum DonationScreen: Equatable {
    case landing
    case amount
    case payment
    case confirmation
}

final class DonationState: ObservableObject {
    @Published var currentScreen: DonationScreen = .landing
    @Published var selectedAmount: Int = 10
    @Published var selectedCause: String
    @Published var roundUpSelected: Bool = false
    @Published var causeDirection: String = ""
    @Published var isProcessingPayment: Bool = false

    init(causeId: String = "hamilton-food-share") {
        self.selectedCause = causeId
        let cause = CauseData.cause(for: causeId)
        if let first = cause.causeOptions.first {
            self.causeDirection = first
        }
    }

    var cause: CauseData {
        CauseData.cause(for: selectedCause)
    }

    var finalAmount: Int {
        roundUpSelected && selectedAmount == 10 ? 12 : selectedAmount
    }

    var impactLabel: String {
        switch selectedAmount {
        case 5: return "Feed 1 child today"
        case 10: return "Feed a family for a day"
        case 25: return "Stock a shelf for a week"
        default: return "Make a difference today"
        }
    }
}
