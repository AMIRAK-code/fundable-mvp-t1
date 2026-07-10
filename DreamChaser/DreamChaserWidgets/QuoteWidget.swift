import SwiftUI
import WidgetKit

/// Quote of the day on the Home and Lock Screen. Tries a fresh internet fetch
/// at timeline time, falling back to the bundled library offline.
struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: Quote

    static let preview = QuoteEntry(
        date: .now,
        quote: Quote(text: "Discipline is the bridge between goals and accomplishment.", author: "Jim Rohn")
    )
}

struct QuoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuoteEntry {
        .preview
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        if context.isPreview {
            completion(.preview)
        } else {
            completion(QuoteEntry(date: .now, quote: QuoteStore.shared.todaysQuote()))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        Task {
            let quote = await QuoteStore.shared.refreshFromInternet() ?? QuoteStore.shared.todaysQuote()
            let entry = QuoteEntry(date: .now, quote: quote)
            completion(Timeline(entries: [entry], policy: .after(Dates.startOfTomorrow)))
        }
    }
}

struct QuoteWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: QuoteEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.quote.text)
                        .font(.caption2)
                        .lineLimit(3)
                    Text("— \(entry.quote.author)")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            default:
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "quote.opening")
                        .font(family == .systemSmall ? .caption : .title3)
                        .foregroundStyle(.purple)
                    Text(entry.quote.text)
                        .font(family == .systemSmall ? .caption : .callout)
                        .fontDesign(.serif)
                        .italic()
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 0)
                    Text("— \(entry.quote.author)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color.indigo.opacity(0.3), Color.purple.opacity(0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

struct QuoteWidget: Widget {
    let kind = "QuoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteProvider()) { entry in
            QuoteWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Quote")
        .description("A fresh dose of discipline every morning.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular])
    }
}
