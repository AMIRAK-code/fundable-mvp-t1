import Foundation

enum ProductCategory: String, Codable, CaseIterable, Identifiable {
    case shampoo, conditioner, treatment, serum, styling, oil, supplement, tool

    var id: String { rawValue }

    var label: String {
        switch self {
        case .serum: return "Scalp Serum"
        case .treatment: return "Treatment"
        case .tool: return "Tools"
        default: return rawValue.capitalized
        }
    }

    var symbol: String {
        switch self {
        case .shampoo: return "shower.fill"
        case .conditioner: return "drop.circle.fill"
        case .treatment: return "cross.vial.fill"
        case .serum: return "eyedropper.halffull"
        case .styling: return "comb.fill"
        case .oil: return "drop.triangle.fill"
        case .supplement: return "pills.fill"
        case .tool: return "wrench.and.screwdriver.fill"
        }
    }
}

struct Product: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let brand: String
    let category: ProductCategory
    let summary: String
    let heroIngredients: [String]
    let tags: [String]
    let priceTier: Int
    let rating: Double
    var source: String?

    var priceLabel: String {
        String(repeating: "$", count: max(1, min(3, priceTier)))
    }
}

struct Tip: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let body: String
    let category: String
    let tags: [String]
}

/// Shared payload shape for every catalog source (bundled or remote).
struct CatalogPayload: Codable {
    var products: [Product]?
    var tips: [Tip]?
}
