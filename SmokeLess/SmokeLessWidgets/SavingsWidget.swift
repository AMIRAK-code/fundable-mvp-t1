import WidgetKit
import SwiftUI

/// Widget tracking money saved and progress toward the next wishlist item.
/// Tapping it opens the wishlist.
struct SavingsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SmokeLessSavings", provider: SmokeLessProvider()) { entry in
            SavingsWidgetView(entry: entry)
        }
        .configurationDisplayName("Money Saved")
        .description("Watch your savings grow toward your next wishlist item.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

struct SavingsWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SmokeLessEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular:
                rectangular
            case .systemMedium:
                medium
            default:
                small
            }
        }
        .containerBackground(for: .widget) {
            if family == .accessoryRectangular {
                Color.clear
            } else {
                entry.theme.gradient
            }
        }
        .widgetURL(URL(string: "smokeless://wishlist"))
    }

    private var small: some View {
        VStack(spacing: 4) {
            Image(systemName: "banknote.fill")
                .font(.title3)
                .foregroundStyle(entry.theme.accent)
            Text(entry.moneySaved, format: .currency(code: entry.currencyCode).precision(.fractionLength(0)))
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .foregroundStyle(.white)
            Text("saved so far")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, 4)
    }

    private var medium: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Money saved")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                Text(entry.moneySaved, format: .currency(code: entry.currencyCode).precision(.fractionLength(0)))
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .foregroundStyle(.white)
                Text("\(Int(entry.unitsAvoided)) units avoided")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            if let wishName = entry.wishName {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(entry.wishEmoji) \(wishName)")
                        .font(.caption.bold())
                        .lineLimit(1)
                        .foregroundStyle(.white)
                    ProgressView(value: entry.wishProgress)
                        .tint(entry.theme.accent)
                    Text("\(Int(entry.wishProgress * 100))% funded")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .frame(maxWidth: 140)
            }
        }
        .padding(.horizontal, 4)
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label {
                Text(entry.moneySaved, format: .currency(code: entry.currencyCode).precision(.fractionLength(0)))
            } icon: {
                Image(systemName: "banknote.fill")
            }
            .font(.headline)
            if let wishName = entry.wishName {
                Text("\(entry.wishEmoji) \(wishName): \(Int(entry.wishProgress * 100))%")
                    .font(.caption)
                ProgressView(value: entry.wishProgress)
            } else {
                Text("saved by not smoking")
                    .font(.caption)
            }
        }
    }
}
