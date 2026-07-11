import SwiftUI

/// Guided 4-7-8 breathing: inhale 4s, hold 7s, exhale 8s.
/// The circle grows on the inhale, holds, then shrinks on the exhale.
struct BreathingView: View {
    let theme: AppTheme

    @State private var elapsed: Double = 0
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    private let inhale: Double = 4
    private let hold: Double = 7
    private let exhale: Double = 8
    private var cycle: Double { inhale + hold + exhale }

    private var phaseInfo: (label: String, scale: Double, remaining: Int) {
        let t = elapsed.truncatingRemainder(dividingBy: cycle)
        if t < inhale {
            let p = t / inhale
            return ("Breathe in", 0.55 + 0.45 * p, Int(inhale - t) + 1)
        } else if t < inhale + hold {
            return ("Hold", 1.0, Int(inhale + hold - t) + 1)
        } else {
            let p = (t - inhale - hold) / exhale
            return ("Breathe out", 1.0 - 0.45 * p, Int(cycle - t) + 1)
        }
    }

    var body: some View {
        let info = phaseInfo
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.15))
                Circle()
                    .fill(theme.gradient)
                    .scaleEffect(info.scale)
                    .animation(.linear(duration: 0.05), value: info.scale)
                VStack(spacing: 4) {
                    Text(info.label)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("\(info.remaining)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 220, height: 220)

            Text("4-7-8 breathing calms your nervous system while the craving fades.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .onReceive(timer) { _ in
            elapsed += 0.05
        }
    }
}
