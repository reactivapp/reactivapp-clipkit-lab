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

    var mealsProvided: Int {
        max(Int(Double(finalAmount) / cause.costPerMeal), 1)
    }

    var impactLabel: String {
        let meals = mealsProvided
        if meals == 1 {
            return "Provide 1 meal today"
        }
        return "Provide \(meals) meals today"
    }
}
