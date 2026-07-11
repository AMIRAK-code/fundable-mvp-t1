#if canImport(WidgetKit)
import WidgetKit
import SwiftUI

/// One timeline entry shared by the iOS and watchOS widget extensions.
/// Snapshots everything the widget views need from the persisted state.
struct SmokeLessEntry: TimelineEntry {
    let date: Date
    let onboarded: Bool
    let streakDays: Int
    let moneySaved: Double
    let currencyCode: String
    let unitsAvoided: Double
    let resisted: Int
    let themeID: String
    let wishName: String?
    let wishEmoji: String
    let wishProgress: Double

    var theme: AppTheme { AppTheme.theme(withID: themeID) }

    static func make(at date: Date) -> SmokeLessEntry {
        guard let state = Persistence.load(), state.onboardingComplete else {
            return SmokeLessEntry(
                date: date, onboarded: false, streakDays: 0, moneySaved: 0,
                currencyCode: "USD", unitsAvoided: 0, resisted: 0,
                themeID: "mint", wishName: nil, wishEmoji: "🎁", wishProgress: 0
            )
        }
        let stats = Stats(state: state, now: date)
        let wish = state.wishlist
            .filter { $0.purchasedAt == nil }
            .sorted { $0.createdAt < $1.createdAt }
            .first
        var wishProgress: Double = 0
        if let wish, wish.price > 0 {
            wishProgress = min(1, stats.availableSavings / wish.price)
        }
        return SmokeLessEntry(
            date: date,
            onboarded: true,
            streakDays: stats.streakDays,
            moneySaved: stats.moneySaved,
            currencyCode: state.profile.currencyCode,
            unitsAvoided: stats.unitsAvoided,
            resisted: stats.resistedCount,
            themeID: state.themeID,
            wishName: wish?.name,
            wishEmoji: wish?.emoji ?? "🎁",
            wishProgress: wishProgress
        )
    }

    static var preview: SmokeLessEntry {
        SmokeLessEntry(
            date: Date(), onboarded: true, streakDays: 12, moneySaved: 86.4,
            currencyCode: "USD", unitsAvoided: 180, resisted: 23,
            themeID: "mint", wishName: "Wireless earbuds", wishEmoji: "🎧",
            wishProgress: 0.62
        )
    }
}

struct SmokeLessProvider: TimelineProvider {
    func placeholder(in context: Context) -> SmokeLessEntry {
        .preview
    }

    func getSnapshot(in context: Context, completion: @escaping (SmokeLessEntry) -> Void) {
        completion(context.isPreview ? .preview : SmokeLessEntry.make(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SmokeLessEntry>) -> Void) {
        // Hourly entries so money saved keeps ticking up between reloads.
        let now = Date()
        var entries: [SmokeLessEntry] = []
        for hour in 0..<12 {
            if let entryDate = Calendar.current.date(byAdding: .hour, value: hour, to: now) {
                entries.append(SmokeLessEntry.make(at: entryDate))
            }
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}
#endif
