import Foundation
import SwiftData

/// Central SwiftData setup shared by the app and the widget extension.
/// The store lives in the App Group container so widgets read (and, via
/// interactive intents, write) the same data as the app.
enum SharedStore {
    static let schema = Schema([
        RoutineSection.self,
        RoutineItem.self,
        UltimateGoal.self,
        MiniGoal.self,
        DietDay.self,
        SkincareStep.self,
        CleaningTask.self,
    ])

    static func makeContainer() -> ModelContainer {
        let grouped = ModelConfiguration(
            "DreamChaser",
            schema: schema,
            groupContainer: .identifier(AppGroup.identifier)
        )
        if let container = try? ModelContainer(for: schema, configurations: [grouped]) {
            return container
        }
        // Fallback keeps the app usable when the App Group isn't configured
        // yet (widgets won't share data until it is — see README).
        let local = ModelConfiguration("DreamChaser-local", schema: schema)
        do {
            return try ModelContainer(for: schema, configurations: [local])
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }

    /// Seeds the default routine, skincare steps, and cleaning task on first
    /// launch. Each group is seeded independently so deleting everything in
    /// one area doesn't resurrect the others.
    static func seedIfNeeded(in container: ModelContainer) {
        let context = ModelContext(container)

        if (try? context.fetchCount(FetchDescriptor<RoutineSection>())) == 0 {
            let defaults: [(String, String, String, [String])] = [
                ("Gym", "dumbbell", "orange", ["Train for 60 minutes", "Hit protein target", "10k steps"]),
                ("Study", "book.fill", "blue", ["Deep-focus study block", "Review notes"]),
                ("Work", "briefcase.fill", "indigo", ["Top priority task first", "Inbox zero by evening"]),
                ("Plan", "calendar", "teal", ["Plan tomorrow before bed", "Review weekly goals"]),
                ("Learn a Skill", "brain.head.profile", "purple", ["30 minutes of practice", "Log one thing you learned"]),
            ]
            for (index, entry) in defaults.enumerated() {
                let section = RoutineSection(name: entry.0, symbol: entry.1, colorName: entry.2, sortOrder: index)
                context.insert(section)
                for (itemIndex, title) in entry.3.enumerated() {
                    let item = RoutineItem(title: title, sortOrder: itemIndex)
                    item.section = section
                    context.insert(item)
                }
            }
        }

        if (try? context.fetchCount(FetchDescriptor<SkincareStep>())) == 0 {
            let morning = ["Cleanser", "Moisturizer", "Sunscreen"]
            let evening = ["Cleanse", "Treatment / serum", "Night moisturizer"]
            for (index, title) in morning.enumerated() {
                context.insert(SkincareStep(title: title, timeOfDay: "morning", sortOrder: index))
            }
            for (index, title) in evening.enumerated() {
                context.insert(SkincareStep(title: title, timeOfDay: "evening", sortOrder: index))
            }
        }

        if (try? context.fetchCount(FetchDescriptor<CleaningTask>())) == 0 {
            context.insert(CleaningTask())
        }

        try? context.save()
    }
}
