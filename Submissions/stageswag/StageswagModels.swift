import SwiftUI

// MARK: - Stageswag Data Models

struct StageswagBand {
    let name: String
    let tourName: String
    let venue: String
    let genre: String
    let date: String
}

struct StageswagSong: Identifiable {
    let id = UUID()
    let trackNumber: Int
    let title: String
    let unlockOffset: TimeInterval
    let accentColor: Color
    let merchItems: [StageswagMerchItem]
}

struct StageswagMerchItem: Identifiable {
    let id = UUID()
    let name: String
    let price: Double
    let icon: String
    let isApparel: Bool
    let songTitle: String
    let accentColor: Color
}

struct StageswagCartItem: Identifiable {
    let id = UUID()
    let merchItem: StageswagMerchItem
    let size: String?
}
