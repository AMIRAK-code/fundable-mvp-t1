import Foundation

/// JSON persistence shared between the app and the widget extension.
///
/// If the `group.com.example.petmonitor` App Group capability is enabled on both
/// targets, data lands in the shared container and widgets show live data.
/// Without it, the app falls back to its own Documents directory and the
/// widgets show gentle sample content instead.
enum SharedStorage {
    static let appGroupID = "group.com.example.petmonitor"

    static let petsFile = "pets.json"
    static let entriesFile = "entries.json"
    static let settingsFile = "settings.json"
    static let snapshotFile = "widget-snapshot.json"

    static var isAppGroupConfigured: Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) != nil
    }

    static var baseDirectory: URL {
        if let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return container
        }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private static func fileURL(for filename: String) -> URL {
        baseDirectory.appendingPathComponent(filename)
    }

    static func load<T: Decodable>(_ type: T.Type, from filename: String) -> T? {
        guard let data = try? Data(contentsOf: fileURL(for: filename)) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(type, from: data)
    }

    static func save<T: Encodable>(_ value: T, to filename: String) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: fileURL(for: filename), options: .atomic)
    }

    static func loadSnapshot() -> WidgetSnapshot? {
        load(WidgetSnapshot.self, from: snapshotFile)
    }

    static func saveSnapshot(_ snapshot: WidgetSnapshot) {
        save(snapshot, to: snapshotFile)
    }
}
