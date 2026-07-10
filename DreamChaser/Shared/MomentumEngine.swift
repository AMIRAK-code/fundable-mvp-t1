import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Momentum: one 0–100 number blending today's routine completion, streak,
/// diet adherence, and last night's sleep — plus the streak-freeze token
/// economy. State that must survive app/widget process boundaries lives in
/// the App Group defaults.
enum MomentumEngine {
    private static var defaults: UserDefaults { AppGroup.defaults }

    private enum Keys {
        static let tokens = "streakTokens.v1"
        static let protectedDates = "protectedDates.v1"
        static let lastTokenWeek = "lastTokenWeek.v1"
        static let cachedScore = "momentumScore.v1"
        static let cachedScoreDay = "momentumScoreDay.v1"
        static let cachedStreak = "momentumStreak.v1"
        static let lastSleepHours = "lastSleepHours.v1"
    }

    // MARK: - Streak freeze tokens

    /// Tokens earned by perfect weeks; each one silently covers a missed day
    /// so a single bad day can't torch a long streak. Capped at 3.
    static var tokens: Int {
        get { defaults.integer(forKey: Keys.tokens) }
        set { defaults.set(newValue, forKey: Keys.tokens) }
    }

    /// Days a token was spent on — they count as active for streak math.
    static var protectedDates: Set<String> {
        get { Set(defaults.stringArray(forKey: Keys.protectedDates) ?? []) }
        set { defaults.set(Array(newValue), forKey: Keys.protectedDates) }
    }

    static func activeDays(items: [RoutineItem]) -> Set<String> {
        var days = Set<String>()
        for item in items {
            days.formUnion(item.completedDates)
        }
        days.formUnion(protectedDates)
        return days
    }

    static func streak(items: [RoutineItem]) -> Int {
        Dates.streak(days: activeDays(items: items))
    }

    /// Run once per foreground: earn a token after a perfect week (every
    /// current item checked on each of the last 7 days, one grant per
    /// calendar week), and spend one to bridge yesterday if it broke a chain.
    static func runDailyMaintenance(items: [RoutineItem]) {
        guard !items.isEmpty else { return }
        let calendar = Calendar.current

        // Earn
        let lastSevenDays = Dates.recentKeys(count: 7)
        let perfectWeek = lastSevenDays.allSatisfy { day in
            items.allSatisfy { $0.isDone(on: day) }
        }
        let weekStamp = "\(calendar.component(.yearForWeekOfYear, from: .now))-W\(calendar.component(.weekOfYear, from: .now))"
        if perfectWeek, defaults.string(forKey: Keys.lastTokenWeek) != weekStamp, tokens < 3 {
            tokens += 1
            defaults.set(weekStamp, forKey: Keys.lastTokenWeek)
        }

        // Spend
        guard
            let yesterday = calendar.date(byAdding: .day, value: -1, to: .now),
            let dayBefore = calendar.date(byAdding: .day, value: -2, to: .now)
        else { return }
        var completions = Set<String>()
        for item in items {
            completions.formUnion(item.completedDates)
        }
        let yesterdayKey = Dates.key(for: yesterday)
        let dayBeforeKey = Dates.key(for: dayBefore)
        let missedYesterday = !completions.contains(yesterdayKey) && !protectedDates.contains(yesterdayKey)
        let hadChain = completions.contains(dayBeforeKey) || protectedDates.contains(dayBeforeKey)
        if missedYesterday, hadChain, tokens > 0 {
            tokens -= 1
            var protected = protectedDates
            protected.insert(yesterdayKey)
            protectedDates = protected
        }
    }

    // MARK: - Momentum score

    /// 45% today's routine, 20% streak (saturates at 14 days), 20% diet
    /// adherence over 7 days, 15% sleep vs. an 8h target. Missing signals
    /// count as neutral (50%) so a new user isn't punished for empty data.
    static func score(routineCompletion: Double, streakDays: Int, dietRatio: Double?, sleepHours: Double?) -> Int {
        var value = 0.45 * max(0, min(1, routineCompletion))
        value += 0.20 * min(Double(streakDays), 14) / 14
        value += 0.20 * (dietRatio ?? 0.5)
        if let sleepHours, sleepHours > 0 {
            value += 0.15 * min(sleepHours / 8.0, 1.0)
        } else {
            value += 0.15 * 0.5
        }
        return Int((value * 100).rounded())
    }

    /// The app caches the full score (it has HealthKit + diet data); widgets
    /// read the cache and only recompute the routine part as a fallback.
    static func cache(score: Int, streak: Int) {
        defaults.set(score, forKey: Keys.cachedScore)
        defaults.set(streak, forKey: Keys.cachedStreak)
        defaults.set(Dates.key(), forKey: Keys.cachedScoreDay)
    }

    static func cachedScore() -> (score: Int, streak: Int)? {
        guard defaults.string(forKey: Keys.cachedScoreDay) == Dates.key() else { return nil }
        return (defaults.integer(forKey: Keys.cachedScore), defaults.integer(forKey: Keys.cachedStreak))
    }

    // MARK: - Sleep cache (for widgets + burnout guardrail)

    static var lastSleepHours: Double? {
        let value = defaults.double(forKey: Keys.lastSleepHours)
        return value > 0 ? value : nil
    }

    static func cacheSleep(hours: Double) {
        defaults.set(hours, forKey: Keys.lastSleepHours)
    }
}
