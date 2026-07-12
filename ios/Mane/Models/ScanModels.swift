import Foundation

// MARK: - Scan angles

enum ScanAngle: String, Codable, CaseIterable, Identifiable {
    case front
    case leftTemple
    case rightTemple
    case crown

    var id: String { rawValue }

    var order: Int {
        switch self {
        case .front: return 0
        case .leftTemple: return 1
        case .rightTemple: return 2
        case .crown: return 3
        }
    }

    var title: String {
        switch self {
        case .front: return "Front hairline"
        case .leftTemple: return "Left temple"
        case .rightTemple: return "Right temple"
        case .crown: return "Crown"
        }
    }

    var guidance: String {
        switch self {
        case .front:
            return "Face the camera straight on. Pull hair off your forehead, keep eyebrows visible, and use even, indirect light."
        case .leftTemple:
            return "Turn your head about 30° to the right so your left temple faces the camera. Keep the eyebrow in frame."
        case .rightTemple:
            return "Turn your head about 30° to the left so your right temple faces the camera. Keep the eyebrow in frame."
        case .crown:
            return "Hold the phone above and behind your head (or ask someone to help) and shoot straight down at the crown."
        }
    }

    var symbol: String {
        switch self {
        case .front: return "person.crop.square"
        case .leftTemple: return "person.crop.square.badge.camera"
        case .rightTemple: return "person.crop.square.badge.camera.fill"
        case .crown: return "circle.grid.cross.up.filled"
        }
    }

    /// The crown shot is recommended but optional (3 or 4 photos per scan).
    var isOptional: Bool { self == .crown }

    /// Whether this angle uses face detection to estimate the hairline.
    var usesFace: Bool { self != .crown }
}

// MARK: - Metrics

struct AngleMetrics: Codable, Identifiable, Hashable {
    let angle: ScanAngle
    /// Forehead height ÷ face height. Higher over time suggests recession.
    var hairlineRatio: Double?
    /// 0–100 estimate of hair coverage/texture in the analyzed region.
    var densityScore: Double?
    /// 0–1 confidence in this angle's measurements.
    var confidence: Double

    var id: String { angle.rawValue }

    var hairlineScore: Double? {
        hairlineRatio.map { max(0, min(100, (0.55 - $0) * 400)) }
    }
}

struct ScanSession: Codable, Identifiable, Hashable {
    let id: UUID
    let date: Date
    var metrics: [AngleMetrics]
    var notes: String = ""

    /// Weighted average ratio (front counts double).
    var hairlineRatio: Double? {
        let pairs: [(value: Double, weight: Double)] = metrics.compactMap { m in
            m.hairlineRatio.map { ($0, m.angle == .front ? 2.0 : 1.0) }
        }
        guard !pairs.isEmpty else { return nil }
        let totalWeight = pairs.reduce(0) { $0 + $1.weight }
        return pairs.reduce(0) { $0 + $1.value * $1.weight } / totalWeight
    }

    /// 0–100, higher = fuller-looking hairline (lower forehead ratio).
    var hairlineScore: Double? {
        hairlineRatio.map { max(0, min(100, (0.55 - $0) * 400)) }
    }

    /// Weighted average density (crown counts double).
    var densityScore: Double? {
        let pairs: [(value: Double, weight: Double)] = metrics.compactMap { m in
            m.densityScore.map { ($0, m.angle == .crown ? 2.0 : 1.0) }
        }
        guard !pairs.isEmpty else { return nil }
        let totalWeight = pairs.reduce(0) { $0 + $1.weight }
        return pairs.reduce(0) { $0 + $1.value * $1.weight } / totalWeight
    }

    var confidence: Double {
        guard !metrics.isEmpty else { return 0 }
        return metrics.map(\.confidence).reduce(0, +) / Double(metrics.count)
    }
}

// MARK: - Trends

enum TrendDirection: String, Codable {
    case improving, stable, declining
}

struct MetricTrend: Hashable {
    let direction: TrendDirection
    /// Percent change of the latest session vs the baseline (avg of up to 3 prior sessions).
    let deltaPercent: Double
    let message: String
}

struct ScanTrends {
    let hairline: MetricTrend?
    let density: MetricTrend?

    /// Needs at least two sessions. Compares the latest against the average of
    /// up to three preceding sessions to smooth out lighting/angle noise.
    static func compute(sessions: [ScanSession]) -> ScanTrends? {
        let sorted = sessions.sorted { $0.date < $1.date }
        guard sorted.count >= 2, let latest = sorted.last else { return nil }
        let baseline = Array(sorted.dropLast().suffix(3))

        let hairline = trend(
            latest: latest.hairlineScore,
            baseline: baseline.compactMap(\.hairlineScore),
            threshold: 4,
            improving: "Hairline index is up vs your baseline — front coverage reads slightly fuller. Keep the routine going.",
            stable: "No meaningful hairline movement. Stability is the goal — that's a win.",
            declining: "Hairline index slipped vs your baseline. Re-scan in 2–4 weeks under the same light; if the slide continues, talk to a dermatologist."
        )
        let density = trend(
            latest: latest.densityScore,
            baseline: baseline.compactMap(\.densityScore),
            threshold: 6,
            improving: "Density index is trending up — coverage and texture read fuller than your baseline.",
            stable: "Density looks steady vs your baseline scans.",
            declining: "Density index dipped vs your baseline. Check lighting first; if it persists across scans, consider a professional check-up."
        )
        if hairline == nil && density == nil { return nil }
        return ScanTrends(hairline: hairline, density: density)
    }

    private static func trend(
        latest: Double?,
        baseline: [Double],
        threshold: Double,
        improving: String,
        stable: String,
        declining: String
    ) -> MetricTrend? {
        guard let latest, !baseline.isEmpty else { return nil }
        let base = baseline.reduce(0, +) / Double(baseline.count)
        let delta = (latest - base) / max(base, 1) * 100
        let direction: TrendDirection
        let message: String
        if delta > threshold {
            direction = .improving; message = improving
        } else if delta < -threshold {
            direction = .declining; message = declining
        } else {
            direction = .stable; message = stable
        }
        return MetricTrend(direction: direction, deltaPercent: delta, message: message)
    }
}
