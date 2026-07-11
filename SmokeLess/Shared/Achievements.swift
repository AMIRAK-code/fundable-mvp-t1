import Foundation

/// Badge definitions evaluated live against `Stats` — nothing extra to persist.
struct Achievement: Identifiable {
    enum Requirement {
        case streakDays(Int)
        case moneySaved(Double)
        case cravingsResisted(Int)
        case unitsAvoided(Double)
    }

    let id: String
    let title: String
    let detail: String
    let symbol: String
    let requirement: Requirement

    func progress(with stats: Stats) -> Double {
        let fraction: Double
        switch requirement {
        case .streakDays(let days):
            fraction = Double(stats.streakDays) / Double(days)
        case .moneySaved(let amount):
            fraction = stats.moneySaved / amount
        case .cravingsResisted(let count):
            fraction = Double(stats.resistedCount) / Double(count)
        case .unitsAvoided(let units):
            fraction = stats.unitsAvoided / units
        }
        return min(1, max(0, fraction))
    }

    func isUnlocked(with stats: Stats) -> Bool {
        progress(with: stats) >= 1
    }

    static let all: [Achievement] = [
        Achievement(id: "day1", title: "First Sunrise", detail: "Complete your first full day", symbol: "sunrise.fill", requirement: .streakDays(1)),
        Achievement(id: "day3", title: "Three's Momentum", detail: "Reach a 3-day streak", symbol: "flame.fill", requirement: .streakDays(3)),
        Achievement(id: "day7", title: "One Week Wonder", detail: "Reach a 7-day streak", symbol: "calendar", requirement: .streakDays(7)),
        Achievement(id: "day14", title: "Fortnight Fighter", detail: "Reach a 14-day streak", symbol: "bolt.fill", requirement: .streakDays(14)),
        Achievement(id: "day30", title: "Monthly Master", detail: "Reach a 30-day streak", symbol: "crown.fill", requirement: .streakDays(30)),
        Achievement(id: "day90", title: "Quarter Champion", detail: "Reach a 90-day streak", symbol: "trophy.fill", requirement: .streakDays(90)),
        Achievement(id: "day365", title: "One Year Free", detail: "Reach a 365-day streak", symbol: "star.circle.fill", requirement: .streakDays(365)),
        Achievement(id: "save10", title: "Coffee Money", detail: "Save your first 10", symbol: "cup.and.saucer.fill", requirement: .moneySaved(10)),
        Achievement(id: "save100", title: "Serious Saver", detail: "Save 100", symbol: "banknote.fill", requirement: .moneySaved(100)),
        Achievement(id: "save500", title: "Big Spender (Not)", detail: "Save 500", symbol: "building.columns.fill", requirement: .moneySaved(500)),
        Achievement(id: "resist1", title: "Wave Rider", detail: "Resist your first craving", symbol: "hand.raised.fill", requirement: .cravingsResisted(1)),
        Achievement(id: "resist10", title: "Iron Will", detail: "Resist 10 cravings", symbol: "shield.lefthalf.filled", requirement: .cravingsResisted(10)),
        Achievement(id: "resist50", title: "Unshakeable", detail: "Resist 50 cravings", symbol: "mountain.2.fill", requirement: .cravingsResisted(50)),
        Achievement(id: "avoid100", title: "Century Avoided", detail: "Avoid 100 units", symbol: "nosign", requirement: .unitsAvoided(100)),
        Achievement(id: "avoid1000", title: "Thousand Strong", detail: "Avoid 1,000 units", symbol: "sparkles", requirement: .unitsAvoided(1000))
    ]
}
