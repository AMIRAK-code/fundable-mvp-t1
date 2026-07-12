import UIKit

/// Persists scan sessions as JSON and their photos as JPEGs under Documents.
/// Everything stays on device.
final class ScanStore {
    private let fileManager = FileManager.default

    private var rootDirectory: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("ManeScans", isDirectory: true)
    }

    private var indexURL: URL {
        rootDirectory.appendingPathComponent("sessions.json")
    }

    private func imagesDirectory(for sessionID: UUID) -> URL {
        rootDirectory.appendingPathComponent(sessionID.uuidString, isDirectory: true)
    }

    private func ensureRoot() {
        try? fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Sessions

    func loadSessions() -> [ScanSession] {
        guard let data = try? Data(contentsOf: indexURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let sessions = (try? decoder.decode([ScanSession].self, from: data)) ?? []
        return sessions.sorted { $0.date < $1.date }
    }

    func saveSessions(_ sessions: [ScanSession]) {
        ensureRoot()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(sessions) {
            try? data.write(to: indexURL, options: .atomic)
        }
    }

    // MARK: - Images

    func saveImages(_ images: [ScanAngle: UIImage], for sessionID: UUID) {
        ensureRoot()
        let dir = imagesDirectory(for: sessionID)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        for (angle, image) in images {
            guard let data = image.jpegData(compressionQuality: 0.85) else { continue }
            try? data.write(to: dir.appendingPathComponent("\(angle.rawValue).jpg"), options: .atomic)
        }
    }

    func image(for sessionID: UUID, angle: ScanAngle) -> UIImage? {
        let url = imagesDirectory(for: sessionID).appendingPathComponent("\(angle.rawValue).jpg")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func deleteImages(for sessionID: UUID) {
        try? fileManager.removeItem(at: imagesDirectory(for: sessionID))
    }

    func deleteAll() {
        try? fileManager.removeItem(at: rootDirectory)
    }
}
