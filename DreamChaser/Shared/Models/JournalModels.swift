import Foundation
import SwiftData

/// One entry per day bookending the routine: the morning commitment and the
/// evening shutdown (win of the day + reflection).
@Model
final class JournalEntry {
    var dateKey: String
    var morningCommitted: Bool
    var eveningCompleted: Bool
    var win: String
    var note: String
    var updatedAt: Date

    init(dateKey: String) {
        self.dateKey = dateKey
        self.morningCommitted = false
        self.eveningCompleted = false
        self.win = ""
        self.note = ""
        self.updatedAt = .now
    }
}
