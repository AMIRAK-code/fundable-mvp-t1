import SwiftUI

// MARK: - Themes

/// The three selectable looks of the app.
/// - `arctic`: deep clinical navy + ice blue (skincare-counter feel)
/// - `steel`:  dark chrome + safety orange (razor-aisle feel)
/// - `light`:  clean, bright, minimal
enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case arctic
    case steel
    case light

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .arctic: return "Arctic"
        case .steel: return "Steel"
        case .light: return "Classic Light"
        }
    }

    var tagline: String {
        switch self {
        case .arctic: return "Deep blue, clinical calm"
        case .steel: return "Dark chrome, sharp edge"
        case .light: return "Clean, bright, minimal"
        }
    }

    var palette: Palette {
        switch self {
        case .arctic:
            return Palette(
                colorScheme: .dark,
                background: Color(hex: 0x001233),
                surface: Color(hex: 0x0A2A5E),
                surfaceSecondary: Color(hex: 0x123A7A),
                textPrimary: .white,
                textSecondary: Color(hex: 0xA9C1E8),
                accent: Color(hex: 0x4FA3FF),
                accentSecondary: Color(hex: 0x9ED0FF),
                heroGradient: [Color(hex: 0x00205B), Color(hex: 0x0A3E8C)],
                positive: Color(hex: 0x3DDC97),
                caution: Color(hex: 0xFFC857),
                negative: Color(hex: 0xFF6B6B)
            )
        case .steel:
            return Palette(
                colorScheme: .dark,
                background: Color(hex: 0x0C0F13),
                surface: Color(hex: 0x171C22),
                surfaceSecondary: Color(hex: 0x222A33),
                textPrimary: Color(hex: 0xF2F5F8),
                textSecondary: Color(hex: 0x9AA7B4),
                accent: Color(hex: 0xFF7A1A),
                accentSecondary: Color(hex: 0x8FB3D9),
                heroGradient: [Color(hex: 0x12161C), Color(hex: 0x2A3947)],
                positive: Color(hex: 0x38D9A9),
                caution: Color(hex: 0xFFD43B),
                negative: Color(hex: 0xFF6B6B)
            )
        case .light:
            return Palette(
                colorScheme: .light,
                background: Color(hex: 0xF5F7FA),
                surface: .white,
                surfaceSecondary: Color(hex: 0xEAF0F7),
                textPrimary: Color(hex: 0x101828),
                textSecondary: Color(hex: 0x5B6B7F),
                accent: Color(hex: 0x0B5FFF),
                accentSecondary: Color(hex: 0x00205B),
                heroGradient: [Color(hex: 0x0B5FFF), Color(hex: 0x66A3FF)],
                positive: Color(hex: 0x12B76A),
                caution: Color(hex: 0xF79009),
                negative: Color(hex: 0xF04438)
            )
        }
    }
}

/// A resolved set of colors for the current theme.
struct Palette {
    let colorScheme: ColorScheme?
    let background: Color
    let surface: Color
    let surfaceSecondary: Color
    let textPrimary: Color
    let textSecondary: Color
    let accent: Color
    let accentSecondary: Color
    let heroGradient: [Color]
    let positive: Color
    let caution: Color
    let negative: Color

    var hero: LinearGradient {
        LinearGradient(colors: heroGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Theme manager

final class ThemeManager: ObservableObject {
    private static let storageKey = "mane.appTheme"

    @Published var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: Self.storageKey) }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.storageKey) ?? ""
        theme = AppTheme(rawValue: raw) ?? .arctic
    }

    var palette: Palette { theme.palette }
}

// MARK: - Helpers

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}
