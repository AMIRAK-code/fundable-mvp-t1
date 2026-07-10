import Foundation
import SwiftData

/// The user's "ultimate goal", broken down into ordered mini goals that must
/// be completed sequentially — a ladder, not a list.
@Model
final class UltimateGoal {
    var title: String
    var why: String
    var targetDate: Date?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \MiniGoal.goal)
    var miniGoals: [MiniGoal]

    init(title: String, why: String = "", targetDate: Date? = nil) {
        self.title = title
        self.why = why
        self.targetDate = targetDate
        self.createdAt = .now
        self.miniGoals = []
    }

    var sortedMiniGoals: [MiniGoal] {
        miniGoals.sorted { $0.sortOrder < $1.sortOrder }
    }

    var completedCount: Int {
        miniGoals.filter(\.isCompleted).count
    }

    var progress: Double {
        miniGoals.isEmpty ? 0 : Double(completedCount) / Double(miniGoals.count)
    }

    var isAchieved: Bool {
        !miniGoals.isEmpty && completedCount == miniGoals.count
    }

    /// The next rung of the ladder — first uncompleted mini goal in order.
    var nextMiniGoal: MiniGoal? {
        sortedMiniGoals.first { !$0.isCompleted }
    }
}

@Model
final class MiniGoal {
    var title: String
    var sortOrder: Int
    var isCompleted: Bool
    var completedAt: Date?
    var goal: UltimateGoal?

    init(title: String, sortOrder: Int) {
        self.title = title
        self.sortOrder = sortOrder
        self.isCompleted = false
    }
}
