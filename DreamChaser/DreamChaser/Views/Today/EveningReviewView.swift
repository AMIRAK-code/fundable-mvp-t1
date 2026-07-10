import SwiftData
import SwiftUI

/// Evening shutdown: see how the day scored, log the win of the day and an
/// optional reflection, and close the loop.
struct EveningReviewView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RoutineSection.sortOrder) private var sections: [RoutineSection]
    @Query private var journalEntries: [JournalEntry]

    @State private var win = ""
    @State private var note = ""
    @State private var closedPulse = 0

    private var todayKey: String { Dates.key() }

    private var completedItems: Int {
        sections.reduce(0) { $0 + $1.completedCount(on: todayKey) }
    }

    private var totalItems: Int {
        sections.reduce(0) { $0 + $1.items.count }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Image(systemName: "sunset.fill")
                            .font(.title)
                            .foregroundStyle(.indigo)
                        Text("\(completedItems) of \(totalItems) done today")
                            .font(.headline)
                        Text(completedItems == totalItems && totalItems > 0
                             ? "A perfect day. Bank it and rest."
                             : "Done is data. Tomorrow you adjust and go again.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .glassCard(tint: .indigo)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Win of the day")
                            .font(.headline)
                        TextField("The one thing that moved you forward", text: $win, axis: .vertical)
                            .lineLimit(1...3)
                        Text("Reflection (optional)")
                            .font(.headline)
                        TextField("What would make tomorrow 1% better?", text: $note, axis: .vertical)
                            .lineLimit(2...4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard()

                    Button {
                        closeDay()
                    } label: {
                        Text("Close the day")
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
            .navigationTitle("Evening Shutdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Later") { dismiss() }
                }
            }
            .onAppear(perform: prefill)
            .sensoryFeedback(.success, trigger: closedPulse)
        }
    }

    private func prefill() {
        guard let entry = journalEntries.first(where: { $0.dateKey == todayKey }) else { return }
        win = entry.win
        note = entry.note
    }

    private func closeDay() {
        let entry = journalEntries.first { $0.dateKey == todayKey } ?? {
            let new = JournalEntry(dateKey: todayKey)
            context.insert(new)
            return new
        }()
        entry.win = win.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.eveningCompleted = true
        entry.updatedAt = .now
        try? context.save()
        closedPulse += 1
        dismiss()
    }
}
