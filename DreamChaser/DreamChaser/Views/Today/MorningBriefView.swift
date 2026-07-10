import SwiftData
import SwiftUI

/// 30-second morning bookend: today's quote, the plan, the next goal rung,
/// and a single commit button.
struct MorningBriefView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RoutineSection.sortOrder) private var sections: [RoutineSection]
    @Query(sort: \UltimateGoal.createdAt) private var goals: [UltimateGoal]
    @Query private var journalEntries: [JournalEntry]

    @State private var quote = QuoteStore.shared.todaysQuote()
    @State private var committedPulse = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 10) {
                        Image(systemName: "sunrise.fill")
                            .font(.title)
                            .foregroundStyle(.yellow)
                        Text("“\(quote.text)”")
                            .font(.callout.italic())
                            .multilineTextAlignment(.center)
                        Text("— \(quote.author)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .glassCard(tint: .yellow)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("The plan")
                            .font(.headline)
                        ForEach(sections) { section in
                            HStack(spacing: 10) {
                                Image(systemName: section.symbol)
                                    .foregroundStyle(ThemeColor.color(for: section.colorName))
                                    .frame(width: 24)
                                Text(section.name)
                                Spacer()
                                Text("\(section.items.count) item\(section.items.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard()

                    if let nextStep = goals.first?.nextMiniGoal {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Today's rung", systemImage: "flag.checkered")
                                .font(.headline)
                            Text(nextStep.title)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassCard(tint: .orange)
                    }

                    Button {
                        commit()
                    } label: {
                        Text("I commit to today")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.glassProminent)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(AppBackground())
            .navigationTitle("Morning Brief")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Later") { dismiss() }
                }
            }
            .sensoryFeedback(.success, trigger: committedPulse)
        }
    }

    private func commit() {
        let key = Dates.key()
        let entry = journalEntries.first { $0.dateKey == key } ?? {
            let new = JournalEntry(dateKey: key)
            context.insert(new)
            return new
        }()
        entry.morningCommitted = true
        entry.updatedAt = .now
        try? context.save()
        committedPulse += 1
        dismiss()
    }
}
