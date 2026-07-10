import ActivityKit
import SwiftUI
import WidgetKit

/// Live Activity for a running focus session — Lock Screen banner plus
/// Dynamic Island presentations with a live countdown.
struct FocusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            // Lock Screen / banner
            HStack(spacing: 14) {
                Image(systemName: context.attributes.symbol)
                    .font(.title2)
                    .foregroundStyle(ThemeColor.color(for: context.attributes.colorName))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Focus · \(context.attributes.sectionName)")
                        .font(.headline)
                    Text("Stay locked in.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(timerInterval: context.state.startDate...context.state.endDate, countsDown: true)
                    .font(.system(.title3, design: .rounded).bold())
                    .monospacedDigit()
                    .frame(width: 80, alignment: .trailing)
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.5))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.attributes.symbol)
                        .font(.title2)
                        .foregroundStyle(ThemeColor.color(for: context.attributes.colorName))
                        .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.sectionName)
                        .font(.headline)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.state.startDate...context.state.endDate, countsDown: true)
                        .font(.system(.headline, design: .rounded))
                        .monospacedDigit()
                        .frame(width: 70, alignment: .trailing)
                        .padding(.trailing, 6)
                }
            } compactLeading: {
                Image(systemName: context.attributes.symbol)
                    .foregroundStyle(ThemeColor.color(for: context.attributes.colorName))
            } compactTrailing: {
                Text(timerInterval: context.state.startDate...context.state.endDate, countsDown: true)
                    .monospacedDigit()
                    .frame(width: 46)
            } minimal: {
                Image(systemName: context.attributes.symbol)
                    .foregroundStyle(ThemeColor.color(for: context.attributes.colorName))
            }
        }
    }
}
