import Foundation
import SwiftData

/// A customizable block of the user's optimal day: Gym, Study, Work, Plan,
/// Learn a Skill… Users can rename, recolor, and re-icon each one.
@Model
final class RoutineSection {
    var name: String
    var symbol: String
    var colorName: String
    var sortOrder: Int

    @Relationship(deleteRule: .cascade, inverse: \RoutineItem.section)
    var items: [RoutineItem]

    init(name: String, symbol: String, colorName: String, sortOrder: Int) {
        self.name = name
        self.symbol = symbol
        self.colorName = colorName
        self.sortOrder = sortOrder
        self.items = []
    }

    var sortedItems: [RoutineItem] {
        items.sorted { $0.sortOrder < $1.sortOrder }
    }

    func completedCount(on dayKey: String) -> Int {
        items.filter { $0.isDone(on: dayKey) }.count
    }

    func progress(on dayKey: String) -> Double {
        items.isEmpty ? 0 : Double(completedCount(on: dayKey)) / Double(items.count)
    }
}

/// One checkable habit inside a section. Completion history is a set of
/// day keys, which makes daily toggles and streaks cheap.
@Model
final class RoutineItem {
    var uuid: UUID
    var title: String
    var sortOrder: Int
    var completedDates: [String]
    var section: RoutineSection?

    init(title: String, sortOrder: Int) {
        self.uuid = UUID()
        self.title = title
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
