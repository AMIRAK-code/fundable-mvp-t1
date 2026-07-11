import SwiftUI

// MARK: - Pet avatar

struct PetAvatar: View {
    let pet: Pet
    var size: CGFloat = 56

    private var color: Color {
        let colors = CalmPalette.avatarColors
        return colors[abs(pet.colorIndex) % colors.count]
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.22))
            Image(systemName: pet.species.symbolName)
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Wellness ring

struct WellnessRing: View {
    let score: Int?
    var size: CGFloat = 116

    private var progress: CGFloat { CGFloat(score ?? 0) / 100 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), style: StrokeStyle(lineWidth: 11, lineCap: .round))
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Wellness.color(for: score), style: StrokeStyle(lineWidth: 11, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: progress)
            VStack(spacing: 2) {
                if let score {
                    Text("\(score)")
                        .font(.system(size: size * 0.27, weight: .semibold, design: .rounded))
                    Text("wellness")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(CalmPalette.sage)
                    Text("no data")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Rating picker (1–5)

struct RatingPicker: View {
    let title: String
    let symbolName: String
    @Binding var value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(title, systemImage: symbolName)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(RatingScale.label(for: value))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { step in
                    Button {
                        value = step
                    } label: {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(step <= value ? CalmPalette.sage : Color.primary.opacity(0.08))
                            .frame(height: 14)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Urgency badge

struct UrgencyBadge: View {
    let urgency: SymptomUrgency

    var body: some View {
        Label(urgency.badge, systemImage: urgency.symbolName)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(urgency.color.opacity(0.16)))
            .foregroundStyle(urgency.color)
    }
}

// MARK: - Symptom chip grid

struct SymptomChipGrid: View {
    let symptoms: [PetSymptom]
    @Binding var selection: Set<String>

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
            ForEach(symptoms) { symptom in
                chip(for: symptom)
            }
        }
    }

    private func chip(for symptom: PetSymptom) -> some View {
        let isSelected = selection.contains(symptom.id)
        return Button {
            if isSelected {
                selection.remove(symptom.id)
            } else {
                selection.insert(symptom.id)
            }
        } label: {
            Text(symptom.name)
                .font(.footnote.weight(.medium))
                .multilineTextAlignment(.center)
                .padding(.vertical, 9)
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(isSelected ? symptom.urgency.color.opacity(0.20) : Color.primary.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .strokeBorder(isSelected ? symptom.urgency.color.opacity(0.55) : Color.clear, lineWidth: 1)
                )
                .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty state

struct EmptyStateCard: View {
    let symbolName: String
    let title: String
    let message: String

    var body: some View {
        GlassCard {
            VStack(spacing: 10) {
                Image(systemName: symbolName)
                    .font(.system(size: 34))
                    .foregroundStyle(CalmPalette.sage)
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }
}
