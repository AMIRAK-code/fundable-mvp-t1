import SwiftData
import SwiftUI
import UIKit

/// The Sunday mirror: last 7 days per section, diet, sleep, focus minutes,
/// goal rungs — rolled into a letter grade, coach's notes, and a shareable
/// report card for your accountability partner.
struct WeeklyReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RoutineSection.sortOrder) private var sections: [RoutineSection]
    @Query private var dietDays: [DietDay]
    @Query private var focusSessions: [FocusSession]
    @Query(sort: \UltimateGoal.createdAt) private var goals: [UltimateGoal]

    @State private var health = HealthKitService()
    @State private var sleepAvg: Double?
    @State private var shareImage: Image?

    private var weekKeys: [String] { Dates.recentKeys(count: 7) }

    // MARK: Stats

    private var sectionRows: [(section: RoutineSection, completion: Double)] {
        sections
            .filter { !$0.items.isEmpty }
            .map { section in
                let average = weekKeys.reduce(0.0) { $0 + section.progress(on: $1) } / 7.0
                return (section, average)
            }
    }

    private var overallCompletion: Double {
        let rows = sectionRows
        guard !rows.isEmpty else { return 0 }
        return rows.reduce(0.0) { $0 + $1.completion } / Double(rows.count)
    }

    private var dietRatio: Double? {
        let recent = Set(weekKeys)
        let entries = dietDays.filter { recent.contains($0.dateKey) }
        guard !entries.isEmpty else { return nil }
        return Double(entries.filter(\.stuckToDiet).count) / Double(entries.count)
    }

    private var focusMinutes: Int {
        let recent = Set(weekKeys)
        return focusSessions.filter { recent.contains($0.dateKey) }.reduce(0) { $0 + $1.minutes }
    }

    private var rungsClimbed: Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return goals.flatMap(\.miniGoals).filter { ($0.completedAt ?? .distantPast) >= cutoff }.count
    }

    private var activeDays: Int {
        let items = sections.flatMap(\.items)
        return weekKeys.filter { key in items.contains { $0.isDone(on: key) } }.count
    }

    private var streak: Int {
        MomentumEngine.streak(items: sections.flatMap(\.items))
    }

    private var weeklyScore: Double {
        var score = 0.5 * overallCompletion
        score += 0.2 * (dietRatio ?? 0.5)
        score += 0.15 * min((sleepAvg ?? 6.5) / 8.0, 1.0)
        score += 0.15 * Double(activeDays) / 7.0
        return score * 100
    }

    private var grade: String {
        switch weeklyScore {
        case 93...: "A+"
        case 85..<93: "A"
        case 70..<85: "B"
        case 55..<70: "C"
        case 40..<55: "D"
        default: "F"
        }
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    gradeCard
                    sectionBreakdown
                    statsGrid
                    coachCard
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .background(AppBackground())
            .navigationTitle("Weekly Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await health.requestAuthorization()
                sleepAvg = await health.sleepAverageHours(days: 7)
                renderShareImage()
            }
        }
    }

    private var gradeCard: some View {
        VStack(spacing: 10) {
            Text("This week's grade")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(grade)
                .font(.system(size: 68, weight: .black, design: .rounded))
                .foregroundStyle(.purple)
            Text("Weekly score \(Int(weeklyScore.rounded()))/100")
                .font(.headline)
            if let shareImage {
                ShareLink(
                    item: shareImage,
                    preview: SharePreview("My Dream Chaser week", image: shareImage)
                ) {
                    Label("Share report card", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.glass)
                Text("Send it to your accountability partner.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard(tint: .purple)
    }

    private var sectionBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sections · last 7 days")
                .font(.headline)
            if sectionRows.isEmpty {
                Text("No routine sections with items yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ForEach(sectionRows.indices, id: \.self) { index in
                let row = sectionRows[index]
                HStack(spacing: 10) {
                    Image(systemName: row.section.symbol)
                        .foregroundStyle(ThemeColor.color(for: row.section.colorName))
                        .frame(width: 24)
                    Text(row.section.name)
                        .font(.subheadline)
                        .lineLimit(1)
                    ProgressView(value: row.completion)
                        .tint(ThemeColor.color(for: row.section.colorName))
                    Text("\(Int(row.completion * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private var statsGrid: some View {
        GlassEffectContainer(spacing: 12) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatTile(
                    title: "Diet",
                    value: dietRatio.map { "\(Int($0 * 100))" } ?? "—",
                    unit: dietRatio != nil ? "%" : nil,
                    symbol: "fork.knife",
                    color: .green
                )
                StatTile(
                    title: "Avg sleep",
                    value: sleepAvg.map { $0.formatted(.number.precision(.fractionLength(1))) } ?? "—",
                    unit: sleepAvg != nil ? "h" : nil,
                    symbol: "moon.zzz.fill",
                    color: .indigo
                )
                StatTile(
                    title: "Focus",
                    value: "\(focusMinutes)",
                    unit: "min",
                    symbol: "timer",
                    color: .blue
                )
                StatTile(
                    title: "Active days",
                    value: "\(activeDays)/7",
                    symbol: "calendar",
                    color: .teal
                )
                StatTile(
                    title: "Goal rungs",
                    value: "\(rungsClimbed)",
                    symbol: "flag.checkered",
                    color: .orange
                )
                StatTile(
                    title: "Streak",
                    value: "\(streak)",
                    unit: "days",
                    symbol: "flame.fill",
                    color: .red
                )
            }
        }
    }

    private var coachCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Coach's notes", systemImage: "figure.wave")
                .font(.headline)
            ForEach(coachNotes(), id: \.self) { note in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "sparkle")
                        .font(.caption)
                        .foregroundStyle(.purple)
                        .padding(.top, 3)
                    Text(note)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(tint: .mint)
    }

    /// Deterministic, on-device "coach" — plain rules over the week's data.
    private func coachNotes() -> [String] {
        var notes: [String] = []
        if let best = sectionRows.max(by: { $0.completion < $1.completion }), best.completion > 0 {
            notes.append("Strongest pillar: \(best.section.name) at \(Int(best.completion * 100))%. That's your identity forming.")
        }
        if sectionRows.count > 1,
           let worst = sectionRows.min(by: { $0.completion < $1.completion }),
           worst.completion < 0.5 {
            notes.append("\(worst.section.name) slipped to \(Int(worst.completion * 100))%. Shrink it to one non-negotiable item next week — consistency first, volume later.")
        }
        if let dietRatio {
            notes.append(dietRatio >= 0.7
                         ? "Diet discipline held \(Int(dietRatio * 100))% of the week. Fuel matches ambition."
                         : "Diet held only \(Int(dietRatio * 100))% of days. Plan meals the night before — decisions made tired are decisions lost.")
        } else {
            notes.append("No diet check-ins this week. One tap a day keeps the trend honest.")
        }
        if let sleepAvg, sleepAvg > 0, sleepAvg < 6.5 {
            notes.append("Averaging \(sleepAvg.formatted(.number.precision(.fractionLength(1))))h of sleep. Nothing you're chasing survives chronic exhaustion — protect the recovery.")
        }
        if focusMinutes > 0 {
            notes.append("\(focusMinutes) deep-focus minutes logged. That's compounding in action.")
        }
        if rungsClimbed > 0 {
            notes.append("You climbed \(rungsClimbed) rung\(rungsClimbed == 1 ? "" : "s") on your goal ladder this week. Momentum is real.")
        }
        if notes.isEmpty {
            notes.append("A quiet week. The comeback starts with one checked box tomorrow morning.")
        }
        return notes
    }

    @MainActor
    private func renderShareImage() {
        let card = ReportCardShareView(
            grade: grade,
            score: Int(weeklyScore.rounded()),
            completion: Int(overallCompletion * 100),
            dietText: dietRatio.map { "\(Int($0 * 100))%" } ?? "—",
            sleepText: sleepAvg.map { "\($0.formatted(.number.precision(.fractionLength(1))))h" } ?? "—",
            focusMinutes: focusMinutes,
            activeDays: activeDays,
            streak: streak
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        if let uiImage = renderer.uiImage {
            shareImage = Image(uiImage: uiImage)
        }
    }
}

/// Fixed-size card rendered to an image for sharing.
struct ReportCardShareView: View {
    let grade: String
    let score: Int
    let completion: Int
    let dietText: String
    let sleepText: String
    let focusMinutes: Int
    let activeDays: Int
    let streak: Int

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Image(systemName: "mountain.2.fill")
                Text("DREAM CHASER")
                    .font(.system(.subheadline, design: .rounded).bold())
                    .kerning(2)
                Spacer()
                Text(Date.now.formatted(.dateTime.month().day()))
                    .font(.caption)
            }
            .foregroundStyle(.white.opacity(0.9))

            Text(grade)
                .font(.system(size: 92, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("Weekly score \(score)/100")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))

            VStack(spacing: 8) {
                statRow("Routine", "\(completion)%")
                statRow("Diet", dietText)
                statRow("Sleep", sleepText)
                statRow("Focus", "\(focusMinutes) min")
                statRow("Active days", "\(activeDays)/7")
                statRow("Streak", "\(streak) days")
            }
            .padding(16)
            .background(.white.opacity(0.12), in: .rect(cornerRadius: 20))

            Spacer(minLength: 0)
            Text("Chase the day.")
                .font(.caption.italic())
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(28)
        .frame(width: 360, height: 540)
        .background(
            LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).bold()
        }
        .font(.subheadline)
        .foregroundStyle(.white)
    }
}
