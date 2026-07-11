import SwiftUI

struct LogEntryView: View {
    @EnvironmentObject private var store: PetStore
    @Environment(\.dismiss) private var dismiss

    let pet: Pet

    @State private var mood = 3
    @State private var energy = 3
    @State private var appetite = 3
    @State private var hydration: HydrationLevel = .normal
    @State private var weightText = ""
    @State private var selectedSymptoms: Set<String> = []
    @State private var notes = ""
    @State private var showingUrgentAlert = false
    @State private var urgentNames: [String] = []

    var body: some View {
        NavigationStack {
            ZStack {
                CalmBackground()
                ScrollView {
                    VStack(spacing: 14) {
                        GlassCard {
                            Text(pet.species.checkInFocus)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        GlassCard {
                            VStack(spacing: 18) {
                                RatingPicker(title: "Mood", symbolName: "face.smiling", value: $mood)
                                RatingPicker(title: "Energy", symbolName: "bolt.heart", value: $energy)
                                RatingPicker(title: "Appetite", symbolName: "fork.knife", value: $appetite)
                            }
                        }
                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Water intake", systemImage: "drop.fill")
                                    .font(.subheadline.weight(.medium))
                                Picker("Water intake", selection: $hydration) {
                                    ForEach(HydrationLevel.allCases) { level in
                                        Text(level.shortLabel).tag(level)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                        GlassCard {
                            HStack {
                                Label("Weight", systemImage: "scalemass")
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                TextField("optional", text: $weightText)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 100)
                                Text("kg")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Anything unusual?", systemImage: "stethoscope")
                                    .font(.subheadline.weight(.medium))
                                Text("Tap any signs you noticed. Urgent signs send a vet alert to your iPhone and paired Apple Watch.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                SymptomChipGrid(
                                    symptoms: SymptomLibrary.symptoms(for: pet.species),
                                    selection: $selectedSymptoms
                                )
                            }
                        }
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Notes", systemImage: "text.alignleft")
                                    .font(.subheadline.weight(.medium))
                                TextEditor(text: $notes)
                                    .frame(minHeight: 90)
                                    .scrollContentBackground(.hidden)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .alert("Please contact your vet", isPresented: $showingUrgentAlert) {
                Button("Understood") { dismiss() }
            } message: {
                Text("You logged: \(urgentNames.joined(separator: ", ")). These signs shouldn't wait — a vet alert was also sent to your iPhone and Apple Watch. \(VetDisclaimer.short)")
            }
        }
    }

    private func save() {
        var entry = LogEntry(
            petID: pet.id,
            mood: mood,
            energy: energy,
            appetite: appetite,
            hydration: hydration,
            symptomIDs: Array(selectedSymptoms),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        let normalizedWeight = weightText.replacingOccurrences(of: ",", with: ".")
        if let weight = Double(normalizedWeight), weight > 0 {
            entry.weightKilograms = weight
        }

        let urgent = store.addEntry(entry)
        if urgent.isEmpty {
            dismiss()
        } else {
            urgentNames = urgent.map { $0.name }
            showingUrgentAlert = true
        }
    }
}
