import SwiftUI

/// Daily dashboard: greeting, streak, AM/PM checklist, tip of the day and a
/// nudge toward the scanner.
struct TodayView: View {
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var model: AppModel

    @State private var expandedStepID: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    heroCard
                    checklist(for: .morning)
                    checklist(for: .evening)
                    tipCard
                    scanNudge
                    DisclaimerFooter()
                }
                .padding(20)
            }
            .themedScreen()
            .navigationTitle("Today")
            .toolbarBackground(theme.palette.background, for: .navigationBar)
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        let fraction = model.completionFraction()
        return ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(theme.palette.hero)
            HStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(greeting)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                    if let routine = model.routine {
                        Text(routine.headline)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(model.streak)-day streak")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 4)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.25), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: max(0.02, fraction))
                        .stroke(.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int((fraction * 100).rounded()))%")
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .foregroundStyle(.white)
                }
                .frame(width: 74, height: 74)
            }
            .padding(20)
        }
        .animation(.easeInOut, value: fraction)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = model.profile?.displayName ?? "there"
        switch hour {
        case 5..<12: return "Morning, \(name)"
        case 12..<18: return "Afternoon, \(name)"
        default: return "Evening, \(name)"
        }
    }

    // MARK: - Checklist

    @ViewBuilder
    private func checklist(for time: TimeOfDay) -> some View {
        if let routine = model.routine {
            let steps = routine.steps(for: Date(), at: time)
            if !steps.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Label(time == .morning ? "Morning" : "Evening", systemImage: time.symbol)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(theme.palette.textPrimary)
                    VStack(spacing: 4) {
                        ForEach(steps) { step in
                            stepRow(step)
                        }
                    }
                }
                .card()
            }
        }
    }

    private func stepRow(_ step: RoutineStep) -> some View {
        let done = model.isDone(step)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Button {
                    withAnimation(.snappy) { model.toggle(step) }
                } label: {
                    Image(systemName: done ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(done ? theme.palette.positive : theme.palette.textSecondary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(step.title)
                            .font(.subheadline.weight(.semibold))
                            .strikethrough(done)
                            .foregroundStyle(done ? theme.palette.textSecondary : theme.palette.textPrimary)
                        Text(step.frequencyLabel)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(theme.palette.surfaceSecondary)
                            .foregroundStyle(theme.palette.textSecondary)
                            .clipShape(Capsule())
                    }
                    Text(step.detail)
                        .font(.caption)
                        .foregroundStyle(theme.palette.textSecondary)
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut) {
                        expandedStepID = expandedStepID == step.id ? nil : step.id
                    }
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.footnote)
                        .foregroundStyle(theme.palette.accentSecondary)
                }
                .buttonStyle(.plain)
            }

            if expandedStepID == step.id {
                Text(step.why)
                    .font(.caption)
                    .foregroundStyle(theme.palette.textPrimary)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.palette.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Tip of the day

    @ViewBuilder
    private var tipCard: some View {
        if let tip = model.tipOfTheDay() {
            VStack(alignment: .leading, spacing: 8) {
                Label("Tip of the day", systemImage: "lightbulb.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.palette.accent)
                Text(tip.title)
                    .font(.headline)
                    .foregroundStyle(theme.palette.textPrimary)
                Text(tip.body)
                    .font(.subheadline)
                    .foregroundStyle(theme.palette.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()
        }
    }

    // MARK: - Scan nudge

    @ViewBuilder
    private var scanNudge: some View {
        let lastScan = model.latestSession?.date
        let daysSince = lastScan.map { Calendar.current.dateComponents([.day], from: $0, to: Date()).day ?? 0 }
        if lastScan == nil || (daysSince ?? 0) >= 21 {
            HStack(spacing: 14) {
                Image(systemName: "camera.metering.center.weighted")
                    .font(.title2)
                    .foregroundStyle(theme.palette.accent)
                VStack(alignment: .leading, spacing: 3) {
                    Text(lastScan == nil ? "Baseline scan" : "Time for a re-scan")
                        .font(.headline)
                        .foregroundStyle(theme.palette.textPrimary)
                    Text(lastScan == nil
                         ? "Take your first hairline scan so future changes have something to compare against."
                         : "It's been \(daysSince ?? 0) days — scan again to keep your trend line honest.")
                        .font(.caption)
                        .foregroundStyle(theme.palette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(theme.palette.textSecondary)
            }
            .card()
        }
    }
}
