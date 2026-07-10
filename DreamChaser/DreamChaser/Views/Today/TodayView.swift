import SwiftData
import SwiftUI

/// The daily command center: quote of the day, overall progress, the weekly
/// cleaning prompt when due, and every routine section with its checklist.
struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \RoutineSection.sortOrder) private var sections: [RoutineSection]
    @Query private var cleaningTasks: [CleaningTask]

    @State private var editingSection: RoutineSection?
    @State private var showingNewSection = false
    @State private var quote = QuoteStore.shared.todaysQuote()

    private var todayKey: String { Dates.key() }

    private var totalItems: Int {
        sections.reduce(0) { $0 + $1.items.count }
    }

    private var completedItems: Int {
        sections.reduce(0) { $0 + $1.completedCount(on: todayKey) }
    }

    private var progress: Double {
        totalItems == 0 ? 0 : Double(completedItems) / Double(totalItems)
    }

    /// Days in a row with at least one completed item.
    private var activeStreak: Int {
        var allDays = Set<String>()
        for section in sections {
            for item in section.items {
                allDays.formUnion(item.completedDates)
            }
        }
        return Dates.streak(days: allDays)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    quoteBanner
                    progressHeader
                    if let cleaning = cleaningTasks.first, cleaning.isDue {
                        CleaningPromptCard(task: cleaning)
                    }
                    ForEach(sections) { section in
                        RoutineSectionCard(section: section, todayKey: todayKey) {
                            editingSection = section
                        }
                    }
                    addSectionButton
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .background(AppBackground())
            .navigationTitle(Date.now.formatted(.dateTime.weekday(.wide).month().day()))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewSection = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $editingSection) { section in
                SectionEditorView(section: section)
            }
            .sheet(isPresented: $showingNewSection) {
                NewSectionSheet()
            }
            .onAppear {
                quote = QuoteStore.shared.todaysQuote()
            }
        }
    }

    private var quoteBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("“\(quote.text)”")
                .font(.callout.italic())
                .fixedSize(horizontal: false, vertical: true)
            Text("— \(quote.author)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(tint: .purple)
    }

    private var progressHeader: some View {
        HStack(spacing: 20) {
            ZStack {
                ProgressRing(progress: progress, lineWidth: 9, tint: .purple)
                Text(progress, format: .percent.precision(.fractionLength(0)))
                    .font(.system(.headline, design: .rounded))
                    .contentTransition(.numericText())
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(completedItems) of \(totalItems) done")
                    .font(.headline)
                Text(progress >= 1 && totalItems > 0
                     ? "Perfect day. This is how empires get built."
                     : "Win the day, one check at a time.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if activeStreak > 0 {
                VStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(activeStreak)")
                        .font(.system(.headline, design: .rounded))
                }
            }
        }
        .glassCard()
    }

    private var addSectionButton: some View {
        Button {
            showingNewSection = true
        } label: {
            Label("Add a routine section", systemImage: "plus")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.glass)
    }
}
