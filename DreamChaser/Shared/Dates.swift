import Foundation

/// Day-key helpers. Every daily check-in is stored against a "yyyy-MM-dd" key
/// in the user's current time zone, which keeps streak math simple and avoids
/// storing one model object per day.
enum Dates {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func key(for date: Date = .now) -> String {
        formatter.string(from: date)
    }

    static func date(fromKey key: String) -> Date? {
        formatter.date(from: key)
    }

    static var startOfTomorrow: Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: .now) ?? .now
        return calendar.startOfDay(for: tomorrow)
    }

    /// Consecutive-day streak ending today (or yesterday, so an unfinished
    /// "today" doesn't kill the streak before the day is over).
    static func streak(days: Set<String>, endingAt date: Date = .now) -> Int {
        let calendar = Calendar.current
        var day = date
        if !days.contains(key(for: day)) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var count = 0
        while days.contains(key(for: day)) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    /// The last `count` day keys, oldest first, ending today.
    static func recentKeys(count: Int, endingAt date: Date = .now) -> [String] {
        let calendar = Calendar.current
        return (0..<count).compactMap { offset in
            calendar.date(byAdding: .day, value: -(count - 1 - offset), to: date).map(key(for:))
        }
    }
}
