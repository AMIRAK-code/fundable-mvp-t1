import Foundation
import SwiftData

/// One day's diet check-in: did you stick to your plan?
@Model
final class DietDay {
    var dateKey: String
    var stuckToDiet: Bool
    var note: String

    init(dateKey: String, stuckToDiet: Bool, note: String = "") {
        self.dateKey = dateKey
        self.stuckToDiet = stuckToDiet
        self.note = note
    }
}

/// A step of the skincare routine, split into morning and evening.
@Model
final class SkincareStep {
    var title: String
    var timeOfDay: String // "morning" | "evening"
    var sortOrder: Int
    var completedDates: [String]

    init(title: String, timeOfDay: String, sortOrder: Int) {
        self.title = title
        self.timeOfDay = timeOfDay
        self.sortOrder = sortOrder
        self.completedDates = []
    }

    func isDone(on dayKey: String) -> Bool {
        completedDates.contains(dayKey)
    }

    func toggle(on dayKey: String) {
        if let index = completedDates.firstIndex(of: dayKey) {
            completedDates.remove(at: index)
        } else {
            completedDates.append(dayKey)
        }
    }
}

/// The recurring "reset your space" task. Due every `frequencyDays` after the
/// last completion; the app surfaces a prompt card when due and can also fire
/// a weekly notification.
@Model
final class CleaningTask {
    var name: String
    var frequencyDays: Int
    var completedDates: [String]
    var snoozedUntil: Date?
    var createdAt: Date

    init(name: String = "Weekly room reset", frequencyDays: Int = 7) {
        self.name = name
        self.frequencyDays = frequencyDays
        self.completedDates = []
        self.createdAt = .now
    }

    var lastCompleted: Date? {
        completedDates.compactMap(Dates.date(fromKey:)).max()
    }

    var nextDue: Date {
        guard let last = lastCompleted else { return createdAt }
        return Calendar.current.date(byAdding: .day, value: frequencyDays, to: last) ?? last
    }

    var isDue: Bool {
        if let snoozedUntil, snoozedUntil > .now { return false }
        return nextDue <= .now
    }

    func markDone(on date: Date = .now) {
        let key = Dates.key(for: date)
        if !completedDates.contains(key) {
            completedDates.append(key)
        }
        snoozedUntil = nil
    }

    func snooze(days: Int = 1) {
        snoozedUntil = Calendar.current.date(byAdding: .day, value: days, to: .now)
    }
}
