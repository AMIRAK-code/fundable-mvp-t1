import WidgetKit
import SwiftUI

struct StatusEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

struct StatusProvider: TimelineProvider {

    private var sample: WidgetSnapshot {
        WidgetSnapshot(
            petName: "Maple",
            speciesRawValue: PetSpecies.dog.rawValue,
            wellnessScore: 86,
            streakDays: 5,
            lastLogDate: Date(),
            dueDescription: "Next check-in this evening",
            generatedAt: Date()
        )
    }

    func placeholder(in context: Context) -> StatusEntry {
        StatusEntry(date: Date(), snapshot: sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (StatusEntry) -> Void) {
        if context.isPreview {
            completion(StatusEntry(date: Date(), snapshot: SharedStorage.loadSnapshot() ?? sample))
        } else {
            completion(StatusEntry(date: Date(), snapshot: SharedStorage.loadSnapshot()))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatusEntry>) -> Void) {
        let entry = StatusEntry(date: Date(), snapshot: SharedStorage.loadSnapshot())
        let refresh = Date().addingTimeInterval(30 * 60)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

struct MiniWellnessRing: View {
    let score: Int?
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), style: StrokeStyle(lineWidth: 6, lineCap: .round))
            Circle()
                .trim(from: 0, to: CGFloat(score ?? 0) / 100)
                .stroke(Wellness.color(for: score), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if let score {
                Text("\(score)")
                    .font(.system(size: size * 0.34, weight: .semibold, design: .rounded))
            } else {
                Image(systemName: "leaf.fill")
                    .font(.caption)
                    .foregroundStyle(CalmPalette.sage)
            }
        }
        .frame(width: size, height: size)
    }
}

struct PetStatusWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StatusEntry

    var body: some View {
        Group {
            if let snapshot = entry.snapshot {
                if family == .systemMedium {
                    medium(snapshot)
                } else {
                    small(snapshot)
                }
            } else {
                setupHint
            }
        }
        .containerBackground(for: .widget) {
            Color("WidgetBackground")
        }
    }

    private var setupHint: some View {
        VStack(spacing: 6) {
            Image(systemName: "pawprint.fill")
                .foregroundStyle(CalmPalette.sage)
            Text("Open Pet Monitor to add your pet")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func small(_ snapshot: WidgetSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: snapshot.species.symbolName)
                Text(snapshot.petName)
                    .lineLimit(1)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(CalmPalette.sage)
            Spacer(minLength: 0)
            HStack(spacing: 10) {
                MiniWellnessRing(score: snapshot.wellnessScore)
                VStack(alignment: .leading, spacing: 2) {
                    Text(Wellness.label(for: snapshot.wellnessScore))
                        .font(.caption2.weight(.medium))
                        .lineLimit(2)
                    Text("\(snapshot.streakDays)-day streak")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func medium(_ snapshot: WidgetSnapshot) -> some View {
        HStack(spacing: 16) {
            MiniWellnessRing(score: snapshot.wellnessScore, size: 62)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Image(systemName: snapshot.species.symbolName)
                    Text(snapshot.petName)
                        .lineLimit(1)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CalmPalette.sage)
                Text(Wellness.label(for: snapshot.wellnessScore))
                    .font(.footnote.weight(.medium))
                Text(snapshot.dueDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(snapshot.streakDays)-day check-in streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct PetStatusWidget: Widget {
    let kind: String = "PetStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StatusProvider()) { entry in
            PetStatusWidgetView(entry: entry)
        }
        .configurationDisplayName("Pet Status")
        .description("Wellness score, check-in streak, and when the next check-in is due.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
