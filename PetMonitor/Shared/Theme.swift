import SwiftUI
import UIKit

extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: 1.0
        )
    }

    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

/// A deliberately quiet palette: desaturated sage, sand, mist and lavender.
/// Nothing saturated, nothing that shouts — even the "urgent" tone is a
/// muted terracotta rather than an alarm red.
enum CalmPalette {
    static let sage = Color(light: Color(hex: 0x6F8F7C), dark: Color(hex: 0x9DBCA9))
    static let tint = Color(light: Color(hex: 0x557D6A), dark: Color(hex: 0x9DBCA9))
    static let mist = Color(light: Color(hex: 0x7FA0B4), dark: Color(hex: 0x9DBCCE))
    static let lavender = Color(light: Color(hex: 0x9A93BC), dark: Color(hex: 0xB7B0D8))
    static let amber = Color(light: Color(hex: 0xB98D4F), dark: Color(hex: 0xD9B27C))
    static let terracotta = Color(light: Color(hex: 0xB06A58), dark: Color(hex: 0xD69384))

    static let backgroundTop = Color(light: Color(hex: 0xF7F4ED), dark: Color(hex: 0x15181B))
    static let backgroundBottom = Color(light: Color(hex: 0xEDEEE4), dark: Color(hex: 0x101311))

    static let avatarColors: [Color] = [sage, mist, lavender, amber, terracotta]
}

extension SymptomUrgency {
    var color: Color {
        switch self {
        case .mild: return CalmPalette.sage
        case .concerning: return CalmPalette.amber
        case .urgent: return CalmPalette.terracotta
        }
    }
}

/// Wellness score presentation shared by the app and the status widget.
enum Wellness {
    static func label(for score: Int?) -> String {
        guard let score else { return "No data yet" }
        if score < 40 { return "Needs attention" }
        if score < 60 { return "Watch closely" }
        if score < 80 { return "Doing okay" }
        return "Thriving"
    }

    static func color(for score: Int?) -> Color {
        guard let score else { return CalmPalette.sage.opacity(0.4) }
        if score < 40 { return CalmPalette.terracotta }
        if score < 70 { return CalmPalette.amber }
        return CalmPalette.sage
    }
}
