import Foundation

struct CauseData: Identifiable {
    let id: String
    let name: String
    let city: String
    let foundedYear: Int
    let mealsToday: Int
    let dailyGoal: Int
    let donorsThisWeek: Int
    let scenario: String
    let causeOptions: [String]

    var progress: Double {
        guard dailyGoal > 0 else { return 0 }
        return Double(mealsToday) / Double(dailyGoal)
    }

    static let allCauses: [CauseData] = [
        CauseData(
            id: "hamilton-food-share",
            name: "Hamilton Food Share",
            city: "Hamilton, ON",
            foundedYear: 1984,
            mealsToday: 848,
            dailyGoal: 1000,
            donorsThisWeek: 94,
            scenario: "A single mom skipped lunch so her kids could eat. Your gift means she doesn't have to choose.",
            causeOptions: ["Emergency food hampers", "Children's breakfast"]
        ),
        CauseData(
            id: "toronto-daily-bread",
            name: "Daily Bread Food Bank",
            city: "Toronto, ON",
            foundedYear: 1983,
            mealsToday: 1204,
            dailyGoal: 1500,
            donorsThisWeek: 217,
            scenario: "A retired teacher lines up before dawn. Your gift keeps the shelves stocked when she arrives.",
            causeOptions: ["Hot meal programs", "Grocery essentials"]
        ),
        CauseData(
            id: "vancouver-food-bank",
            name: "Greater Vancouver Food Bank",
            city: "Vancouver, BC",
            foundedYear: 1982,
            mealsToday: 673,
            dailyGoal: 900,
            donorsThisWeek: 156,
            scenario: "A student chose rent over food this month. Your gift makes sure no one goes hungry tonight.",
            causeOptions: ["Community kitchen", "Student meal packs"]
        ),
    ]

    static func cause(for id: String) -> CauseData {
        allCauses.first { $0.id == id } ?? allCauses[0]
    }
}
