import SwiftUI

/// Shows today's rotating fact about the problems of smoking.
struct DailyFactCard: View {
    @EnvironmentObject private var store: AppStore

    private var fact: DailyFact { DailyFact.fact(for: Date()) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Did you know?", systemImage: "lightbulb.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(store.theme.accent)
                Spacer()
                Text(fact.category)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(store.theme.primary.opacity(0.15)))
                    .foregroundStyle(store.theme.primary)
            }
            Text(fact.text)
                .font(.callout)
                .foregroundStyle(Color.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(store.theme.accent.opacity(0.4), lineWidth: 1)
        )
    }
}
