import Foundation

/// Identifiers shared between the app and the widget extension.
///
/// Before running on a real device, replace these with your own identifiers
/// and update the two `.entitlements` files to match. On the simulator the
/// defaults work out of the box.
enum AppGroup {
    /// App Group used so the app and widgets read the same database and quote cache.
    static let identifier = "group.com.example.dreamchaser"

    /// Suite used for lightweight shared values (today's quote, favorites).
    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}
