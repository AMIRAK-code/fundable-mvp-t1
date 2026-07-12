import SwiftUI
import UIKit

/// Detail page for a saved scan: photos per angle plus the stored metrics.
struct ScanDetailView: View {
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    let session: ScanSession
    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
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

                SectionHeader(title: "Photos")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(session.metrics.sorted { $0.angle.order < $1.angle.order }) { metric in
                        VStack(spacing: 6) {
                            if let image = model.image(for: session, angle: metric.angle) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 150)
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            } else {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(theme.palette.surfaceSecondary)
                                    .frame(height: 150)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundStyle(theme.palette.textSecondary)
                                    )
                            }
                            Text(metric.angle.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(theme.palette.textSecondary)
                        }
                    }
                }

                SectionHeader(title: "Metrics")
                VStack(spacing: 8) {
                    ForEach(session.metrics.sorted { $0.angle.order < $1.angle.order }) { metric in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(metric.angle.title)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(theme.palette.textPrimary)
                            HStack(spacing: 14) {
                                if let ratio = metric.hairlineRatio {
                                    metricPill("Forehead ratio", String(format: "%.3f", ratio))
                                }
                                if let density = metric.densityScore {
                                    metricPill("Density", "\(Int(density.rounded()))")
                                }
                                metricPill("Confidence", "\(Int((metric.confidence * 100).rounded()))%")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                    }
                }
                .card()

                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Label("Delete this scan", systemImage: "trash")
                        .font(.headline)
                        .foregroundStyle(theme.palette.negative)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(theme.palette.negative.opacity(0.12))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                DisclaimerFooter()
            }
            .padding(20)
        }
        .themedScreen()
        .navigationTitle(session.date.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete this scan?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                model.deleteSession(session)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func metricPill(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(theme.palette.textSecondary)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(theme.palette.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(theme.palette.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
