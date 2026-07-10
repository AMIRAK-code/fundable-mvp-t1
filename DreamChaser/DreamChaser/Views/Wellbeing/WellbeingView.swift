import SwiftData
import SwiftUI

/// Wellbeing hub: Apple Health stats, the daily diet check-in, skincare
/// routines (AM/PM), and the weekly cleaning cadence.
struct WellbeingView: View {
    @Environment(\.modelContext) private var context
    @State private var health = HealthKitService()

    @Query private var dietDays: [DietDay]
    @Query(sort: \SkincareStep.sortOrder) private var skincareSteps: [SkincareStep]
    @Query private var cleaningTasks: [CleaningTask]

    @State private var dietNote = ""
    @State private var showingSkincareEditor = false
    @State private var checkPulse = 0

    private var todayKey: String { Dates.key() }

    private var todayDiet: DietDay? {
        dietDays.first { $0.dateKey == todayKey }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    healthSection
                    dietCard
                    skincareCard
                    cleaningCard
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .background(AppBackground())
            .navigationTitle("Wellbeing")
            .sheet(isPresented: $showingSkincareEditor) {
                SkincareEditorView()
            }
            .task {
                await health.requestAuthorization()
            }
            .refreshable {
                await health.refresh()
            }
            .sensoryFeedback(.success, trigger: checkPulse)
        }
    }

    // MARK: Apple Health

    private var healthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Fitness · Apple Health", systemImage: "heart.text.square.fill")
                    .font(.headline)
                Spacer()
                Button {
                    Task { await health.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline)
                }
                .buttonStyle(.glass)
            }
            if health.isAvailable {
                GlassEffectContainer(spacing: 12) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatTile(
                            title: "Steps",
                            value: health.steps.formatted(.number.precision(.fractionLength(0))),
                            symbol: "figure.walk",
                            color: .green
                        )
                        StatTile(
                            title: "Active energy",
                            value: health.activeEnergy.formatted(.number.precision(.fractionLength(0))),
                            unit: "kcal",
                            symbol: "flame.fill",
                            color: .orange
                        )
                        StatTile(
                            title: "Exercise",
                            value: health.exerciseMinutes.formatted(.number.precision(.fractionLength(0))),
                            unit: "min",
                            symbol: "figure.strengthtraining.traditional",
                            color: .red
                        )
                        StatTile(
                            title: "Sleep",
                            value: health.sleepHours.formatted(.number.precision(.fractionLength(1))),
                            unit: "h",
                            symbol: "moon.zzz.fill",
                            color: .indigo
                        )
                    }
                }
                Text("Numbers stuck at zero? Grant access in the Health app → Sharing.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Text("Apple Health isn't available on this device.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Diet

    private var dietCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Diet", systemImage: "fork.knife")
                .font(.headline)
            Text("Did you stick to your plan today?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                dietButton(stuck: true, label: "On track", symbol: "checkmark.seal.fill")
                dietButton(stuck: false, label: "Slipped", symbol: "arrow.uturn.down")
            }
            TextField("Add a note (optional)", text: $dietNote)
                .font(.subheadline)
                .onSubmit(saveDietNote)
            weekStrip
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(tint: .green)
        .onAppear {
            dietNote = todayDiet?.note ?? ""
        }
    }

    private func dietButton(stuck: Bool, label: String, symbol: String) -> some View {
        let isSelected = todayDiet?.stuckToDiet == stuck
        return Button {
            setDiet(stuck: stuck)
        } label: {
            Label(label, systemImage: symbol)
                .font(.subheadline.bold())
                .foregroundStyle(isSelected ? (stuck ? Color.green : Color.orange) : Color.secondary)
                .padding(.horizontal, 4)
        }
        .buttonStyle(.glass)
    }

    /// Last 7 days: green = on track, orange = slipped, hollow = no check-in.
    private var weekStrip: some View {
        HStack(spacing: 8) {
            ForEach(Dates.recentKeys(count: 7), id: \.self) { key in
                let day = dietDays.first { $0.dateKey == key }
                let fill: Color = day.map { $0.stuckToDiet ? .green : .orange } ?? .clear
                ZStack {
                    Circle().fill(fill)
                    Circle().strokeBorder(.quaternary, lineWidth: 1)
                }
                .frame(width: 14, height: 14)
            }
            Spacer()
            Text("last 7 days")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private func setDiet(stuck: Bool) {
        if let existing = todayDiet {
            existing.stuckToDiet = stuck
        } else {
            context.insert(DietDay(dateKey: todayKey, stuckToDiet: stuck, note: dietNote))
        }
        checkPulse += 1
        try? context.save()
    }

    private func saveDietNote() {
        guard let existing = todayDiet else { return }
        existing.note = dietNote
        try? context.save()
    }

    // MARK: Skincare

    private var skincareCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Skincare", systemImage: "drop.fill")
                    .font(.headline)
                Spacer()
                Button("Edit") {
                    showingSkincareEditor = true
                }
                .font(.subheadline)
                .buttonStyle(.glass)
            }
            skincareGroup(title: "Morning", symbol: "sun.max.fill", timeOfDay: "morning")
            skincareGroup(title: "Evening", symbol: "moon.fill", timeOfDay: "evening")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(tint: .blue)
    }

    private func skincareGroup(title: String, symbol: String, timeOfDay: String) -> some View {
        let steps = skincareSteps.filter { $0.timeOfDay == timeOfDay }
        return VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            ForEach(steps) { step in
                let done = step.isDone(on: todayKey)
                Button {
                    withAnimation(.snappy) {
                        step.toggle(on: todayKey)
                    }
                    if step.isDone(on: todayKey) { checkPulse += 1 }
                    try? context.save()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: done ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(done ? Color.blue : Color.secondary)
                            .contentTransition(.symbolEffect(.replace))
                        Text(step.title)
                            .strikethrough(done)
                            .foregroundStyle(done ? .secondary : .primary)
                        Spacer()
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Cleaning

    private var cleaningCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Space reset", systemImage: "sparkles")
                .font(.headline)
            if let task = cleaningTasks.first {
                if let last = task.lastCompleted {
                    Text("Last reset \(last.formatted(.relative(presentation: .named))) · next due \(task.nextDue.formatted(.dateTime.weekday(.wide).month().day()))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No reset logged yet. Start the habit this week.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text("\(task.completedDates.count) resets logged")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Button("Mark cleaned today") {
                    task.markDone()
                    checkPulse += 1
                    try? context.save()
                }
                .buttonStyle(.glassProminent)
                .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(tint: .teal)
    }
}
