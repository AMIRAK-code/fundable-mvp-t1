import ActivityKit
import Foundation

/// Live Activity payload for a running focus session — shown on the Lock
/// Screen and in the Dynamic Island.
struct FocusActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var startDate: Date
        var endDate: Date
    }

    var sectionName: String
    var symbol: String
    var colorName: String
}
