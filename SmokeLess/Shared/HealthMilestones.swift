import Foundation

/// Body-recovery milestones after the last smoke, based on widely published
/// public-health timelines (WHO / CDC). Purely educational, not medical advice.
struct HealthMilestone: Identifiable {
    let id: String
    let hours: Double
    let title: String
    let detail: String
    let symbol: String

    func progress(after interval: TimeInterval) -> Double {
        guard hours > 0 else { return 1 }
        return min(1, interval / (hours * 3_600))
    }

    func isReached(after interval: TimeInterval) -> Bool {
        progress(after: interval) >= 1
    }

    static let all: [HealthMilestone] = [
        HealthMilestone(
            id: "20m", hours: 1.0 / 3.0, title: "20 minutes",
            detail: "Your heart rate and blood pressure begin to drop back toward normal.",
            symbol: "heart.fill"
        ),
        HealthMilestone(
            id: "12h", hours: 12, title: "12 hours",
            detail: "Carbon monoxide in your blood falls to a normal level, letting oxygen flow freely again.",
            symbol: "wind"
        ),
        HealthMilestone(
            id: "24h", hours: 24, title: "24 hours",
            detail: "Your risk of a heart attack already starts to decrease.",
            symbol: "bolt.heart.fill"
        ),
        HealthMilestone(
            id: "48h", hours: 48, title: "48 hours",
            detail: "Nerve endings begin to regrow — taste and smell start coming back.",
            symbol: "sparkles"
        ),
        HealthMilestone(
            id: "72h", hours: 72, title: "72 hours",
            detail: "Bronchial tubes relax. Breathing feels noticeably easier and energy rises.",
            symbol: "lungs.fill"
        ),
        HealthMilestone(
            id: "1w", hours: 24 * 7, title: "1 week",
            detail: "The hardest cravings peak and begin to fade. Success odds jump sharply from here.",
            symbol: "calendar"
        ),
        HealthMilestone(
            id: "2w", hours: 24 * 14, title: "2 weeks",
            detail: "Circulation improves — walking and exercise feel easier.",
            symbol: "figure.walk"
        ),
        HealthMilestone(
            id: "1m", hours: 24 * 30, title: "1 month",
            detail: "Lung function increases and coughing or shortness of breath decreases.",
            symbol: "figure.run"
        ),
        HealthMilestone(
            id: "3m", hours: 24 * 90, title: "3 months",
            detail: "Blood circulation and lung capacity have significantly improved.",
            symbol: "arrow.up.heart.fill"
        ),
        HealthMilestone(
            id: "9m", hours: 24 * 270, title: "9 months",
            detail: "Cilia in your lungs have regrown — fewer infections, clearer airways.",
            symbol: "shield.fill"
        ),
        HealthMilestone(
            id: "1y", hours: 24 * 365, title: "1 year",
            detail: "Your risk of coronary heart disease is about half that of someone still smoking.",
            symbol: "star.fill"
        )
    ]
}
