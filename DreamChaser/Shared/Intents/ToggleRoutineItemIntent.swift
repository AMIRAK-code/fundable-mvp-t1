import AppIntents
import Foundation
import SwiftData
import WidgetKit

/// Lets widgets (and Siri / Shortcuts) check a routine item off for today
/// without opening the app.
struct ToggleRoutineItemIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Routine Item"
    static var description = IntentDescription("Marks a routine item as done or not done for today.")

    @Parameter(title: "Item ID")
    var itemID: String

    init() {}

    init(itemID: String) {
        self.itemID = itemID
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: itemID) else { return .result() }
        let container = SharedStore.makeContainer()
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<RoutineItem>(predicate: #Predicate { $0.uuid == uuid })
        if let item = try context.fetch(descriptor).first {
            item.toggle(on: Dates.key())
            try context.save()
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
