import Foundation

/// Rule-based engine that turns an onboarding profile into a weekly routine
/// and scores catalog products against the profile.
enum RoutineEngine {

    // MARK: - Routine generation

    static func buildRoutine(for profile: HairProfile) -> HairRoutine {
        var rationale: [String] = []
        var focus: [String] = []

        // --- Wash cadence ---
        var washes: Int
        switch profile.scalp {
        case .oily: washes = 5
        case .balanced: washes = 4
        case .dry: washes = 2
        case .flaky: washes = 3
        }
        if profile.lifestyle.exercise == .daily { washes = min(7, washes + 1) }
        if profile.lifestyle.swims { washes = min(7, washes + 1) }
        if profile.concerns.contains(.oiliness) { washes = min(7, washes + 1) }
        if profile.concerns.contains(.dryness) && profile.scalp != .oily { washes = max(2, washes - 1) }

        rationale.append("A \(profile.scalp.label.lowercased()) scalp does best around \(washes)× shampoo per week — enough to stay clean without stripping natural oils.")
        if profile.currentWashesPerWeek > washes + 1 {
            rationale.append("You currently wash \(profile.currentWashesPerWeek)×/week. We're dialing it back — over-washing triggers rebound oil and dryness.")
        } else if profile.currentWashesPerWeek < washes - 1 {
            rationale.append("You currently wash \(profile.currentWashesPerWeek)×/week. We're stepping it up to keep buildup and scalp irritation in check.")
        }

        let washDays = weekdays(forTimesPerWeek: washes)
        let everyDay: Set<Int> = [1, 2, 3, 4, 5, 6, 7]
        var steps: [RoutineStep] = []

        // --- Shampoo ---
        let shampooDetail: String
        let shampooWhy: String
        if profile.scalp == .flaky || profile.concerns.contains(.dandruff) {
            shampooDetail = "Use an anti-dandruff shampoo (zinc pyrithione or ketoconazole). Massage into the scalp, leave for 2–3 minutes before rinsing."
            shampooWhy = "Active anti-dandruff ingredients need contact time on the scalp to control the fungus behind most flaking."
            focus.append("Flake control")
        } else if profile.concerns.contains(.thinning) || profile.concerns.contains(.receding) {
            shampooDetail = "Use a gentle fortifying shampoo (caffeine/biotin). Massage with fingertips for 60 seconds — never nails."
            shampooWhy = "A clean, stimulated scalp is the baseline for any hair-retention effort."
            focus.append("Hair retention")
        } else if profile.scalp == .dry || profile.concerns.contains(.dryness) {
            shampooDetail = "Use a hydrating, sulfate-free shampoo with lukewarm (not hot) water."
            shampooWhy = "Hot water and harsh sulfates strip the oils a dry scalp is already short on."
            focus.append("Moisture")
        } else {
            shampooDetail = "Use a balancing daily shampoo. Lather at the scalp, let the runoff clean the lengths."
            shampooWhy = "Shampoo is for the scalp; the lengths only need the rinse-through."
            focus.append("Scalp balance")
        }
        steps.append(RoutineStep(
            id: "shampoo", title: "Shampoo", detail: shampooDetail, why: shampooWhy,
            timeOfDay: .evening, weekdays: washDays,
            frequencyLabel: "\(washes)×/week", icon: "shower.fill"
        ))

        // --- Conditioner ---
        if profile.hairLength != .buzz {
            steps.append(RoutineStep(
                id: "condition",
                title: "Condition",
                detail: "After shampoo, work conditioner through mid-lengths and ends. Leave 1–2 minutes, rinse cool.",
                why: "Conditioner reseals the cuticle that washing opens — skipping it is the #1 cause of dull, frizzy hair in men.",
                timeOfDay: .evening, weekdays: washDays,
                frequencyLabel: "Wash days", icon: "drop.circle.fill"
            ))
        }

        // --- Growth block ---
        let wantsGrowth = profile.goal == .regrow
            || profile.concerns.contains(.thinning)
            || profile.concerns.contains(.receding)
        if wantsGrowth {
            steps.append(RoutineStep(
                id: "serum",
                title: "Scalp serum",
                detail: "Apply a targeted scalp serum to the hairline and crown on a dry or towel-dry scalp. For clinically proven options (minoxidil), talk to a dermatologist first.",
                why: "Consistent daily application matters more than the product itself — retention treatments only work with unbroken streaks.",
                timeOfDay: .evening, weekdays: everyDay,
                frequencyLabel: "Daily", icon: "eyedropper.halffull"
            ))
            steps.append(RoutineStep(
                id: "massage",
                title: "Scalp massage — 3 min",
                detail: "Fingertips or a silicone brush, firm circular strokes across the hairline, temples and crown.",
                why: "Small studies link regular scalp massage to increased hair thickness via improved blood flow and mechanical stimulation.",
                timeOfDay: .morning, weekdays: everyDay,
                frequencyLabel: "Daily", icon: "hand.raised.fingers.spread.fill"
            ))
            focus.append("Growth stimulation")
        }

        // --- Scalp treatments ---
        if profile.scalp == .flaky || profile.concerns.contains(.dandruff) || profile.goal == .scalp {
            steps.append(RoutineStep(
                id: "exfoliate",
                title: "Scalp exfoliation",
                detail: "Once a week, use a scalp scrub or exfoliating brush before shampooing to lift buildup and dead skin.",
                why: "A weekly reset keeps follicles clear and helps actives reach the scalp instead of sitting on buildup.",
                timeOfDay: .evening, weekdays: [7],
                frequencyLabel: "1×/week", icon: "sparkles"
            ))
        }

        // --- Moisture treatments ---
        if profile.concerns.contains(.dryness) || profile.hairType == .curly || profile.hairType == .coily {
            steps.append(RoutineStep(
                id: "mask",
                title: "Deep-conditioning mask",
                detail: "Swap conditioner for a mask once a week. Leave in 5–10 minutes while you shower.",
                why: "Curly and dry hair loses moisture faster along the curve of each strand — a weekly mask replaces what daily conditioner can't.",
                timeOfDay: .evening, weekdays: [1],
                frequencyLabel: "1×/week", icon: "cloud.rain.fill"
            ))
            focus.append("Deep moisture")
        }

        // --- Lifestyle add-ons ---
        if profile.lifestyle.heatStyling {
            steps.append(RoutineStep(
                id: "heat-protect",
                title: "Heat protectant before styling",
                detail: "Mist a heat protectant on damp hair before any blow-dry or hot tool. Keep the dryer moving, medium heat.",
                why: "Unprotected heat above ~150 °C permanently cracks the hair cuticle — protectant buys you a big safety margin.",
                timeOfDay: .morning, weekdays: everyDay,
                frequencyLabel: "Styling days", icon: "flame.fill"
            ))
        }
        if profile.lifestyle.swims {
            steps.append(RoutineStep(
                id: "swim-rinse",
                title: "Pre-wet + rinse around swims",
                detail: "Soak hair with tap water before the pool (saturated hair absorbs less chlorine) and rinse right after.",
                why: "Chlorine bonds to dry hair and oxidizes it — pre-wetting is the cheapest protection there is.",
                timeOfDay: .morning, weekdays: [3, 6],
                frequencyLabel: "Swim days", icon: "figure.pool.swim"
            ))
        }
        if profile.lifestyle.hardWater {
            steps.append(RoutineStep(
                id: "chelate",
                title: "Chelating / clarifying wash",
                detail: "Once a week, replace your regular shampoo with a chelating wash to strip mineral buildup.",
                why: "Hard-water minerals coat the strand, blocking moisture and making hair stiff and dull.",
                timeOfDay: .evening, weekdays: [4],
                frequencyLabel: "1×/week", icon: "aqi.medium"
            ))
        }

        // --- Daily styling / AM care ---
        if profile.hairLength != .buzz {
            let styleDetail: String
            switch profile.hairType {
            case .straight: styleDetail = "Style on dry or slightly damp hair — matte clay or paste for texture, a light cream for a natural finish."
            case .wavy: styleDetail = "Scrunch a sea-salt spray or light cream into damp hair and let waves set naturally where you can."
            case .curly: styleDetail = "Apply curl cream to damp hair, scrunch upward, then air-dry or diffuse. Don't brush curls dry."
            case .coily: styleDetail = "Work a leave-in cream or oil through damp hair in sections. Style with fingers or a wide-tooth comb."
            }
            steps.append(RoutineStep(
                id: "style",
                title: "Style",
                detail: styleDetail,
                why: "Matching product to your hair type is 80% of good styling — technique covers the rest.",
                timeOfDay: .morning, weekdays: everyDay,
                frequencyLabel: "Daily", icon: "comb.fill"
            ))
        }

        // --- Rinse-only days for very active users ---
        if profile.lifestyle.exercise == .daily && washes < 6 {
            let rinseDays = everyDay.subtracting(washDays)
            steps.append(RoutineStep(
                id: "rinse",
                title: "Water-only rinse after training",
                detail: "On non-wash days, rinse sweat out with water only and a quick fingertip massage — no shampoo.",
                why: "Sweat left on the scalp irritates it, but shampooing daily overshoots — a water rinse is the middle path.",
                timeOfDay: .evening, weekdays: rinseDays,
                frequencyLabel: "Non-wash days", icon: "figure.run"
            ))
        }

        if focus.isEmpty { focus.append("Everyday maintenance") }
        let headline = "\(washes)×/week wash plan · \(focus.prefix(2).joined(separator: " + "))"
        rationale.append("Consistency beats intensity: a routine you repeat for 8–12 weeks will always outperform a perfect one you abandon in two.")

        return HairRoutine(
            generatedAt: Date(),
            washesPerWeek: washes,
            headline: headline,
            focusAreas: focus,
            rationale: rationale,
            steps: steps.sorted { $0.timeOfDay == .morning && $1.timeOfDay == .evening }
        )
    }

