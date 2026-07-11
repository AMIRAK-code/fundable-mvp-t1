import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var health = HealthKitManager.shared
    @State private var showLogSlip = false

    private var theme: AppTheme { store.theme }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    streakCard
                    moneyCard
                    quickActions
                    if store.state.profile.goal == .reduceGradually {
                        allowanceCard
                    }
                    DailyFactCard()
                    nextMilestoneCard
                    achievementsCard
                    healthCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("SmokeLess")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        AchievementsView()
                    } label: {
                        Image(systemName: "trophy.fill")
                    }
                }
            }
            .sheet(isPresented: $showLogSlip) {
                LogSlipSheet()
                    .environmentObject(store)
            }
            .onAppear {
                if health.isAuthorized {
                    health.refresh()
                }
            }
        }
    }

    // MARK: Cards

    private var streakCard: some View {
        VStack(spacing: 12) {
            StreakRing(
                days: store.stats.streakDays,
                hours: store.stats.streakHours,
                theme: theme
            )
            HStack(spacing: 24) {
                statBlock(value: "\(store.stats.bestStreak)", label: "best streak")
                statBlock(value: "\(Int(store.stats.unitsAvoided))", label: "\(store.state.profile.smokingType.unitPlural) avoided")
                statBlock(value: "\(store.stats.resistedCount)", label: "cravings beaten")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(RoundedRectangle(cornerRadius: 20).fill(theme.gradient))
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private var moneyCard: some View {
        // Ticks every second so savings visibly grow in real time.
        TimelineView(.periodic(from: Date(), by: 1)) { context in
            let stats = Stats(state: store.state, now: context.date)
            VStack(alignment: .leading, spacing: 8) {
                Label("Money saved", systemImage: "banknote.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                Text(stats.moneySaved, format: .currency(code: store.state.profile.currencyCode))
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(theme.primary)
                    .contentTransition(.numericText())
                HStack(spacing: 4) {
                    Text("Available to spend:")
                        .foregroundStyle(.secondary)
                    Text(stats.availableSavings, format: .currency(code: store.state.profile.currencyCode))
                        .bold()
                }
                .font(.footnote)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
        }
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            Button {
                store.showCravingSOS = true
            } label: {
                Label("Craving SOS", systemImage: "lungs.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.accent)
            .foregroundStyle(.black)

            Button {
                showLogSlip = true
            } label: {
                Label("Log a slip", systemImage: "arrow.counterclockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(theme.secondary)
        }
    }

    private var allowanceCard: some View {
        let used = store.stats.todayUnits
        let allowance = store.state.profile.dailyAllowance
        let over = used > allowance
        return VStack(alignment: .leading, spacing: 8) {
            Label("Today's allowance", systemImage: "gauge.with.needle")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            ProgressView(value: min(used, allowance), total: max(allowance, 0.01))
                .tint(over ? .red : theme.primary)
            Text("\(used.formatted(.number.precision(.fractionLength(0...1)))) of \(allowance.formatted(.number.precision(.fractionLength(0...1)))) \(store.state.profile.smokingType.unitPlural)")
                .font(.footnote)
                .foregroundStyle(over ? .red : .secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
    }

    private var nextMilestoneCard: some View {
        let interval = store.stats.smokeFreeInterval
        let next = HealthMilestone.all.first { !$0.isReached(after: interval) }
        return NavigationLink {
            HealthTimelineView()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Label("Body recovery", systemImage: "heart.text.square.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                if let next {
                    HStack(spacing: 12) {
                        Image(systemName: next.symbol)
                            .font(.title2)
                            .foregroundStyle(theme.primary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Next: \(next.title)")
                                .font(.headline)
                                .foregroundStyle(Color.primary)
                            ProgressView(value: next.progress(after: interval))
                                .tint(theme.primary)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                } else {
                    Text("All milestones reached — incredible! 🎉")
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
        }
        .buttonStyle(.plain)
    }

    private var achievementsCard: some View {
        let next = Achievement.all
            .filter { !$0.isUnlocked(with: store.stats) }
            .max { $0.progress(with: store.stats) < $1.progress(with: store.stats) }
        return NavigationLink {
            AchievementsView()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Label("Next badge", systemImage: "rosette")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                if let next {
                    HStack(spacing: 12) {
                        Image(systemName: next.symbol)
                            .font(.title2)
                            .foregroundStyle(theme.accent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(next.title)
                                .font(.headline)
                                .foregroundStyle(Color.primary)
                            Text(next.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ProgressView(value: next.progress(with: store.stats))
                                .tint(theme.accent)
                        }
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                } else {
                    Text("Every badge unlocked!")
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
        }
        .buttonStyle(.plain)
    }

    private var healthCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Today's activity", systemImage: "figure.run")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            if health.isAuthorized {
                HStack(spacing: 24) {
                    VStack(alignment: .leading) {
                        Text("\(Int(health.todayActiveEnergy ?? 0))")
                            .font(.title2.bold())
                            .foregroundStyle(theme.primary)
                        Text("kcal burned")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading) {
                        Text("\(Int(health.todayExerciseMinutes ?? 0))")
                            .font(.title2.bold())
                            .foregroundStyle(theme.primary)
                        Text("exercise min")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Text("Movement blunts cravings — a 5-minute walk can beat one.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Connect Apple Health to see your activity here and log breathing exercises as mindful minutes.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Connect Apple Health") {
                    health.requestAccess()
                }
                .buttonStyle(.bordered)
                .tint(theme.primary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
    }
}
