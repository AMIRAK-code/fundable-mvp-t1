import SwiftData
import SwiftUI

/// A ready-made "optimal day" the user picks during onboarding. Everything
/// is editable afterwards — this just removes the blank-page problem.
struct RoutineTemplate: Identifiable {
    typealias SectionSpec = (name: String, symbol: String, colorName: String, items: [String])

    let id: String
    let name: String
    let tagline: String
    let symbol: String
    let sections: [SectionSpec]

    func apply(in context: ModelContext) {
        for (index, spec) in sections.enumerated() {
            let section = RoutineSection(name: spec.name, symbol: spec.symbol, colorName: spec.colorName, sortOrder: index)
            context.insert(section)
            for (itemIndex, title) in spec.items.enumerated() {
                let item = RoutineItem(title: title, sortOrder: itemIndex)
                item.section = section
                context.insert(item)
            }
        }
        try? context.save()
    }

    static let all: [RoutineTemplate] = [balanced, fiveAMClub, studentAthlete, founderMode, glowUp]

    static let balanced = RoutineTemplate(
        id: "balanced",
        name: "Balanced Chaser",
        tagline: "The classic five pillars — train, learn, earn, plan, grow.",
        symbol: "circle.hexagongrid.fill",
        sections: [
            ("Gym", "dumbbell", "orange", ["Train for 60 minutes", "Hit protein target", "10k steps"]),
            ("Study", "book.fill", "blue", ["Deep-focus study block", "Review notes"]),
            ("Work", "briefcase.fill", "indigo", ["Top priority task first", "Inbox zero by evening"]),
            ("Plan", "calendar", "teal", ["Plan tomorrow before bed", "Review weekly goals"]),
            ("Learn a Skill", "brain.head.profile", "purple", ["30 minutes of practice", "Log one thing you learned"]),
        ]
    )

    static let fiveAMClub = RoutineTemplate(
        id: "fiveam",
        name: "5 AM Club",
        tagline: "Own the morning, own the day. 20/20/20 before the world wakes.",
        symbol: "sunrise.fill",
        sections: [
            ("Morning Ritual", "sunrise.fill", "yellow", ["Up at 5:00", "20 min movement", "20 min reflection", "20 min learning"]),
            ("Gym", "dumbbell", "orange", ["Main training session", "10k steps"]),
            ("Work", "briefcase.fill", "indigo", ["Deep work before noon", "Top priority task first"]),
            ("Plan", "calendar", "teal", ["Shut down by 9 PM", "Plan tomorrow before bed"]),
        ]
    )

    static let studentAthlete = RoutineTemplate(
        id: "student",
        name: "Student Athlete",
        tagline: "Grades and gains — recovery is part of the program.",
        symbol: "figure.run",
        sections: [
            ("Training", "figure.run", "orange", ["Practice / training session", "Mobility 15 min"]),
            ("Study", "book.fill", "blue", ["Two deep-focus blocks", "Review lecture notes", "Prep for next class"]),
            ("Recovery", "bed.double.fill", "mint", ["8 hours of sleep", "Hydration target", "Stretch before bed"]),
            ("Plan", "calendar", "teal", ["Plan tomorrow before bed"]),
        ]
    )

    static let founderMode = RoutineTemplate(
        id: "founder",
        name: "Founder Mode",
        tagline: "Build, ship, sell — and stay strong enough to keep doing it.",
        symbol: "hammer.fill",
        sections: [
            ("Deep Work", "laptopcomputer", "indigo", ["3-hour maker block", "Ship one thing daily"]),
            ("Growth", "megaphone.fill", "pink", ["Talk to one user/customer", "One outreach or post"]),
            ("Gym", "dumbbell", "orange", ["Train for 45 minutes", "10k steps"]),
            ("Plan", "calendar", "teal", ["Review metrics", "Plan tomorrow before bed"]),
        ]
    )

    static let glowUp = RoutineTemplate(
        id: "glowup",
        name: "Glow-Up Protocol",
        tagline: "Body, mind, and presence — become the person you're becoming.",
        symbol: "sparkles",
        sections: [
            ("Gym", "dumbbell", "orange", ["Train for 60 minutes", "Hit protein target"]),
            ("Self-Care", "drop.fill", "pink", ["Morning skincare", "Evening skincare", "Posture check"]),
            ("Mind", "brain.head.profile", "purple", ["Read 20 pages", "10 min meditation"]),
            ("Plan", "calendar", "teal", ["Plan tomorrow before bed"]),
        ]
    )
}

/// First-launch template picker. Sets `hasOnboarded` when a protocol is
/// chosen, which dismisses the full-screen cover in RootView.
struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("hasOnboarded.v1") private var hasOnboarded = false

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 16) {
                    header
                    ForEach(RoutineTemplate.all) { template in
                        templateCard(template)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "mountain.2.fill")
                .font(.system(size: 44))
                .foregroundStyle(.purple)
            Text("Design your optimal day")
                .font(.title.bold())
            Text("Pick a starting protocol. Every section and item stays fully customizable.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 48)
        .padding(.bottom, 8)
    }

    private func templateCard(_ template: RoutineTemplate) -> some View {
        Button {
            template.apply(in: context)
            hasOnboarded = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Label(template.name, systemImage: template.symbol)
                    .font(.headline)
                Text(template.tagline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 8) {
                    ForEach(template.sections.indices, id: \.self) { index in
                        Image(systemName: template.sections[index].symbol)
                            .font(.caption)
                            .foregroundStyle(ThemeColor.color(for: template.sections[index].colorName))
                    }
                    Spacer()
                    Text("\(template.sections.count) sections")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .glassCard()
    }
}
