import SwiftUI
import PhotosUI
import UIKit

/// Guided capture flow: front → left temple → right temple → crown (optional),
/// then on-device analysis and a results screen with comparison to the
/// previous session.
struct ScanFlowView: View {
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    @StateObject private var flow = ScanFlowViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch flow.phase {
                case .capture:
                    captureView
                case .analyzing:
                    analyzingView
                case .results:
                    if let session = flow.result {
                        ScanResultView(
                            session: session,
                            previous: model.latestSession,
                            onSave: {
                                model.addSession(session, images: flow.images)
                                dismiss()
                            },
                            onDiscard: { dismiss() }
                        )
                    }
                }
            }
            .themedScreen()
            .navigationTitle("New Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(flow.phase == .analyzing)
                }
            }
        }
    }

    // MARK: - Capture

    private var captureView: some View {
        let angle = flow.currentAngle
        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(flow.angles) { a in
                        Capsule()
                            .fill(dotColor(for: a))
                            .frame(height: 6)
                    }
                }

                SectionHeader(
                    title: "\(flow.currentIndex + 1). \(angle.title)",
                    subtitle: angle.isOptional ? "Recommended, but you can skip it" : nil
                )

                // Guide card
                VStack(spacing: 16) {
                    if let image = flow.images[angle] {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 300)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(theme.palette.surfaceSecondary)
                                .frame(height: 300)
                            VStack(spacing: 12) {
                                Image(systemName: angle.symbol)
                                    .font(.system(size: 52))
                                    .foregroundStyle(theme.palette.accent)
                                Text(angle.guidance)
                                    .font(.subheadline)
                                    .foregroundStyle(theme.palette.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }
                        }
                    }
                }
                .card()

                // Capture buttons
                VStack(spacing: 10) {
                    if CameraPicker.isAvailable {
                        Button {
                            flow.showCamera = true
                        } label: {
                            Label(flow.images[angle] == nil ? "Take photo" : "Retake photo", systemImage: "camera.fill")
                        }
                        .buttonStyle(PrimaryButtonStyle(palette: theme.palette))
                    }

                    PhotosPicker(selection: $flow.pickerItem, matching: .images) {
                        Label("Choose from library", systemImage: "photo.on.rectangle")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(theme.palette.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(theme.palette.accent.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                // Navigation buttons
                HStack(spacing: 10) {
                    if flow.currentIndex > 0 {
                        Button("Back") { flow.goBack() }
                            .buttonStyle(SecondaryButtonStyle(palette: theme.palette))
                    }
                    if flow.images[angle] != nil {
                        Button(flow.isLastAngle ? "Analyze" : "Next") { flow.advanceOrAnalyze() }
                            .buttonStyle(PrimaryButtonStyle(palette: theme.palette))
                    } else if angle.isOptional {
                        Button("Skip & analyze") { flow.analyze() }
                            .buttonStyle(SecondaryButtonStyle(palette: theme.palette))
                    }
                }

                Text("Photos are analyzed and stored on this device only.")
                    .font(.caption2)
                    .foregroundStyle(theme.palette.textSecondary)
            }
            .padding(20)
        }
        .fullScreenCover(isPresented: $flow.showCamera) {
            CameraPicker { image in
                flow.setImage(image)
            }
            .ignoresSafeArea()
        }
        .onChange(of: flow.pickerItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    flow.setImage(image)
                }
                flow.pickerItem = nil
            }
        }
    }

    private func dotColor(for angle: ScanAngle) -> Color {
        if flow.images[angle] != nil { return theme.palette.positive }
        if angle == flow.currentAngle { return theme.palette.accent }
        return theme.palette.surfaceSecondary
    }

    // MARK: - Analyzing

    private var analyzingView: some View {
        VStack(spacing: 22) {
            Spacer()
            ProgressView()
                .controlSize(.large)
                .tint(theme.palette.accent)
            Text(flow.progressText)
                .font(.headline)
                .foregroundStyle(theme.palette.textPrimary)
            Text("Face landmarks → hairline transition → density mapping.\nAll on device.")
                .font(.caption)
                .foregroundStyle(theme.palette.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(24)
    }
}

// MARK: - View model

@MainActor
final class ScanFlowViewModel: ObservableObject {
    enum Phase { case capture, analyzing, results }

    let angles: [ScanAngle] = [.front, .leftTemple, .rightTemple, .crown]

    @Published var phase: Phase = .capture
    @Published var currentIndex = 0
    @Published var images: [ScanAngle: UIImage] = [:]
    @Published var pickerItem: PhotosPickerItem?
    @Published var showCamera = false
    @Published var progressText = "Analyzing…"
    @Published var result: ScanSession?

    var currentAngle: ScanAngle { angles[currentIndex] }
    var isLastAngle: Bool { currentIndex == angles.count - 1 }

    func setImage(_ image: UIImage) {
        images[currentAngle] = image
    }

    func goBack() {
        if currentIndex > 0 { currentIndex -= 1 }
    }

    func advanceOrAnalyze() {
        if isLastAngle {
            analyze()
        } else {
            currentIndex += 1
        }
    }

    func analyze() {
        guard !images.isEmpty else { return }
        phase = .analyzing
        Task {
            var metrics: [AngleMetrics] = []
            let ordered = images.sorted { $0.key.order < $1.key.order }
            for (angle, image) in ordered {
                progressText = "Analyzing \(angle.title.lowercased())…"
                let metric = await HairlineAnalyzer.analyze(image: image, angle: angle)
                metrics.append(metric)
            }
            result = ScanSession(id: UUID(), date: Date(), metrics: metrics)
            phase = .results
        }
    }
}

// MARK: - Results

struct ScanResultView: View {
    @EnvironmentObject private var theme: ThemeManager
    let session: ScanSession
    let previous: ScanSession?
    let onSave: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(title: "Scan results", subtitle: "Estimates, not diagnoses — trends across scans are what count.")

                HStack(spacing: 24) {
                    Spacer()
                    if let hairline = session.hairlineScore {
                        ScoreRing(value: hairline, label: "Hairline index")
                    }
                    if let density = session.densityScore {
                        ScoreRing(value: density, label: "Density index")
                    }
                    Spacer()
                }
                .card()

                if let previous {
                    comparisonCard(previous: previous)
                }

                perAngleBreakdown

                if session.confidence < 0.45 {
                    Label {
                        Text("Low confidence — the face or hairline was hard to detect. Try again with even light, hair pulled back and the camera at eye level.")
                            .font(.caption)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                    }
                    .foregroundStyle(theme.palette.caution)
                    .card()
                }

                VStack(spacing: 10) {
                    Button("Save scan") { onSave() }
                        .buttonStyle(PrimaryButtonStyle(palette: theme.palette))
                    Button("Discard") { onDiscard() }
                        .buttonStyle(SecondaryButtonStyle(palette: theme.palette))
                }

                DisclaimerFooter()
            }
            .padding(20)
        }
    }

    private func comparisonCard(previous: ScanSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("vs \(previous.date.formatted(date: .abbreviated, time: .omitted))")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(theme.palette.textPrimary)
            if let now = session.hairlineScore, let then = previous.hairlineScore {
                deltaRow(label: "Hairline index", now: now, then: then,
                         up: "Restoring", flat: "Stable", down: "Receding")
            }
            if let now = session.densityScore, let then = previous.densityScore {
                deltaRow(label: "Density index", now: now, then: then,
                         up: "Improving", flat: "Stable", down: "Thinning")
            }
        }
        .card()
    }

    private func deltaRow(label: String, now: Double, then: Double, up: String, flat: String, down: String) -> some View {
        let delta = (now - then) / max(then, 1) * 100
        let direction: TrendDirection = delta > 4 ? .improving : (delta < -4 ? .declining : .stable)
        let trend = MetricTrend(direction: direction, deltaPercent: delta, message: "")
        return HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(theme.palette.textSecondary)
            Spacer()
            TrendBadge(trend: trend, labels: (up, flat, down))
        }
    }

    private var perAngleBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Per-angle detail")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(theme.palette.textPrimary)
            ForEach(session.metrics.sorted { $0.angle.order < $1.angle.order }) { metric in
                HStack {
                    Label(metric.angle.title, systemImage: metric.angle.symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.palette.textPrimary)
                    Spacer()
                    if let score = metric.hairlineScore {
                        Text("HL \(Int(score.rounded()))")
                            .font(.caption)
                            .foregroundStyle(theme.palette.textSecondary)
                    }
                    if let density = metric.densityScore {
                        Text("DN \(Int(density.rounded()))")
                            .font(.caption)
                            .foregroundStyle(theme.palette.textSecondary)
                    }
                    Text("\(Int((metric.confidence * 100).rounded()))%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(metric.confidence >= 0.5 ? theme.palette.positive : theme.palette.caution)
                }
                .padding(.vertical, 2)
            }
        }
        .card()
    }
}
