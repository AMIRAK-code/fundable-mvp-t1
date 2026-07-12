import SwiftUI
import Charts

/// Scanner hub: latest scores, trend verdicts, history chart and past sessions.
struct ScanHomeView: View {
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var model: AppModel

    @State private var showScanFlow = false
    @State private var chartMetric: ChartMetric = .hairline

    enum ChartMetric: String, CaseIterable, Identifiable {
        case hairline = "Hairline"
        case density = "Density"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if model.sessions.isEmpty {
                        emptyState
                    } else {
                        latestScores
                        trendCards
                        historyChart
                        historyList
                    }
                    DisclaimerFooter()
                }
                .padding(20)
            }
            .themedScreen()
            .navigationTitle("Hairline Scan")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showScanFlow = true
                    } label: {
                        Label("New Scan", systemImage: "plus.circle.fill")
                            .font(.headline)
                    }
                }
            }
            .fullScreenCover(isPresented: $showScanFlow) {
                ScanFlowView()
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(theme.palette.hero)
                    .frame(height: 170)
                VStack(spacing: 8) {
                    Image(systemName: "camera.metering.center.weighted")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                    Text("Track your hairline with photos")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: .leading, spacing: 14) {
                explainerRow(number: "1", text: "Take 3–4 photos: front hairline, both temples, and optionally the crown.")
                explainerRow(number: "2", text: "On-device algorithms estimate your forehead-to-face ratio and hair density.")
                explainerRow(number: "3", text: "Repeat every few weeks — MANE compares sessions and tells you if things are receding, stable or restoring.")
            }
            .card()

            Button {
                showScanFlow = true
            } label: {
                Label("Take baseline scan", systemImage: "camera.fill")
            }
            .buttonStyle(PrimaryButtonStyle(palette: theme.palette))

            Text("Tip: same mirror, same light, same distance — every time. Consistency is what makes the trend meaningful.")
                .font(.caption)
                .foregroundStyle(theme.palette.textSecondary)
        }
    }

    private func explainerRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(.subheadline, design: .rounded).weight(.black))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(theme.palette.accent))
            Text(text)
                .font(.subheadline)
                .foregroundStyle(theme.palette.textSecondary)
        }
    }

    // MARK: - Latest scores

    @ViewBuilder
    private var latestScores: some View {
        if let latest = model.latestSession {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(
                    title: "Latest scan",
                    subtitle: latest.date.formatted(date: .abbreviated, time: .shortened)
                )
                HStack(spacing: 24) {
                    Spacer()
                    if let hairline = latest.hairlineScore {
                        ScoreRing(value: hairline, label: "Hairline index")
                    }
                    if let density = latest.densityScore {
                        ScoreRing(value: density, label: "Density index")
                    }
                    Spacer()
                }
                Text("Confidence \(Int((latest.confidence * 100).rounded()))% · higher is better on both indexes")
                    .font(.caption)
                    .foregroundStyle(theme.palette.textSecondary)
            }
            .card()
        }
    }

    // MARK: - Trends

    @ViewBuilder
    private var trendCards: some View {
        if let trends = model.trends {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Trend vs baseline")
                if let hairline = trends.hairline {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Hairline")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(theme.palette.textPrimary)
                            Spacer()
                            TrendBadge(trend: hairline, labels: ("Restoring", "Stable", "Receding"))
                        }
                        Text(hairline.message)
                            .font(.caption)
                            .foregroundStyle(theme.palette.textSecondary)
                    }
                    .card()
                }
                if let density = trends.density {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Density")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(theme.palette.textPrimary)
                            Spacer()
                            TrendBadge(trend: density, labels: ("Improving", "Stable", "Thinning"))
                        }
                        Text(density.message)
                            .font(.caption)
                            .foregroundStyle(theme.palette.textSecondary)
                    }
                    .card()
                }
            }
        } else if model.sessions.count == 1 {
            Text("One more scan and you'll get trend verdicts — re-scan in 2–4 weeks.")
                .font(.subheadline)
                .foregroundStyle(theme.palette.textSecondary)
                .card()
        }
    }

    // MARK: - Chart

    @ViewBuilder
    private var historyChart: some View {
        if model.sessions.count >= 2 {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "History")
                Picker("Metric", selection: $chartMetric) {
                    ForEach(ChartMetric.allCases) { metric in
                        Text(metric.rawValue).tag(metric)
                    }
                }
                .pickerStyle(.segmented)

                Chart(chartPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.value)
                    )
                    .foregroundStyle(theme.palette.accent)
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.value)
                    )
                    .foregroundStyle(theme.palette.accentSecondary)
                }
                .chartYScale(domain: 0...100)
                .frame(height: 200)
            }
            .card()
        }
    }

    private struct ChartPoint: Identifiable {
        let date: Date
        let value: Double
        var id: Date { date }
    }

    private var chartPoints: [ChartPoint] {
        model.sessions.compactMap { session in
            let value = chartMetric == .hairline ? session.hairlineScore : session.densityScore
            return value.map { ChartPoint(date: session.date, value: $0) }
        }
    }

    // MARK: - History list

    private var historyList: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "All scans")
            VStack(spacing: 10) {
                ForEach(model.sessions.reversed()) { session in
                    NavigationLink {
                        ScanDetailView(session: session)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "person.crop.square.badge.camera")
                                .font(.title3)
                                .foregroundStyle(theme.palette.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(theme.palette.textPrimary)
                                Text(summaryLine(for: session))
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
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            model.deleteSession(session)
                        } label: {
                            Label("Delete scan", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private func summaryLine(for session: ScanSession) -> String {
        var parts: [String] = []
        if let hairline = session.hairlineScore {
            parts.append("Hairline \(Int(hairline.rounded()))")
        }
        if let density = session.densityScore {
            parts.append("Density \(Int(density.rounded()))")
        }
        parts.append("\(session.metrics.count) photos")
        return parts.joined(separator: " · ")
    }
}
