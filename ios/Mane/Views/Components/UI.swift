import SwiftUI

// MARK: - Screen & card chrome

private struct ThemedScreen: ViewModifier {
    @EnvironmentObject private var theme: ThemeManager

    func body(content: Content) -> some View {
        ZStack {
            theme.palette.background.ignoresSafeArea()
            content
        }
    }
}

private struct CardStyle: ViewModifier {
    @EnvironmentObject private var theme: ThemeManager

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(theme.palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(
                color: theme.palette.colorScheme == .light ? Color.black.opacity(0.06) : .clear,
                radius: 10, x: 0, y: 4
            )
    }
}

extension View {
    func themedScreen() -> some View { modifier(ThemedScreen()) }
    func card() -> some View { modifier(CardStyle()) }
}

// MARK: - Section header

struct SectionHeader: View {
    @EnvironmentObject private var theme: ThemeManager
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(theme.palette.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(theme.palette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    let palette: Palette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                LinearGradient(
                    colors: [palette.accent, palette.accent.opacity(0.75)],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    let palette: Palette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(palette.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(palette.accent.opacity(0.12))
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

// MARK: - Selectable chip

struct Chip: View {
    @EnvironmentObject private var theme: ThemeManager
    let label: String
    var symbol: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.footnote)
                }
                Text(label)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? theme.palette.accent : theme.palette.surfaceSecondary)
            .foregroundStyle(isSelected ? Color.white : theme.palette.textPrimary)
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(
                    isSelected ? Color.clear : theme.palette.textSecondary.opacity(0.25),
                    lineWidth: 1
                )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Score ring

struct ScoreRing: View {
    @EnvironmentObject private var theme: ThemeManager
    let value: Double // 0–100
    let label: String
    var size: CGFloat = 96

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(theme.palette.surfaceSecondary, lineWidth: 9)
                Circle()
                    .trim(from: 0, to: max(0.02, min(1, value / 100)))
                    .stroke(
                        AngularGradient(
                            colors: [theme.palette.accent, theme.palette.accentSecondary],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 9, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Text("\(Int(value.rounded()))")
                    .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.palette.textPrimary)
            }
            .frame(width: size, height: size)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.palette.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Trend badge

struct TrendBadge: View {
    @EnvironmentObject private var theme: ThemeManager
    let trend: MetricTrend
    /// Contextual labels, e.g. ("Restoring", "Stable", "Receding").
    var labels: (up: String, flat: String, down: String) = ("Improving", "Stable", "Declining")

    private var color: Color {
        switch trend.direction {
        case .improving: return theme.palette.positive
        case .stable: return theme.palette.accentSecondary
        case .declining: return theme.palette.caution
        }
    }

    private var symbol: String {
        switch trend.direction {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }

    private var text: String {
        switch trend.direction {
        case .improving: return labels.up
        case .stable: return labels.flat
        case .declining: return labels.down
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
            Text(text)
            Text(String(format: "%+.1f%%", trend.deltaPercent))
                .opacity(0.8)
        }
        .font(.caption.weight(.bold))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.16))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}

// MARK: - Disclaimer

struct DisclaimerFooter: View {
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        Label {
            Text("MANE is a grooming companion, not a medical device. Hairline and density estimates are approximate and sensitive to lighting and angle. For medical concerns about hair loss, consult a dermatologist.")
        } icon: {
            Image(systemName: "info.circle")
        }
        .font(.caption2)
        .foregroundStyle(theme.palette.textSecondary)
    }
}

// MARK: - Flow layout for chips

struct FlowChips<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let content: (Data.Element) -> Content

    private var rows: [[Data.Element]] {
        // Simple fixed 2-column-ish wrapping using a grid keeps layout predictable.
        var result: [[Data.Element]] = []
        var current: [Data.Element] = []
        for element in data {
            current.append(element)
            if current.count == 2 {
                result.append(current)
                current = []
            }
        }
        if !current.isEmpty { result.append(current) }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { element in
                        content(element)
                    }
                }
            }
        }
    }
}
