import SwiftUI

/// Animated progress ring showing the current streak. The ring fills over
/// each 30-day cycle so long streaks keep a sense of motion.
struct StreakRing: View {
    let days: Int
    let hours: Int
    let theme: AppTheme

    private var cycleProgress: Double {
        let inCycle = days % 30
        return days > 0 && inCycle == 0 ? 1 : Double(inCycle) / 30
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.25), lineWidth: 14)
            Circle()
                .trim(from: 0, to: cycleProgress)
                .stroke(theme.accent, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: cycleProgress)
            VStack(spacing: 2) {
                Image(systemName: "flame.fill")
                    .font(.title3)
                    .foregroundStyle(theme.accent)
                if days == 0 {
                    Text("\(hours)")
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text(hours == 1 ? "hour" : "hours")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                } else {
                    Text("\(days)")
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text(days == 1 ? "day streak" : "days streak")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .frame(width: 160, height: 160)
    }
}
