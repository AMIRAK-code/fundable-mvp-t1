import Foundation

// MARK: - Profile building blocks

enum HairType: String, Codable, CaseIterable, Identifiable {
    case straight, wavy, curly, coily

    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    var symbol: String {
        switch self {
        case .straight: return "line.diagonal"
        case .wavy: return "water.waves"
        case .curly: return "scribble.variable"
        case .coily: return "hurricane"
        }
    }
}

enum HairLength: String, Codable, CaseIterable, Identifiable {
    case buzz, short, medium, long

    var id: String { rawValue }

    var label: String {
        switch self {
        case .buzz: return "Buzz / shaved"
        case .short: return "Short"
        case .medium: return "Medium"
        case .long: return "Long"
        }
    }
}

enum ScalpCondition: String, Codable, CaseIterable, Identifiable {
    case dry, balanced, oily, flaky

    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    var blurb: String {
        switch self {
        case .dry: return "Tight, sometimes itchy, rarely greasy"
        case .balanced: return "No real complaints"
        case .oily: return "Greasy by the end of the day"
        case .flaky: return "Visible flakes on shoulders or scalp"
        }
    }
}

enum Concern: String, Codable, CaseIterable, Identifiable {
    case thinning
    case receding
    case dandruff
    case dryness
    case oiliness
    case graying
    case slowGrowth = "slow-growth"
    case frizz

    var id: String { rawValue }

    var label: String {
        switch self {
        case .thinning: return "Thinning hair"
        case .receding: return "Receding hairline"
        case .dandruff: return "Dandruff / flakes"
        case .dryness: return "Dry, brittle hair"
        case .oiliness: return "Greasy roots"
        case .graying: return "Graying"
        case .slowGrowth: return "Slow growth"
        case .frizz: return "Frizz"
        }
    }

    var symbol: String {
        switch self {
        case .thinning: return "chart.line.downtrend.xyaxis"
        case .receding: return "arrow.up.forward"
        case .dandruff: return "snowflake"
        case .dryness: return "sun.max"
        case .oiliness: return "drop.fill"
        case .graying: return "circle.lefthalf.filled"
        case .slowGrowth: return "tortoise"
        case .frizz: return "wind"
        }
    }
}

enum Goal: String, Codable, CaseIterable, Identifiable {
    case maintain, regrow, style, scalp

    var id: String { rawValue }

    var label: String {
        switch self {
        case .maintain: return "Keep it healthy"
        case .regrow: return "Fight hair loss"
        case .style: return "Level up styling"
        case .scalp: return "Fix my scalp"
        }
    }

    var symbol: String {
        switch self {
        case .maintain: return "checkmark.shield"
        case .regrow: return "leaf"
        case .style: return "comb"
        case .scalp: return "brain.head.profile"
        }
    }
}

enum ExerciseFrequency: String, Codable, CaseIterable, Identifiable {
    case rarely, weekly, daily

    var id: String { rawValue }

    var label: String {
        switch self {
        case .rarely: return "Rarely"
        case .weekly: return "A few times a week"
        case .daily: return "Daily"
        }
    }
}

enum AgeRange: String, Codable, CaseIterable, Identifiable {
    case under20 = "Under 20"
    case twenties = "20–29"
    case thirties = "30–39"
    case forties = "40–49"
    case fiftyPlus = "50+"

    var id: String { rawValue }
}

struct Lifestyle: Codable, Equatable, Hashable {
    var exercise: ExerciseFrequency = .weekly
    var swims: Bool = false
    var hardWater: Bool = false
    var heatStyling: Bool = false
    var wearsHats: Bool = false
}

// MARK: - Profile

struct HairProfile: Codable, Equatable, Hashable {
    var name: String = ""
    var ageRange: AgeRange = .twenties
    var hairType: HairType = .straight
    var hairLength: HairLength = .short
    var scalp: ScalpCondition = .balanced
    var concerns: Set<Concern> = []
    var lifestyle: Lifestyle = Lifestyle()
    var currentWashesPerWeek: Int = 4
    var goal: Goal = .maintain

    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Champ" : trimmed
    }

    /// Tags used to match this profile against product/tip tags.
    var matchTags: Set<String> {
        var tags: Set<String> = [hairType.rawValue, hairLength.rawValue, "\(scalp.rawValue)-scalp"]
        tags.formUnion(concerns.map(\.rawValue))
        switch goal {
        case .maintain: tags.insert("maintenance")
        case .regrow: tags.insert("growth")
        case .style: tags.insert("styling")
        case .scalp: tags.insert("scalp-health")
        }
        if scalp == .flaky { tags.insert("dandruff") }
        if concerns.contains(.thinning) || concerns.contains(.receding) { tags.insert("growth") }
        if lifestyle.swims { tags.insert("swimmer") }
        if lifestyle.hardWater { tags.insert("hard-water") }
        if lifestyle.heatStyling { tags.insert("heat") }
        if lifestyle.wearsHats { tags.insert("hats") }
        if lifestyle.exercise == .daily { tags.insert("active") }
        return tags
    }
}
