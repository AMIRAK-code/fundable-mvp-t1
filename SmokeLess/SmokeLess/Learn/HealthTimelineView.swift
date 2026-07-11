import SwiftUI

/// Timeline of body-recovery milestones anchored to the last logged smoke.
struct HealthTimelineView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        let interval = store.stats.smokeFreeInterval
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Smoke-free since")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(store.stats.healthAnchor, format: .dateTime.day().month().year().hour().minute())
                        .font(.headline)
                }
            }

            Section("Your body is healing") {
                ForEach(HealthMilestone.all) { milestone in
                    row(milestone, interval: interval)
                }
            }

            Section {
                Text("Timelines are based on widely published public-health guidance (WHO/CDC) and vary by person. Educational only — not medical advice.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Body recovery")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ milestone: HealthMilestone, interval: TimeInterval) -> some View {
        let reached = milestone.isReached(after: interval)
        let progress = milestone.progress(after: interval)
        return HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(reached ? AnyShapeStyle(store.theme.gradient) : AnyShapeStyle(Color(.tertiarySystemFill)))
                    .frame(width: 40, height: 40)
                Image(systemName: reached ? "checkmark" : milestone.symbol)
                    .font(.subheadline)
                    .foregroundStyle(reached ? .white : .secondary)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.title)
                    .font(.headline)
                Text(milestone.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if !reached {
                    ProgressView(value: progress)
                        .tint(store.theme.primary)
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(reached ? 1 : 0.9)
    }
}
