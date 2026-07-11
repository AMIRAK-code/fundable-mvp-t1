import SwiftUI

struct SymptomCheckerView: View {
    @EnvironmentObject private var store: PetStore
    @State private var selected: Set<String> = []
    @State private var showingAssessment = false

    var body: some View {
        NavigationStack {
            ZStack {
                CalmBackground()
                if let pet = store.selectedPet {
                    ScrollView {
                        VStack(spacing: 14) {
                            GlassCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("How this works", systemImage: "info.circle")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(CalmPalette.mist)
                                    Text("Pick the signs you've noticed and get gentle guidance on how soon to act. This is a first read, never a diagnosis — your veterinarian always has the final word.")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            GlassCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("What have you noticed in \(pet.name)?")
                                        .font(.headline)
                                    SymptomChipGrid(
                                        symptoms: SymptomLibrary.symptoms(for: pet.species),
                                        selection: $selected
                                    )
                                }
                            }
                            if !selected.isEmpty {
                                Button {
                                    showingAssessment = true
                                } label: {
                                    Label("Review guidance (\(selected.count))", systemImage: "checklist")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)

                                Button("Clear selection") {
                                    selected.removeAll()
                                }
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            }
                            redFlagsCard(for: pet)
                            Text(VetDisclaimer.short)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Health check")
            .sheet(isPresented: $showingAssessment) {
                if let pet = store.selectedPet {
                    AssessmentView(pet: pet, symptomIDs: Array(selected))
                }
            }
        }
    }

    private func redFlagsCard(for pet: Pet) -> some View {
        let guide = TipsLibrary.careGuide(for: pet.species)
        return GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Always urgent for \(pet.species.displayName.lowercased())s", systemImage: "cross.case.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CalmPalette.terracotta)
                ForEach(guide.redFlags, id: \.self) { flag in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 5))
                            .foregroundStyle(CalmPalette.terracotta)
                            .padding(.top, 6)
                        Text(flag)
                            .font(.subheadline)
                    }
                }
                Text("If you see any of these, skip the app and contact a vet directly.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct AssessmentView: View {
    @EnvironmentObject private var store: PetStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let pet: Pet
    let symptomIDs: [String]

    private var symptoms: [PetSymptom] {
        symptomIDs
            .compactMap { SymptomLibrary.symptom(id: $0, for: pet.species) }
            .sorted { $0.urgency > $1.urgency }
    }

    private var overall: SymptomUrgency {
        symptoms.map { $0.urgency }.max() ?? .mild
    }

    private var vetCallURL: URL? {
        let digits = store.settings.vetPhone.filter { "0123456789+".contains($0) }
        guard !digits.isEmpty else { return nil }
        return URL(string: "tel://\(digits)")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CalmBackground()
                ScrollView {
                    VStack(spacing: 14) {
                        overallCard
                        actionButtons
                        ForEach(symptoms) { symptom in
                            symptomCard(symptom)
                        }
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("A note from Pet Monitor", systemImage: "heart.text.square")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(CalmPalette.sage)
                                Text(VetDisclaimer.full)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Guidance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var overallCard: some View {
        GlassCard {
            HStack(spacing: 16) {
                Image(systemName: overall.symbolName)
                    .font(.system(size: 30))
                    .foregroundStyle(overall.color)
                VStack(alignment: .leading, spacing: 4) {
                    Text(overall.label)
                        .font(.headline)
                    Text(summaryText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var summaryText: String {
        switch overall {
        case .urgent:
            return "At least one sign can be serious. Please contact a veterinarian now rather than waiting for the next check-in."
        case .concerning:
            return "Nothing screams emergency, but book a vet visit in the next day or two and keep logging what you see."
        case .mild:
            return "Keep observing and log daily. If anything worsens or new signs appear, call your vet."
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        if overall == .urgent, let url = vetCallURL {
            Button {
                openURL(url)
            } label: {
                Label(
                    store.settings.vetName.isEmpty ? "Call your vet" : "Call \(store.settings.vetName)",
                    systemImage: "phone.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(CalmPalette.terracotta)
            .controlSize(.large)
        } else if overall == .urgent {
            GlassCard(cornerRadius: 20) {
                Text("Tip: add your vet's phone number in Settings for one-tap calling at moments like this.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }

        if overall >= .concerning {
            Button {
                NotificationManager.sendVetAlert(
                    petName: pet.name,
                    symptomNames: symptoms.filter { $0.urgency >= .concerning }.map { $0.name }
                )
            } label: {
                Label("Send alert to iPhone & Apple Watch", systemImage: "applewatch.radiowaves.left.and.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    private func symptomCard(_ symptom: PetSymptom) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(symptom.name)
                        .font(.headline)
                    Spacer()
                    UrgencyBadge(urgency: symptom.urgency)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Possible causes")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text(symptom.possibleCauses.joined(separator: " · "))
                        .font(.subheadline)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("What helps")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text(symptom.guidance)
                        .font(.subheadline)
                }
            }
        }
    }
}
