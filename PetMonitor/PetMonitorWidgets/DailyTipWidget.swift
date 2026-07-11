import WidgetKit
import SwiftUI

struct TipEntry: TimelineEntry {
    let date: Date
    let petName: String
    let species: PetSpecies
    let tip: PetTip
}

struct TipProvider: TimelineProvider {

    private func entry(for date: Date) -> TipEntry {
        let snapshot = SharedStorage.loadSnapshot()
        let species = snapshot?.species ?? .dog
        return TipEntry(
            date: date,
            petName: snapshot?.petName ?? "your pet",
            species: species,
            tip: TipsLibrary.dailyTip(for: species, on: date)
        )
    }

    func placeholder(in context: Context) -> TipEntry {
        entry(for: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (TipEntry) -> Void) {
        completion(entry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TipEntry>) -> Void) {
        let calendar = Calendar.current
        var entries: [TipEntry] = [entry(for: Date())]
        let startOfToday = calendar.startOfDay(for: Date())
        for offset in 1..<7 {
            if let day = calendar.date(byAdding: .day, value: offset, to: startOfToday) {
                entries.append(entry(for: day))
            }
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct DailyTipWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TipEntry

    var body: some View {
        Group {
            if family == .systemMedium {
                medium
            } else {
                small
            }
        }
        .containerBackground(for: .widget) {
            Color("WidgetBackground")
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "leaf.fill")
                Text("Daily tip")
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(CalmPalette.sage)
            Text(entry.tip.text)
                .font(.caption)
                .lineLimit(6)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var medium: some View {
        HStack(spacing: 14) {
            VStack(spacing: 6) {
                Image(systemName: entry.species.symbolName)
                    .font(.title2)
                    .foregroundStyle(CalmPalette.sage)
                Text(entry.species.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 60)
            VStack(alignment: .leading, spacing: 5) {
                Text("Tip for \(entry.petName)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CalmPalette.sage)
                Text(entry.tip.text)
                    .font(.footnote)
                    .lineLimit(4)
                    .minimumScaleFactor(0.9)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct DailyTipWidget: Widget {
    let kind: String = "DailyTipWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TipProvider()) { entry in
            DailyTipWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Pet Tip")
        .description("A calm care tip for your pet, refreshed every day.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
