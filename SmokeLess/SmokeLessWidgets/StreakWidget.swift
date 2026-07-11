import WidgetKit
import SwiftUI

/// Home-screen and lock-screen widget showing the current smoke-free streak.
/// Tapping it deep-links straight into Craving SOS.
struct StreakWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SmokeLessStreak", provider: SmokeLessProvider()) { entry in
            StreakWidgetView(entry: entry)
        }
        .configurationDisplayName("Smoke-Free Streak")
        .description("Your streak, avoided units and a one-tap craving SOS.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct StreakWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SmokeLessEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                circular
            case .accessoryRectangular:
                rectangular
            case .accessoryInline:
                Text("🔥 \(entry.streakDays)-day streak")
            default:
                small
            }
        }
        .containerBackground(for: .widget) {
            if family == .systemSmall {
                entry.theme.gradient
            } else {
                Color.clear
            }
        }
        .widgetURL(URL(string: "smokeless://sos"))
    }

    private var small: some View {
        VStack(spacing: 4) {
            if entry.onboarded {
                Image(systemName: "flame.fill")
                    .font(.title3)
                    .foregroundStyle(entry.theme.accent)
                Text("\(entry.streakDays)")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(entry.streakDays == 1 ? "day smoke-free" : "days smoke-free")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.85))
                Text("Craving? Tap me")
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.7))
            } else {
                Image(systemName: "wind")
                    .font(.title2)
                    .foregroundStyle(.white)
                Text("Open SmokeLess to get started")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
            }
        }
    }

    private var circular: some View {
        Gauge(value: Double(min(entry.streakDays % 30 == 0 && entry.streakDays > 0 ? 30 : entry.streakDays % 30, 30)), in: 0...30) {
            Image(systemName: "flame.fill")
        } currentValueLabel: {
            Text("\(entry.streakDays)")
        }
        .gaugeStyle(.accessoryCircular)
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("\(entry.streakDays)-day streak", systemImage: "flame.fill")
                .font(.headline)
            Text("\(Int(entry.unitsAvoided)) units avoided")
                .font(.caption)
            Text(entry.moneySaved, format: .currency(code: entry.currencyCode))
                .font(.caption2)
        }
    }
}
