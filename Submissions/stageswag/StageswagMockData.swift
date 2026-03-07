import SwiftUI

// MARK: - Mock Data

enum StageswagMockData {
    static let band = StageswagBand(
        name: "The Voltage Thieves",
        tourName: "Electric Reckoning Tour",
        venue: "Rogers Centre, Toronto",
        genre: "Indie Electronic",
        date: "Tonight"
    )

    static let songs: [StageswagSong] = [
        StageswagSong(
            trackNumber: 1,
            title: "Electric Reckoning",
            unlockOffset: 0,
            accentColor: Color(stageswagHex: "#06B6D4"),
            merchItems: [
                StageswagMerchItem(name: "Electric Reckoning Tee", price: 45.00, icon: "tshirt.fill", isApparel: true, songTitle: "Electric Reckoning", accentColor: Color(stageswagHex: "#06B6D4")),
                StageswagMerchItem(name: "Reckoning Enamel Pin", price: 12.00, icon: "seal.fill", isApparel: false, songTitle: "Electric Reckoning", accentColor: Color(stageswagHex: "#06B6D4")),
                StageswagMerchItem(name: "Electric Poster (24x36)", price: 25.00, icon: "photo.artframe", isApparel: false, songTitle: "Electric Reckoning", accentColor: Color(stageswagHex: "#06B6D4")),
            ]
        ),
        StageswagSong(
            trackNumber: 2,
            title: "Neon Heartbreak",
            unlockOffset: 0,
            accentColor: Color(stageswagHex: "#EC4899"),
            merchItems: [
                StageswagMerchItem(name: "Neon Heartbreak Hoodie", price: 65.00, icon: "tshirt.fill", isApparel: true, songTitle: "Neon Heartbreak", accentColor: Color(stageswagHex: "#EC4899")),
                StageswagMerchItem(name: "Heartbreak Vinyl Single", price: 18.00, icon: "opticaldisc.fill", isApparel: false, songTitle: "Neon Heartbreak", accentColor: Color(stageswagHex: "#EC4899")),
            ]
        ),
        StageswagSong(
            trackNumber: 3,
            title: "Voltage",
            unlockOffset: 3,
            accentColor: Color(stageswagHex: "#FACC15"),
            merchItems: [
                StageswagMerchItem(name: "Voltage Crop Top", price: 40.00, icon: "tshirt.fill", isApparel: true, songTitle: "Voltage", accentColor: Color(stageswagHex: "#FACC15")),
                StageswagMerchItem(name: "Lightning Bolt Patch", price: 8.00, icon: "seal.fill", isApparel: false, songTitle: "Voltage", accentColor: Color(stageswagHex: "#FACC15")),
                StageswagMerchItem(name: "Voltage Sticker Pack", price: 6.00, icon: "square.stack.fill", isApparel: false, songTitle: "Voltage", accentColor: Color(stageswagHex: "#FACC15")),
            ]
        ),
        StageswagSong(
            trackNumber: 4,
            title: "Burning Chrome",
            unlockOffset: 7,
            accentColor: Color(stageswagHex: "#F97316"),
            merchItems: [
                StageswagMerchItem(name: "Burning Chrome Tank", price: 38.00, icon: "tshirt.fill", isApparel: true, songTitle: "Burning Chrome", accentColor: Color(stageswagHex: "#F97316")),
                StageswagMerchItem(name: "Chrome Beanie", price: 28.00, icon: "tshirt.fill", isApparel: true, songTitle: "Burning Chrome", accentColor: Color(stageswagHex: "#F97316")),
            ]
        ),
        StageswagSong(
            trackNumber: 5,
            title: "Midnight Static",
            unlockOffset: 12,
            accentColor: Color(stageswagHex: "#22C55E"),
            merchItems: [
                StageswagMerchItem(name: "Static Long Sleeve", price: 50.00, icon: "tshirt.fill", isApparel: true, songTitle: "Midnight Static", accentColor: Color(stageswagHex: "#22C55E")),
                StageswagMerchItem(name: "Midnight Tote Bag", price: 22.00, icon: "bag.fill", isApparel: false, songTitle: "Midnight Static", accentColor: Color(stageswagHex: "#22C55E")),
            ]
        ),
        StageswagSong(
            trackNumber: 6,
            title: "The Last Encore",
            unlockOffset: 17,
            accentColor: Color(stageswagHex: "#A855F7"),
            merchItems: [
                StageswagMerchItem(name: "Last Encore Tour Jacket", price: 95.00, icon: "tshirt.fill", isApparel: true, songTitle: "The Last Encore", accentColor: Color(stageswagHex: "#A855F7")),
                StageswagMerchItem(name: "Encore Vinyl LP", price: 35.00, icon: "opticaldisc.fill", isApparel: false, songTitle: "The Last Encore", accentColor: Color(stageswagHex: "#A855F7")),
                StageswagMerchItem(name: "Signed Setlist Print", price: 45.00, icon: "photo.artframe", isApparel: false, songTitle: "The Last Encore", accentColor: Color(stageswagHex: "#A855F7")),
            ]
        ),
    ]
}
