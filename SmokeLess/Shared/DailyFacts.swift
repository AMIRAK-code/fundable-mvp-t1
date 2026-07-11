import Foundation

/// A rotating library of facts about the problems of smoking, vaping and
/// heated tobacco. One fact is surfaced per calendar day.
struct DailyFact: Identifiable {
    let id: Int
    let category: String
    let text: String

    static func fact(for date: Date) -> DailyFact {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
        return all[day % all.count]
    }

    static var categories: [String] {
        var seen: [String] = []
        for fact in all where !seen.contains(fact.category) {
            seen.append(fact.category)
        }
        return seen
    }

    static let all: [DailyFact] = [
        DailyFact(id: 1, category: "Health", text: "Cigarette smoke contains over 7,000 chemicals — at least 69 of them are known to cause cancer."),
        DailyFact(id: 2, category: "Health", text: "Smoking damages nearly every organ in the body, from your heart and lungs to your skin, eyes and bones."),
        DailyFact(id: 3, category: "Health", text: "Tobacco use is the leading preventable cause of death worldwide, killing more than 8 million people every year."),
        DailyFact(id: 4, category: "Health", text: "Smokers are 2–4 times more likely to develop coronary heart disease than non-smokers."),
        DailyFact(id: 5, category: "Health", text: "Smoking doubles your risk of stroke by damaging blood vessels and raising blood pressure."),
        DailyFact(id: 6, category: "Health", text: "About 9 out of 10 lung cancer deaths are linked to smoking."),
        DailyFact(id: 7, category: "Health", text: "Smoking weakens your immune system, making everyday infections last longer and hit harder."),
        DailyFact(id: 8, category: "Health", text: "Carbon monoxide from smoke crowds out oxygen in your blood, starving your muscles and brain."),
        DailyFact(id: 9, category: "Vaping", text: "Most vapes contain nicotine — one pod can deliver as much nicotine as an entire pack of cigarettes."),
        DailyFact(id: 10, category: "Vaping", text: "Nicotine exposure in youth can harm the parts of the brain that control attention, learning and mood."),
        DailyFact(id: 11, category: "Vaping", text: "Vape aerosol is not water vapor — it can contain heavy metals, ultrafine particles and flavoring chemicals linked to lung irritation."),
        DailyFact(id: 12, category: "Vaping", text: "Many disposable vapes contain more puffs than a carton of cigarettes, making it easy to consume far more nicotine than intended."),
        DailyFact(id: 13, category: "Heated tobacco", text: "IQOS and other heated tobacco products still deliver nicotine and toxic chemicals — 'heated' does not mean harmless."),
        DailyFact(id: 14, category: "Heated tobacco", text: "Heated tobacco aerosol contains many of the same harmful substances found in cigarette smoke, sometimes at lower and sometimes at higher levels."),
        DailyFact(id: 15, category: "Heated tobacco", text: "No tobacco product is safe. The WHO states that reducing exposure does not mean reducing risk to safe levels."),
        DailyFact(id: 16, category: "Money", text: "A pack-a-day habit can cost thousands per year — enough for a vacation, a new phone, or months of groceries."),
        DailyFact(id: 17, category: "Money", text: "Smokers often pay significantly more for life and health insurance than non-smokers."),
        DailyFact(id: 18, category: "Money", text: "The money spent on a single week of smoking could fund a great pair of running shoes to enjoy your recovering lungs."),
        DailyFact(id: 19, category: "Body", text: "Smoking speeds up skin aging — wrinkles, dullness and slower wound healing are all linked to tobacco."),
        DailyFact(id: 20, category: "Body", text: "Smoking stains teeth, causes gum disease, and is a major cause of tooth loss in adults."),
        DailyFact(id: 21, category: "Body", text: "Smoking reduces fertility in both men and women and makes pregnancy complications more likely."),
        DailyFact(id: 22, category: "Body", text: "Smokers lose bone density faster, raising the risk of fractures and osteoporosis."),
        DailyFact(id: 23, category: "Body", text: "Smoking damages the blood vessels in your eyes and raises the risk of macular degeneration and cataracts."),
        DailyFact(id: 24, category: "Others", text: "Secondhand smoke causes stroke, heart disease and lung cancer in people who never smoked."),
        DailyFact(id: 25, category: "Others", text: "Children exposed to secondhand smoke face higher risks of asthma, ear infections and sudden infant death syndrome."),
        DailyFact(id: 26, category: "Others", text: "Pets in smoking households show higher rates of respiratory illness and certain cancers."),
        DailyFact(id: 27, category: "Environment", text: "Cigarette butts are the most littered item on Earth — trillions per year, leaching plastic and toxins into water."),
        DailyFact(id: 28, category: "Environment", text: "Disposable vapes create huge amounts of electronic and battery waste that is rarely recycled."),
        DailyFact(id: 29, category: "Recovery", text: "Within 20 minutes of your last cigarette, your heart rate begins to drop. Recovery starts almost immediately."),
        DailyFact(id: 30, category: "Recovery", text: "Cravings typically pass in 5–10 minutes, whether or not you smoke. Ride the wave — it always breaks."),
        DailyFact(id: 31, category: "Recovery", text: "One year after quitting, your risk of heart disease is about half of a smoker's. Your body wants to heal."),
        DailyFact(id: 32, category: "Recovery", text: "People who quit before age 40 avoid about 90% of the excess death risk caused by continued smoking.")
    ]
}
