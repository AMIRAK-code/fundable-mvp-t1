import AppIntents
import Foundation
import SwiftData
import WidgetKit

// Intents behind the Siri / Shortcuts phrases ("log my diet", "I cleaned my
// room", "complete my next step"). Exposed via DreamChaserShortcuts in the
// app target.

enum DietStatus: String, AppEnum {
    case onTrack
    case slipped

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Diet Status"
    static var caseDisplayRepresentations: [DietStatus: DisplayRepresentation] = [
        .onTrack: "On track",
        .slipped: "Slipped",
    ]
}

struct LogDietIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Diet Check-In"
    static var description = IntentDescription("Records whether you stuck to your diet today.")

    @Parameter(title: "How did it go?")
    var status: DietStatus

    init() {}

    init(status: DietStatus) {
        self.status = status
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = SharedStore.makeContainer()
        let context = ModelContext(container)
        let key = Dates.key()
        let stuck = status == .onTrack
        let descriptor = FetchDescriptor<DietDay>(predicate: #Predicate { $0.dateKey == key })
        if let existing = try context.fetch(descriptor).first {
            existing.stuckToDiet = stuck
        } else {
            context.insert(DietDay(dateKey: key, stuckToDiet: stuck))
        }
        try context.save()
        WidgetCenter.shared.reloadAllTimelines()
        return .result(dialog: stuck
                       ? "Logged. Keep stacking clean days."
                       : "Logged. Tomorrow you take it back.")
    }
}

struct MarkCleaningDoneIntent: AppIntent {
    static var title: LocalizedStringResource = "Mark Space Reset Done"
    static var description = IntentDescription("Logs your weekly room reset as completed today.")

    init() {}

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = SharedStore.makeContainer()
        let context = ModelContext(container)
        guard let task = try context.fetch(FetchDescriptor<CleaningTask>()).first else {
            return .result(dialog: "No cleaning task set up yet — open Dream Chaser first.")
        }
        task.markDone()
        try context.save()
        return .result(dialog: "Space reset logged. Clean room, clear mind.")
    }
}

struct CompleteNextMiniGoalIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Next Mini Goal"
    static var description = IntentDescription("Checks off the next rung on your goal ladder.")

    init() {}

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = SharedStore.makeContainer()
        let context = ModelContext(container)
        let goals = try context.fetch(
            FetchDescriptor<UltimateGoal>(sortBy: [SortDescriptor(\.createdAt)])
        )
        guard let goal = goals.first else {
            return .result(dialog: "You haven't set an ultimate goal yet.")
        }
        guard let next = goal.nextMiniGoal else {
            return .result(dialog: "Every mini goal for “\(goal.title)” is already done. Time to raise the bar.")
        }
        next.isCompleted = true
        next.completedAt = .now
        try context.save()
        WidgetCenter.shared.reloadAllTimelines()
        return .result(dialog: "“\(next.title)” — done. One rung closer to \(goal.title).")
    }
}
