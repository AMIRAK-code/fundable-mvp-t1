import Foundation

enum TimeOfDay: String, Codable, CaseIterable, Identifiable {
    case morning, evening

    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var symbol: String { self == .morning ? "sun.max.fill" : "moon.stars.fill" }
}

struct RoutineStep: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    /// Short explanation of why this step is in the plan — shown on demand.
    let why: String
    let timeOfDay: TimeOfDay
    /// Active weekdays, 1 = Sunday … 7 = Saturday (Calendar.weekday).
    let weekdays: Set<Int>
    let frequencyLabel: String
    let icon: String

    func isActive(on date: Date, calendar: Calendar = .current) -> Bool {
        weekdays.contains(calendar.component(.weekday, from: date))
    }
}

struct HairRoutine: Codable, Hashable {
    let generatedAt: Date
    let washesPerWeek: Int
    let headline: String
    let focusAreas: [String]
    let rationale: [String]
    let steps: [RoutineStep]

    func steps(for date: Date) -> [RoutineStep] {
        steps.filter { $0.isActive(on: date) }
    }

    func steps(for date: Date, at time: TimeOfDay) -> [RoutineStep] {
        steps(for: date).filter { $0.timeOfDay == time }
    }
}
