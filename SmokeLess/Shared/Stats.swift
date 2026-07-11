import Foundation

/// Pure derived numbers over an `AppState` at a moment in time.
/// Used by the app, the widgets and the watch so every surface agrees.
struct Stats {
    let state: AppState
    let now: Date

    private var profile: UserProfile { state.profile }
    private var cal: Calendar { Calendar.current }

    // MARK: Money & units

    var elapsedDaysExact: Double {
        max(0, now.timeIntervalSince(profile.startDate) / 86_400)
    }

    var baselineUnits: Double { profile.unitsPerDay * elapsedDaysExact }

    var consumedUnits: Double {
        state.slips
            .filter { $0.date >= profile.startDate && $0.date <= now }
            .reduce(0) { $0 + $1.units }
    }

    var unitsAvoided: Double { max(0, baselineUnits - consumedUnits) }

    var moneySaved: Double { unitsAvoided * profile.pricePerUnit }

    var wishlistSpent: Double {
        state.wishlist
            .filter { $0.purchasedAt != nil }
            .reduce(0) { $0 + $1.price }
    }

    /// Savings still unallocated after wishlist purchases.
    var availableSavings: Double { max(0, moneySaved - wishlistSpent) }

    // MARK: Streak

    var lastSlipDate: Date? { state.slips.map { $0.date }.max() }

    /// The most recent day whose logged total exceeded the reduce-mode allowance.
    var lastOverAllowanceDay: Date? {
        let grouped = Dictionary(grouping: state.slips) { entry in
            cal.startOfDay(for: entry.date)
        }
        let overDays = grouped.compactMap { day, entries -> Date? in
            let total = entries.reduce(0.0) { sum, e in sum + e.units }
            return total > profile.dailyAllowance ? day : nil
        }
        return overDays.max()
    }

    var streakAnchor: Date {
        switch profile.goal {
        case .quitCompletely:
            return lastSlipDate ?? profile.startDate
        case .reduceGradually:
            return lastOverAllowanceDay ?? profile.startDate
        }
    }

    /// Whole calendar days since the streak anchor.
    var streakDays: Int {
        let from = cal.startOfDay(for: streakAnchor)
        let to = cal.startOfDay(for: now)
        return max(0, cal.dateComponents([.day], from: from, to: to).day ?? 0)
    }

    var streakHours: Int {
        max(0, Int(now.timeIntervalSince(streakAnchor) / 3_600))
    }

    var bestStreak: Int { max(state.bestStreakCache, streakDays) }

    var resistedCount: Int { state.resistedCravings.count }

    // MARK: Daily usage

    func units(onDay day: Date) -> Double {
        let target = cal.startOfDay(for: day)
        return state.slips
            .filter { cal.startOfDay(for: $0.date) == target }
            .reduce(0) { $0 + $1.units }
    }

    var todayUnits: Double { units(onDay: now) }

    var lastSevenDays: [(date: Date, units: Double)] {
        var result: [(date: Date, units: Double)] = []
        for offset in stride(from: 6, through: 0, by: -1) {
            if let day = cal.date(byAdding: .day, value: -offset, to: now) {
                result.append((cal.startOfDay(for: day), units(onDay: day)))
            }
        }
        return result
    }

    // MARK: Body recovery

    /// Recovery timelines restart from the last time smoke entered the body.
    var healthAnchor: Date { lastSlipDate ?? profile.startDate }

    var smokeFreeInterval: TimeInterval {
        max(0, now.timeIntervalSince(healthAnchor))
    }
}
