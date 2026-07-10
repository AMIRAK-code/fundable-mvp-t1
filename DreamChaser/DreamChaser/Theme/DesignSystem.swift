import SwiftUI

// MARK: - Background

/// Soft aurora gradient behind every screen — Liquid Glass needs something
/// colorful underneath to refract, so content never sits on flat gray.
struct AppBackground: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
            LinearGradient(
                colors: [.purple.opacity(0.25), .indigo.opacity(0.18), .clear],
                startPoint: .topLeading,
                endPoint: .center
            )
            LinearGradient(
                colors: [.clear, .teal.opacity(0.12)],
                startPoint: .center,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Progress ring

struct ProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 8
    var tint: Color = .accentColor

    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(
                    AngularGradient(
                        colors: [tint.opacity(0.6), tint],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.5), value: progress)
        }
    }
}

// MARK: - Stat tile

struct StatTile: View {
    let title: String
    let value: String
    var unit: String? = nil
    let symbol: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(.title2, design: .rounded).bold())
                    .contentTransition(.numericText())
                if let unit {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular.tint(color.opacity(0.18)), in: .rect(cornerRadius: 22))
    }
}

// MARK: - Glass card helper

extension View {
    /// Standard Liquid Glass card treatment used across the app.
    func glassCard(cornerRadius: CGFloat = 28, tint: Color? = nil) -> some View {
        padding(20)
            .glassEffect(
                tint.map { Glass.regular.tint($0.opacity(0.2)) } ?? .regular,
                in: .rect(cornerRadius: cornerRadius)
            )
    }
}
