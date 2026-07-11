import Foundation

/// The kind of smoking habit being tracked. Each type carries sensible
/// defaults so onboarding can pre-fill consumption and price.
enum SmokingType: String, Codable, CaseIterable, Identifiable {
    case cigarettes
    case vape
    case iqos
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cigarettes: return "Cigarettes"
        case .vape: return "Vape / E-cigarette"
        case .iqos: return "IQOS / Heated tobacco"
        case .other: return "Other"
        }
    }

    var unitSingular: String {
        switch self {
        case .cigarettes: return "cigarette"
        case .vape: return "pod"
        case .iqos: return "stick"
        case .other: return "unit"
        }
    }

    var unitPlural: String {
        switch self {
        case .cigarettes: return "cigarettes"
        case .vape: return "pods"
        case .iqos: return "sticks"
        case .other: return "units"
        }
    }

    var symbol: String {
        switch self {
        case .cigarettes: return "smoke.fill"
        case .vape: return "cloud.fill"
        case .iqos: return "flame.fill"
        case .other: return "leaf.fill"
        }
    }

    var defaultUnitsPerDay: Double {
        switch self {
        case .cigarettes: return 15
        case .vape: return 1
        case .iqos: return 15
        case .other: return 10
        }
    }

    var defaultPricePerUnit: Double {
        switch self {
        case .cigarettes: return 0.40
        case .vape: return 6.00
        case .iqos: return 0.35
        case .other: return 0.50
        }
    }
}

enum QuitGoal: String, Codable, CaseIterable, Identifiable {
    case quitCompletely
    case reduceGradually

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quitCompletely: return "Quit completely"
        case .reduceGradually: return "Reduce gradually"
        }
    }

    var detail: String {
        switch self {
        case .quitCompletely: return "Stop from day one. Every slip resets your streak."
        case .reduceGradually: return "Set a daily allowance. Staying under it keeps your streak alive."
        }
    }
}

struct UserProfile: Codable {
    var smokingType: SmokingType = .cigarettes
    var unitsPerDay: Double = 15
    var pricePerUnit: Double = 0.40
    var currencyCode: String = Locale.current.currency?.identifier ?? "USD"
    var startDate: Date = Date()
    var goal: QuitGoal = .quitCompletely
    var dailyAllowance: Double = 5

    var costPerDay: Double { unitsPerDay * pricePerUnit }
}

/// A logged smoking event ("slip"). In quit mode any slip resets the streak;
/// in reduce mode only days over the allowance do.
struct SlipEntry: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date
    var units: Double
    var note: String?
}

struct WishlistItem: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var price: Double
    var emoji: String = "🎁"
    var createdAt: Date = Date()
    var purchasedAt: Date?
}

/// The whole persisted application state. Kept as one small Codable value so
/// the app, widgets and the watch can share and sync it as a single blob.
struct AppState: Codable {
    var onboardingComplete: Bool = false
    var profile: UserProfile = UserProfile()
    var slips: [SlipEntry] = []
    var resistedCravings: [Date] = []
    var wishlist: [WishlistItem] = []
    var bestStreakCache: Int = 0
    var themeID: String = "mint"
    var notificationsEnabled: Bool = false
}
