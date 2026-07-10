import SwiftUI

/// Named palette stored on models as strings so SwiftData stays simple.
enum ThemeColor {
    static let names: [String] = [
        "purple", "indigo", "blue", "teal", "mint",
        "green", "yellow", "orange", "pink", "red",
    ]

    static func color(for name: String) -> Color {
        switch name {
        case "purple": .purple
        case "indigo": .indigo
        case "blue": .blue
        case "teal": .teal
        case "mint": .mint
        case "green": .green
        case "yellow": .yellow
        case "orange": .orange
        case "pink": .pink
        case "red": .red
        default: .accentColor
        }
    }
}