    /// Spreads N wash days across the week. 1 = Sunday … 7 = Saturday.
    static func weekdays(forTimesPerWeek n: Int) -> Set<Int> {
        switch max(1, min(7, n)) {
        case 1: return [4]
        case 2: return [2, 5]
        case 3: return [2, 4, 6]
        case 4: return [1, 3, 5, 7]
        case 5: return [1, 2, 4, 6, 7]
        case 6: return [1, 2, 3, 4, 6, 7]
        default: return [1, 2, 3, 4, 5, 6, 7]
        }
    }

    // MARK: - Product recommendations

    static func score(_ product: Product, against tags: Set<String>) -> Double {
        var score = 0.0
        for tag in product.tags where tags.contains(tag) {
            score += weight(forTag: tag)
        }
        if score > 0 { score += product.rating * 0.3 }
        return score
    }

    static func recommend(products: [Product], for profile: HairProfile?, limit: Int = 6) -> [Product] {
        guard let profile else { return Array(products.prefix(limit)) }
        let tags = profile.matchTags
        let ranked = products
            .map { (product: $0, score: score($0, against: tags)) }
            .filter { $0.score > 0 }
            .sorted { $0.score > $1.score }
            .map(\.product)
        if ranked.isEmpty {
            return Array(products.sorted { $0.rating > $1.rating }.prefix(limit))
        }
        return Array(ranked.prefix(limit))
    }

