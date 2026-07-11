import SwiftUI

/// A theme is exactly three colors: primary, secondary and accent.
/// The app ships three selectable palettes.
struct AppTheme: Identifiable {
    let id: String
    let name: String
    let primary: Color
    let secondary: Color
    let accent: Color

    var gradient: LinearGradient {
        LinearGradient(
            colors: [primary, secondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static let mint = AppTheme(
        id: "mint",
        name: "Fresh Mint",
        primary: Color(red: 0.13, green: 0.69, blue: 0.55),
        secondary: Color(red: 0.07, green: 0.36, blue: 0.33),
        accent: Color(red: 0.99, green: 0.78, blue: 0.30)
    )

    static let ocean = AppTheme(
        id: "ocean",
        name: "Deep Ocean",
        primary: Color(red: 0.20, green: 0.51, blue: 0.90),
        secondary: Color(red: 0.12, green: 0.23, blue: 0.47),
        accent: Color(red: 0.42, green: 0.86, blue: 0.95)
    )

    static let sunset = AppTheme(
        id: "sunset",
        name: "Warm Sunset",
        primary: Color(red: 0.95, green: 0.45, blue: 0.30),
        secondary: Color(red: 0.55, green: 0.20, blue: 0.35),
        accent: Color(red: 0.99, green: 0.72, blue: 0.25)
    )

    static let all: [AppTheme] = [.mint, .ocean, .sunset]

    static func theme(withID id: String) -> AppTheme {
        all.first { $0.id == id } ?? .mint
    }
}
