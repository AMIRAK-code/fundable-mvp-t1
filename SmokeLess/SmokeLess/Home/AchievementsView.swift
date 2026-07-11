import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var store: AppStore

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Achievement.all) { achievement in
                    card(for: achievement)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Badges")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func card(for achievement: Achievement) -> some View {
        let unlocked = achievement.isUnlocked(with: store.stats)
        let progress = achievement.progress(with: store.stats)
        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(unlocked ? AnyShapeStyle(store.theme.gradient) : AnyShapeStyle(Color(.tertiarySystemFill)))
                    .frame(width: 64, height: 64)
                Image(systemName: achievement.symbol)
                    .font(.title2)
                    .foregroundStyle(unlocked ? .white : .secondary)
            }
            Text(achievement.title)
                .font(.subheadline.bold())
                .multilineTextAlignment(.center)
            Text(achievement.detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if !unlocked {
                ProgressView(value: progress)
                    .tint(store.theme.primary)
                    .padding(.horizontal, 8)
            } else {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(store.theme.primary)
                    .font(.caption)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 170)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .opacity(unlocked ? 1 : 0.85)
    }
}
