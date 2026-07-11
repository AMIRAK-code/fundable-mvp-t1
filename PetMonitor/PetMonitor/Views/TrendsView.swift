import SwiftUI
import Charts

enum TrendMetric: String, CaseIterable, Identifiable {
    case mood = "Mood"
    case energy = "Energy"
    case appetite = "Appetite"
    case weight = "Weight"

    var id: String { rawValue }
}

struct TrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct TrendsView: View {
    @EnvironmentObject private var store: PetStore
    @State private var metric: TrendMetric = .mood

    var body: some View {
        NavigationStack {
            ZStack {
                CalmBackground()
                if let pet = store.selectedPet {
                    ScrollView {
                        VStack(spacing: 14) {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 14) {
                                    Picker("Metric", selection: $metric) {
                                        ForEach(TrendMetric.allCases) { m in
                                            Text(m.rawValue).tag(m)
                                        }
                                    }
                                    .pickerStyle(.segmented)

                                    let points = points(for: pet)
                                    if points.count < 2 {
                                        VStack(spacing: 8) {
                                            Image(systemName: "chart.xyaxis.line")
                                                .font(.system(size: 30))
                                                .foregroundStyle(CalmPalette.sage)
                                            Text("A couple more check-ins and a trend line will appear here.")
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                                .multilineTextAlignment(.center)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 40)
                                    } else {
                                        chart(points: points)
                                    }
                                }
                            }
                            summaryCard(for: pet)
                            GlassCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Why trends matter", systemImage: "lightbulb")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(CalmPalette.lavender)
                                    Text("Pets rarely announce that something is wrong. A slow slide in appetite or energy over a week is often the first honest signal — and it only shows up when you log gently and regularly.")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Trends")
        }
    }

    // MARK: - Data

    private func points(for pet: Pet) -> [TrendPoint] {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recent = store.entries(for: pet).filter { $0.date >= cutoff }

        if metric == .weight {
            return recent
                .compactMap { entry in
                    entry.weightKilograms.map { TrendPoint(date: entry.date, value: $0) }
                }
                .sorted { $0.date < $1.date }
        }

        let grouped = Dictionary(grouping: recent) { calendar.startOfDay(for: $0.date) }
        return grouped
            .map { day, dayEntries in
                let total = dayEntries.reduce(0) { $0 + ratingValue(of: $1) }
                return TrendPoint(date: day, value: Double(total) / Double(dayEntries.count))
            }
            .sorted { $0.date < $1.date }
    }

    private func ratingValue(of entry: LogEntry) -> Int {
        switch metric {
        case .mood: return entry.mood
        case .energy: return entry.energy
        case .appetite: return entry.appetite
        case .weight: return 0
        }
    }

    // MARK: - Chart

    @ViewBuilder
    private func chart(points: [TrendPoint]) -> some View {
        let base = Chart(points) { point in
            LineMark(
                x: .value("Day", point.date, unit: .day),
                y: .value(metric.rawValue, point.value)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(CalmPalette.sage)

            PointMark(
                x: .value("Day", point.date, unit: .day),
                y: .value(metric.rawValue, point.value)
            )
            .foregroundStyle(CalmPalette.sage.opacity(0.85))
        }
        .frame(height: 220)

        if metric == .weight {
            base
        } else {
            base.chartYScale(domain: 0.0...5.0)
        }
    }

    // MARK: - Summary

    private func summaryCard(for pet: Pet) -> some View {
        let cutoff = Date().addingTimeInterval(-7 * 86_400)
        let week = store.entries(for: pet).filter { $0.date > cutoff }
        let count = week.count
        let avgMood = average(week.map { $0.mood })
        let avgEnergy = average(week.map { $0.energy })
        let avgAppetite = average(week.map { $0.appetite })
        let latestWeight = store.entries(for: pet).compactMap { $0.weightKilograms }.first

        return GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Last 7 days", systemImage: "calendar")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CalmPalette.mist)
                summaryRow("Check-ins", count == 0 ? "—" : "\(count)")
                summaryRow("Average mood", formatted(avgMood))
                summaryRow("Average energy", formatted(avgEnergy))
                summaryRow("Average appetite", formatted(avgAppetite))
                summaryRow("Latest weight", latestWeight.map { String(format: "%.1f kg", $0) } ?? "—")
            }
        }
    }

    private func summaryRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }

    private func average(_ values: [Int]) -> Double? {
        guard !values.isEmpty else { return nil }
        return Double(values.reduce(0, +)) / Double(values.count)
    }

    private func formatted(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.1f / 5", value)
    }
}
