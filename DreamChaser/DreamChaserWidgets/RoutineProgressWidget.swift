import AppIntents
import SwiftData
import SwiftUI
import WidgetKit

/// Home-screen view of today's routine: overall progress ring, per-section
/// dots, and (in the medium size) interactive checkboxes for the next items —
/// check them off without opening the app.
struct RoutineEntry: TimelineEntry {
    struct SectionSummary: Identifiable {
        let id: String
        let symbol: String
        let colorName: String
        let completed: Int
        let total: Int
    }

    struct ItemSummary: Identifiable {
        let id: String
        let title: String
        let done: Bool
    }

    let date: Date
    let completed: Int
    let total: Int
    let sections: [SectionSummary]
    let remainingItems: [ItemSummary]

    var progress: Double {
        total == 0 ? 0 : Double(completed) / Double(total)
    }

    static let preview = RoutineEntry(
        date: .now,
        completed: 4,
        total: 11,
        sections: [
            SectionSummary(id: "1", symbol: "dumbbell", colorName: "orange", completed: 2, total: 3),
            SectionSummary(id: "2", symbol: "book.fill", colorName: "blue", completed: 1, total: 2),
            SectionSummary(id: "3", symbol: "briefcase.fill", colorName: "indigo", completed: 1, total: 2),
        ],
        remainingItems: [
            ItemSummary(id: "a", title: "Train for 60 minutes", done: false),
            ItemSummary(id: "b", title: "Deep-focus study block", done: false),
            ItemSummary(id: "c", title: "Plan tomorrow before bed", done: false),
        ]
    )
}

struct RoutineProvider: TimelineProvider {
    func placeholder(in context: Context) -> RoutineEntry {
        .preview
    }

    func getSnapshot(in context: Context, completion: @escaping (RoutineEntry) -> Void) {
        completion(context.isPreview ? .preview : loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RoutineEntry>) -> Void) {
        completion(Timeline(entries: [loadEntry()], policy: .after(Dates.startOfTomorrow)))
    }

    private func loadEntry() -> RoutineEntry {
        let container = SharedStore.makeContainer()
        let modelContext = ModelContext(container)
        let todayKey = Dates.key()
        let sections = (try? modelContext.fetch(
            FetchDescriptor<RoutineSection>(sortBy: [SortDescriptor(\.sortOrder)])
        )) ?? []

        var completed = 0
        var total = 0
        var summaries: [RoutineEntry.SectionSummary] = []
        var remaining: [RoutineEntry.ItemSummary] = []

        for section in sections {
            let done = section.completedCount(on: todayKey)
            completed += done
            total += section.items.count
            summaries.append(RoutineEntry.SectionSummary(
                id: section.persistentModelID.hashValue.description,
                symbol: section.symbol,
                colorName: section.colorName,
                completed: done,
                total: section.items.count
            ))
            for item in section.sortedItems where !item.isDone(on: todayKey) {
                remaining.append(RoutineEntry.ItemSummary(
                    id: item.uuid.uuidString,
                    title: item.title,
                    done: false
                ))
            }
        }

        return RoutineEntry(
            date: .now,
            completed: completed,
            total: total,
            sections: summaries,
            remainingItems: Array(remaining.prefix(3))
        )
    }
}

struct RoutineProgressWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: RoutineEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                accessoryCircular
            case .systemMedium:
                medium
            default:
                small
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color.purple.opacity(0.35), Color.indigo.opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var accessoryCircular: some View {
        Gauge(value: entry.progress) {
            Image(systemName: "flag.checkered")
        } currentValueLabel: {
            Text("\(entry.completed)/\(entry.total)")
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }

    private var small: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: max(0, min(1, entry.progress)))
                    .stroke(Color.purple, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(entry.completed)/\(entry.total)")
                    .font(.system(.headline, design: .rounded))
            }
            .frame(width: 68, height: 68)
            Text(entry.progress >= 1 && entry.total > 0 ? "Day won 🏆" : "Chase the day")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var medium: some View {
        HStack(spacing: 16) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(.quaternary, lineWidth: 7)
                    Circle()
                        .trim(from: 0, to: max(0, min(1, entry.progress)))
                        .stroke(Color.purple, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(entry.completed)/\(entry.total)")
                        .font(.system(.subheadline, design: .rounded).bold())
                }
                .frame(width: 56, height: 56)
                HStack(spacing: 4) {
                    ForEach(entry.sections.prefix(5)) { section in
                        Image(systemName: section.symbol)
                            .font(.system(size: 9))
                            .foregroundStyle(section.completed >= section.total && section.total > 0
                                             ? ThemeColor.color(for: section.colorName)
                                             : .secondary)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                if entry.remainingItems.isEmpty {
                    Text(entry.total > 0 ? "All done. Legend." : "Add routines in the app")
                        .font(.subheadline.bold())
                } else {
                    Text("Up next")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                    ForEach(entry.remainingItems) { item in
                        Button(intent: ToggleRoutineItemIntent(itemID: item.id)) {
                            HStack(spacing: 6) {
                                Image(systemName: "circle")
                                    .font(.caption)
                                Text(item.title)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct RoutineProgressWidget: Widget {
    let kind = "RoutineProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RoutineProvider()) { entry in
            RoutineProgressWidgetView(entry: entry)
        }
        .configurationDisplayName("Today's Routine")
        .description("Your daily progress ring — check items off right from the Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
    }
}
