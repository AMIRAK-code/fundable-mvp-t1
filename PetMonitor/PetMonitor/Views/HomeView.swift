import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: PetStore
    @State private var showingLogSheet = false
    @State private var showingTips = false

    var body: some View {
        NavigationStack {
            ZStack {
                CalmBackground()
                if let pet = store.selectedPet {
                    ScrollView {
                        VStack(spacing: 14) {
                            headerCard(for: pet)
                            wellnessCard(for: pet)
                            ForEach(store.alerts(for: pet)) { alert in
                                alertCard(alert)
                            }
                            checkInCard(for: pet)
                            tipCard(for: pet)
                            careBasicsCard(for: pet)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle(store.selectedPet?.name ?? "Pet Monitor")
            .toolbar {
                if store.pets.count > 1 {
                    ToolbarItem(placement: .topBarTrailing) {
                        petSwitcher
                    }
                }
            }
            .sheet(isPresented: $showingLogSheet) {
                if let pet = store.selectedPet {
                    LogEntryView(pet: pet)
                }
            }
            .sheet(isPresented: $showingTips) {
                if let pet = store.selectedPet {
                    TipsView(species: pet.species)
                }
            }
        }
    }

    private var petSwitcher: some View {
        Menu {
            ForEach(store.pets) { pet in
                Button {
                    store.selectPet(pet)
                } label: {
                    if pet.id == store.selectedPet?.id {
                        Label(pet.name, systemImage: "checkmark")
                    } else {
                        Label(pet.name, systemImage: pet.species.symbolName)
                    }
                }
            }
        } label: {
            Image(systemName: "chevron.up.chevron.down")
        }
    }

    private func headerCard(for pet: Pet) -> some View {
        GlassCard {
            HStack(spacing: 14) {
                PetAvatar(pet: pet, size: 62)
                VStack(alignment: .leading, spacing: 3) {
                    Text(pet.name)
                        .font(.title3.weight(.semibold))
                    Text(subtitle(for: pet))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text("\(store.streak(for: pet))")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(CalmPalette.sage)
                    Text("day streak")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func subtitle(for pet: Pet) -> String {
        if let age = pet.ageDescription {
            return "\(pet.species.displayName) · \(age)"
        }
        return pet.species.displayName
    }

    private func wellnessCard(for pet: Pet) -> some View {
        let score = store.wellnessScore(for: pet)
        return GlassCard {
            HStack(spacing: 20) {
                WellnessRing(score: score)
                VStack(alignment: .leading, spacing: 6) {
                    Text(Wellness.label(for: score))
                        .font(.headline)
                    Text(score == nil
                         ? "Log a first check-in to start \(pet.name)'s wellness picture."
                         : "Based on mood, energy, appetite and signs from the last 7 days.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func alertCard(_ alert: PetAlert) -> some View {
        GlassCard(cornerRadius: 20) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: alert.urgency.symbolName)
                    .foregroundStyle(alert.urgency.color)
                    .padding(.top, 2)
                Text(alert.message)
                    .font(.subheadline)
            }
        }
    }

    private func checkInCard(for pet: Pet) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Check-in cycle", systemImage: "arrow.triangle.2.circlepath")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CalmPalette.sage)
                Text(store.dueDescription(for: pet))
                    .font(.headline)
                Text(pet.species.checkInFocus)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button {
                    showingLogSheet = true
                } label: {
                    Label("Log a check-in", systemImage: "square.and.pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    private func tipCard(for pet: Pet) -> some View {
        let tip = TipsLibrary.dailyTip(for: pet.species)
        return GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Today's tip", systemImage: "leaf.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CalmPalette.sage)
                    Spacer()
                    Label(tip.category.rawValue, systemImage: tip.category.symbolName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(tip.text)
                    .font(.subheadline)
                Button("Browse all tips") {
                    showingTips = true
                }
                .font(.footnote.weight(.medium))
            }
        }
    }

    private func careBasicsCard(for pet: Pet) -> some View {
        let guide = TipsLibrary.careGuide(for: pet.species)
        return GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Daily basics for \(pet.species.displayName.lowercased())s", systemImage: "checklist")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CalmPalette.mist)
                ForEach(guide.dailyBasics, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 5))
                            .foregroundStyle(CalmPalette.mist)
                            .padding(.top, 6)
                        Text(item)
                            .font(.subheadline)
                    }
                }
            }
        }
    }
}
