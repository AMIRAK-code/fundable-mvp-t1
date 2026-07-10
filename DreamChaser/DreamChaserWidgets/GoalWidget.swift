import SwiftData
import SwiftUI
import WidgetKit

/// Keeps the ultimate goal in sight: overall progress and the next mini goal.
struct GoalEntry: TimelineEntry {
    let date: Date
    let goalTitle: String?
    let progress: Double
    let completed: Int
    let total: Int
    let nextStep: String?

    static let preview = GoalEntry(
        date: .now,
        goalTitle: "Launch my company",
        progress: 0.4,
        completed: 2,
        total: 5,
        nextStep: "Ship the MVP"
    )
}

struct GoalProvider: TimelineProvider {
    func placeholder(in context: Context) -> GoalEntry {
        .preview
    }

    func getSnapshot(in context: Context, completion: @escaping (GoalEntry) -> Void) {
        completion(context.isPreview ? .preview : loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GoalEntry>) -> Void) {
        completion(Timeline(entries: [loadEntry()], policy: .after(Dates.startOfTomorrow)))
    }

    private func loadEntry() -> GoalEntry {
        let container = SharedStore.makeContainer()
        let modelContext = ModelContext(container)
        let goals = (try? modelContext.fetch(
            FetchDescriptor<UltimateGoal>(sortBy: [SortDescriptor(\.createdAt)])
        )) ?? []
        guard let goal = goals.first else {
            return GoalEntry(date: .now, goalTitle: nil, progress: 0, completed: 0, total: 0, nextStep: nil)
        }
        return GoalEntry(
            date: .now,
            goalTitle: goal.title,
            progress: goal.progress,
            completed: goal.completedCount,
            total: goal.miniGoals.count,
            nextStep: goal.nextMiniGoal?.title
        )
    }
}

struct GoalWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: GoalEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular:
                accessoryRectangular
            case .accessoryInline:
                Text(entry.nextStep.map { "Next: \($0)" } ?? "Set your goal")
            default:
                small
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color.orange.opacity(0.3), Color.pink.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let title = entry.goalTitle {
                Label {
                    Text(title)
                        .font(.caption.bold())
                        .lineLimit(2)
                } icon: {
                    Image(systemName: "mountain.2.fill")
                        .foregroundStyle(.orange)
                }
                ProgressView(value: entry.progress)
                    .tint(.orange)
                Text("\(entry.completed) of \(entry.total) mini goals")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let next = entry.nextStep {
                    Spacer(minLength: 0)
                    Text("Next: \(next)")
                        .font(.caption2.bold())
                        .lineLimit(2)
                }
            } else {
                Image(systemName: "mountain.2.fill")
                    .foregroundStyle(.orange)
                Text("Set your ultimate goal in Dream Chaser")
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var accessoryRectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.goalTitle ?? "Set your goal")
                .font(.caption.bold())
                .lineLimit(1)
            if entry.total > 0 {
                ProgressView(value: entry.progress)
            }
            if let next = entry.nextStep {
                Text("Next: \(next)")
                    .font(.caption2)
                    .lineLimit(1)
            }
        }
    }
}

struct GoalWidget: Widget {
    let kind = "GoalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GoalProvider()) { entry in
            GoalWidgetView(entry: entry)
        }
        .configurationDisplayName("Ultimate Goal")
        .description("Your dream and the very next step toward it.")
        .supportedFamilies([.systemSmall, .accessoryRectangular, .accessoryInline])
    }
}
