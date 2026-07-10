import Foundation
import SwiftData

/// A private progress photo (fitness / skincare). Stored on-device only,
/// with external storage so the database stays lean.
@Model
final class ProgressPhoto {
    @Attribute(.externalStorage) var imageData: Data
    var createdAt: Date
    var note: String

    init(imageData: Data, note: String = "") {
        self.imageData = imageData
        self.createdAt = .now
        self.note = note
    }
}
