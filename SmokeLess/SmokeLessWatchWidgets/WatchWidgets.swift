import WidgetKit
import SwiftUI

@main
struct SmokeLessWatchWidgetsBundle: WidgetBundle {
    var body: some Widget {
        WatchStreakWidget()
        WatchSavingsWidget()
    }
}

/// Watch-face complication showing the streak.
struct WatchStreakWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SmokeLessWatchStreak", provider: SmokeLessProvider()) { entry in
            WatchStreakView(entry: entry)
        }
        .configurationDisplayName("Smoke-Free Streak")
        .description("Your current streak on the watch face.")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline])
    }
}

struct WatchStreakView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SmokeLessEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryCorner:
                Text("\(entry.streakDays)d")
                    .font(.headline)
                    .widgetLabel {
                        Text("Smoke-free")
                    }
            case .accessoryInline:
                Text("🔥 \(entry.streakDays)-day streak")
            default:
                Gauge(value: gaugeValue, in: 0...30) {
                    Image(systemName: "flame.fill")
                } currentValueLabel: {
                    Text("\(entry.streakDays)")
                }
                .gaugeStyle(.accessoryCircular)
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private var gaugeValue: Double {
        let inCycle = entry.streakDays % 30
        if entry.streakDays > 0 && inCycle == 0 {
            return 30
        }
        return Double(min(inCycle, 30))
    }
}

/// Watch-face complication showing money saved.
struct WatchSavingsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SmokeLessWatchSavings", provider: SmokeLessProvider()) { entry in
            WatchSavingsView(entry: entry)
        }
        .configurationDisplayName("Money Saved")
        .description("Savings from not smoking, at a glance.")
        .supportedFamilies([.accessoryRectangular, .accessoryCorner, .accessoryInline])
    }
}

struct WatchSavingsView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SmokeLessEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryCorner:
                Text(entry.moneySaved, format: .currency(code: entry.currencyCode).precision(.fractionLength(0)))
                    .font(.headline)
                    .minimumScaleFactor(0.6)
                    .widgetLabel {
                        Text("Saved")
                    }
            case .accessoryInline:
                Text("💰 \(entry.moneySaved.formatted(.currency(code: entry.currencyCode).precision(.fractionLength(0)))) saved")
            default:
                VStack(alignment: .leading, spacing: 2) {
                    Label {
                        Text(entry.moneySaved, format: .currency(code: entry.currencyCode).precision(.fractionLength(0)))
                    } icon: {
                        Image(systemName: "banknote.fill")
                    }
                    .font(.headline)
                    if let wishName = entry.wishName {
                        Text("\(entry.wishEmoji) \(wishName)")
                            .font(.caption2)
                            .lineLimit(1)
                        ProgressView(value: entry.wishProgress)
                    } else {
                        Text("\(Int(entry.unitsAvoided)) units avoided")
                            .font(.caption2)
                    }
                }
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}
