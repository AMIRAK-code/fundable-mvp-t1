import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Stores the whole `AppState` as JSON in the shared app-group container so
/// the app and its widget extension read the same data. Falls back to
/// standard UserDefaults when the app group is unavailable (e.g. a personal
/// team without the App Groups capability).
enum Persistence {
    static let appGroupID = "group.com.fundable.smokeless"
    static let stateKey = "smokeless.state.v1"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func load() -> AppState? {
        guard let data = defaults.data(forKey: stateKey) else { return nil }
        return try? JSONDecoder().decode(AppState.self, from: data)
    }

    static func save(_ state: AppState) {
        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: stateKey)
        }
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
