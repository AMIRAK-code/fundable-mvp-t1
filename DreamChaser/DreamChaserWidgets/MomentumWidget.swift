import SwiftData
import SwiftUI
import WidgetKit

/// The one number to protect every day. Reads the score the app cached in
/// the App Group; falls back to recomputing the routine part from the store.
struct MomentumEntry: TimelineEntry {
    let date: Date
    let score: Int
    let streak: Int
    let tokens: Int

    static let preview = MomentumEntry(date: .now, score: 78, streak: 6, tokens: 1)
}

struct MomentumProvider: TimelineProvider {
    func placeholder(in context: Context) -> MomentumEntry {
        .preview
    }

    func getSnapshot(in context: Context, completion: @escaping (MomentumEntry) -> Void) {
        completion(context.isPreview ? .preview : loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MomentumEntry>) -> Void) {
        let refresh = Date.now.addingTimeInterval(2 * 3600)
        completion(Timeline(entries: [loadEntry()], policy: .after(refresh)))
    }

    private func loadEntry() -> MomentumEntry {
        if let cached = MomentumEngine.cachedScore() {
            return MomentumEntry(date: .now, score: cached.score, streak: cached.streak, tokens: MomentumEngine.tokens)
        }
        let container = SharedStore.makeContainer()
        let modelContext = ModelContext(container)
        let items = (try? modelContext.fetch(FetchDescriptor<RoutineItem>())) ?? []
        let todayKey = Dates.key()
        let completion = items.isEmpty
            ? 0
            : Double(items.filter { $0.isDone(on: todayKey) }.count) / Double(items.count)
        let streak = MomentumEngine.streak(items: items)
        let score = MomentumEngine.score(
            routineCompletion: completion,
            streakDays: streak,
            dietRatio: nil,
            sleepHours: MomentumEngine.lastSleepHours
        )
        return MomentumEntry(date: .now, score: score, streak: streak, tokens: MomentumEngine.tokens)
    }
}

struct MomentumWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: MomentumEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                Gauge(value: Double(entry.score), in: 0...100) {
                    Image(systemName: "bolt.fill")
                } currentValueLabel: {
                    Text("\(entry.score)")
                }
                .gaugeStyle(.accessoryCircular)
            default:
                small
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color.purple.opacity(0.4), Color.indigo.opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var small: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: Double(entry.score) / 100)
                    .stroke(Color.purple, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(entry.score)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                    Text("MOMENTUM")
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 76, height: 76)
            HStack(spacing: 12) {
                if entry.streak > 0 {
                    Label("\(entry.streak)", systemImage: "flame.fill")
                        .foregroundStyle(.orange)
                }
                if entry.tokens > 0 {
                    Label("\(entry.tokens)", systemImage: "shield.fill")
                        .foregroundStyle(.teal)
                }
                if entry.streak == 0 && entry.tokens == 0 {
                    Text("Build the chain")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.caption2.bold())
        }
    }
}

struct MomentumWidget: Widget {
    let kind = "MomentumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MomentumProvider()) { entry in
            MomentumWidgetView(entry: entry)
        }
        .configurationDisplayName("Momentum")
        .description("Your daily 0–100 score: routine, streak, diet, and sleep in one number.")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}
