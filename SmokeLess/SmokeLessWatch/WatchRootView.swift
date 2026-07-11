import SwiftUI

/// Three vertically paged screens: streak, money saved, quick actions.
struct WatchRootView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        if store.state.onboardingComplete {
            TabView {
                StreakPage()
                MoneyPage()
                ActionsPage()
            }
            .tabViewStyle(.verticalPage)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "wind")
                    .font(.title2)
                    .foregroundStyle(store.theme.primary)
                Text("Set up SmokeLess on your iPhone first")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

struct StreakPage: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        let stats = store.stats
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(store.theme.primary.opacity(0.25), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: ringProgress(days: stats.streakDays))
                    .stroke(store.theme.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(store.theme.accent)
                    Text("\(stats.streakDays)")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                    Text(stats.streakDays == 1 ? "day" : "days")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 110, height: 110)
            Text("Best: \(stats.bestStreak) days")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Streak")
    }

    private func ringProgress(days: Int) -> Double {
        let inCycle = days % 30
        return days > 0 && inCycle == 0 ? 1 : Double(inCycle) / 30
    }
}

struct MoneyPage: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        let stats = store.stats
        VStack(spacing: 8) {
            Image(systemName: "banknote.fill")
                .font(.title3)
                .foregroundStyle(store.theme.accent)
            Text(stats.moneySaved, format: .currency(code: store.state.profile.currencyCode).precision(.fractionLength(0)))
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text("saved so far")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(Int(stats.unitsAvoided)) \(store.state.profile.smokingType.unitPlural) avoided")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct ActionsPage: View {
    @EnvironmentObject private var store: AppStore
    @State private var confirmation: String?

    var body: some View {
        VStack(spacing: 10) {
            if let confirmation {
                Text(confirmation)
                    .font(.footnote)
                    .foregroundStyle(store.theme.primary)
                    .multilineTextAlignment(.center)
            }

            Button {
                store.logResistedCraving()
                WatchSyncManager.shared.sendAction("resistCraving")
                confirmation = "Craving beaten 💪"
            } label: {
                Label("I resisted", systemImage: "hand.raised.fill")
            }
            .tint(store.theme.primary)

            Button {
                store.logSlip(units: 1)
                WatchSyncManager.shared.sendAction("logSlip", units: 1)
                confirmation = "Slip logged — fresh start now."
            } label: {
                Label("I slipped", systemImage: "arrow.counterclockwise")
            }
            .tint(.red)
        }
        .padding()
    }
}
