import SwiftData
import SwiftUI
import WidgetKit

/// The daily command center: quote of the day, momentum + progress header,
/// morning/evening bookends, burnout guardrail, the weekly cleaning prompt
/// when due, and every routine section with its checklist.
struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \RoutineSection.sortOrder) private var sections: [RoutineSection]
    @Query private var cleaningTasks: [CleaningTask]
    @Query private var dietDays: [DietDay]
    @Query private var journalEntries: [JournalEntry]

    @State private var editingSection: RoutineSection?
    @State private var showingNewSection = false
    @State private var showingWeeklyReview = false
    @State private var showingMorningBrief = false
    @State private var showingEveningReview = false
    @State private var focusSection: RoutineSection?
    @State private var quote = QuoteStore.shared.todaysQuote()

    private var todayKey: String { Dates.key() }

    private var allItems: [RoutineItem] {
        sections.flatMap(\.items)
    }

    private var totalItems: Int {
        allItems.count
    }

    private var completedItems: Int {
        sections.reduce(0) { $0 + $1.completedCount(on: todayKey) }
    }

    private var progress: Double {
        totalItems == 0 ? 0 : Double(completedItems) / Double(totalItems)
    }

    private var streak: Int {
        MomentumEngine.streak(items: allItems)
    }

    private var dietRatio: Double? {
        let recent = Set(Dates.recentKeys(count: 7))
        let entries = dietDays.filter { recent.contains($0.dateKey) }
        guard !entries.isEmpty else { return nil }
        return Double(entries.filter(\.stuckToDiet).count) / Double(entries.count)
    }

    private var momentum: Int {
        MomentumEngine.score(
            routineCompletion: progress,
            streakDays: streak,
            dietRatio: dietRatio,
            sleepHours: MomentumEngine.lastSleepHours
        )
    }

    private var todayJournal: JournalEntry? {
        journalEntries.first { $0.dateKey == todayKey }
    }

    private var hour: Int {
        Calendar.current.component(.hour, from: .now)
    }

    /// Burnout guardrail: short sleep while deep in a streak → suggest rest.
    private var suggestsRecovery: Bool {
        guard let sleep = MomentumEngine.lastSleepHours else { return false }
        return sleep < 6 && streak >= 3
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    quoteBanner
                    progressHeader
                    if hour < 12, !(todayJournal?.morningCommitted ?? false) {
                        bookendCard(
                            title: "Morning brief",
                            subtitle: "Commit to the day · 30 sec",
                            symbol: "sunrise.fill",
                            tint: .yellow
                        ) { showingMorningBrief = true }
                    }
                    if hour >= 18, !(todayJournal?.eveningCompleted ?? false) {
                        bookendCard(
                            title: "Evening shutdown",
                            subtitle: "Log your win, close the loop",
                            symbol: "sunset.fill",
                            tint: .indigo
                        ) { showingEveningReview = true }
                    }
                    if suggestsRecovery {
                        recoveryCard
                    }
                    if let cleaning = cleaningTasks.first, cleaning.isDue {
                        CleaningPromptCard(task: cleaning)
                    }
                    ForEach(sections) { section in
                        RoutineSectionCard(
                            section: section,
                            todayKey: todayKey,
                            onEdit: { editingSection = section },
                            onFocus: { focusSection = section }
                        )
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
                        showingWeeklyReview = true
                    } label: {
                        Image(systemName: "chart.bar.xaxis")
                    }
                }
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
            .sheet(isPresented: $showingWeeklyReview) {
                WeeklyReviewView()
            }
            .sheet(isPresented: $showingMorningBrief) {
                MorningBriefView()
            }
            .sheet(isPresented: $showingEveningReview) {
                EveningReviewView()
            }
            .sheet(item: $focusSection) { section in
                FocusTimerView(
                    sectionName: section.name,
                    symbol: section.symbol,
                    colorName: section.colorName
                )
            }
            .onAppear {
                quote = QuoteStore.shared.todaysQuote()
                MomentumEngine.runDailyMaintenance(items: allItems)
                refreshMomentumCache()
            }
            .onChange(of: completedItems) {
                refreshMomentumCache()
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

            VStack(alignment: .leading, spacing: 6) {
                Text("\(completedItems) of \(totalItems) done")
                    .font(.headline)
                Text(progress >= 1 && totalItems > 0
                     ? "Perfect day. This is how empires get built."
                     : "Win the day, one check at a time.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 14) {
                    Label("\(momentum)", systemImage: "bolt.fill")
                        .foregroundStyle(.purple)
                    if streak > 0 {
                        Label("\(streak)", systemImage: "flame.fill")
                            .foregroundStyle(.orange)
                    }
                    if MomentumEngine.tokens > 0 {
                        Label("\(MomentumEngine.tokens)", systemImage: "shield.fill")
                            .foregroundStyle(.teal)
                    }
                }
                .font(.caption.bold())
            }
            Spacer()
        }
        .glassCard()
    }

    private func bookendCard(title: String, subtitle: String, symbol: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .glassCard(tint: tint)
    }

    private var recoveryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Recovery mode suggested", systemImage: "bed.double.fill")
                .font(.headline)
            Text("You slept under 6 hours and you're \(streak) days deep. Ambition compounds on rest — go lighter today and protect the streak.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(tint: .mint)
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

    private func refreshMomentumCache() {
        MomentumEngine.cache(score: momentum, streak: streak)
        WidgetCenter.shared.reloadTimelines(ofKind: "MomentumWidget")
    }
}