    /// Human-readable reasons why a product fits this profile.
    static func reasons(for product: Product, profile: HairProfile?) -> [String] {
        guard let profile else { return [] }
        let tags = profile.matchTags
        return product.tags
            .filter { tags.contains($0) }
            .compactMap(reason(forTag:))
    }

    private static func weight(forTag tag: String) -> Double {
        if Concern(rawValue: tag) != nil { return 3 }
        if tag.hasSuffix("-scalp") { return 2.5 }
        if ["growth", "maintenance", "styling", "scalp-health"].contains(tag) { return 2 }
        if ["swimmer", "hard-water", "heat", "hats", "active"].contains(tag) { return 1.5 }
        return 1
    }

    private static func reason(forTag tag: String) -> String? {
        switch tag {
        case "thinning": return "Targets thinning hair"
        case "receding": return "Formulated for receding hairlines"
        case "dandruff": return "Fights dandruff and flaking"
        case "dryness": return "Rehydrates dry hair"
        case "oiliness": return "Controls excess oil"
        case "graying": return "Cares for graying hair"
        case "slow-growth": return "Supports faster growth"
        case "frizz": return "Tames frizz"
        case "growth": return "Supports your growth goal"
        case "maintenance": return "Great for everyday maintenance"
        case "styling": return "Fits your styling goal"
        case "scalp-health": return "Boosts scalp health"
        case "swimmer": return "Protects hair from pool chlorine"
        case "hard-water": return "Counters hard-water buildup"
        case "heat": return "Shields against heat styling"
        case "hats": return "Good for frequent hat wearers"
        case "active": return "Fits a sweaty, active lifestyle"
        case "straight", "wavy", "curly", "coily": return "Suits \(tag) hair"
        case "buzz", "short", "medium", "long": return "Works for \(tag) length"
        default:
            if tag.hasSuffix("-scalp") {
                return "Matches your \(tag.replacingOccurrences(of: "-scalp", with: "")) scalp"
            }
            return nil
        }
    }
}
