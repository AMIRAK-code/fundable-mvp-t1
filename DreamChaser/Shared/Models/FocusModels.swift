import Foundation
import SwiftData

/// A completed deep-focus session started from a routine section. Minutes
/// feed the weekly review.
@Model
final class FocusSession {
    var sectionName: String
    var minutes: Int
    var dateKey: String
    var endedAt: Date

    init(sectionName: String, minutes: Int, endedAt: Date = .now) {
        self.sectionName = sectionName
        self.minutes = minutes
        self.dateKey = Dates.key(for: endedAt)
        self.endedAt = endedAt
    }
}
