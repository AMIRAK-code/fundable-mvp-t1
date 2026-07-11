import SwiftUI

struct PetEditorView: View {
    @EnvironmentObject private var store: PetStore
    @Environment(\.dismiss) private var dismiss

    private let existingPet: Pet?

    @State private var name: String
    @State private var species: PetSpecies
    @State private var hasBirthDate: Bool
    @State private var birthDate: Date
    @State private var weightText: String
    @State private var colorIndex: Int
    @State private var showingDeleteConfirm = false

    init(pet: Pet?) {
        existingPet = pet
        _name = State(initialValue: pet?.name ?? "")
        _species = State(initialValue: pet?.species ?? .dog)
        _hasBirthDate = State(initialValue: pet?.birthDate != nil)
        _birthDate = State(initialValue: pet?.birthDate
            ?? Calendar.current.date(byAdding: .year, value: -1, to: Date())
            ?? Date())
        _weightText = State(initialValue: pet?.weightKilograms.map { String($0) } ?? "")
        _colorIndex = State(initialValue: pet?.colorIndex ?? 0)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Form {
            Section("Name") {
                TextField("e.g. Maple", text: $name)
            }
            Section("Species") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 10)], spacing: 10) {
                    ForEach(PetSpecies.allCases) { candidate in
                        speciesCard(candidate)
                    }
                }
                .padding(.vertical, 4)
            }
            Section("Details") {
                Toggle("I know the birth date", isOn: $hasBirthDate)
                if hasBirthDate {
                    DatePicker("Birth date", selection: $birthDate, in: ...Date(), displayedComponents: .date)
                }
                HStack {
                    Text("Weight")
                    Spacer()
                    TextField("optional", text: $weightText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 110)
                    Text("kg")
                        .foregroundStyle(.secondary)
                }
            }
            Section("Avatar color") {
                HStack(spacing: 14) {
                    ForEach(0..<CalmPalette.avatarColors.count, id: \.self) { index in
                        colorDot(index)
                    }
                }
                .padding(.vertical, 4)
            }
            if existingPet != nil {
                Section {
                    Button("Remove pet", role: .destructive) {
                        showingDeleteConfirm = true
                    }
                }
            }
        }
        .navigationTitle(existingPet == nil ? "New pet" : "Edit pet")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(trimmedName.isEmpty)
            }
        }
        .confirmationDialog(
            "Remove \(existingPet?.name ?? "this pet") and all logs?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Remove pet and its logs", role: .destructive) {
                if let existingPet {
                    store.deletePet(existingPet)
                    dismiss()
                }
            }
        }
    }

    private func speciesCard(_ candidate: PetSpecies) -> some View {
        Button {
            species = candidate
        } label: {
            VStack(spacing: 6) {
                Image(systemName: candidate.symbolName)
                    .font(.title2)
                    .foregroundStyle(species == candidate ? CalmPalette.sage : Color.secondary)
                Text(candidate.displayName)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(species == candidate ? CalmPalette.sage.opacity(0.18) : Color.primary.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(species == candidate ? CalmPalette.sage.opacity(0.6) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func colorDot(_ index: Int) -> some View {
        Button {
            colorIndex = index
        } label: {
            ZStack {
                Circle()
                    .fill(CalmPalette.avatarColors[index].opacity(0.8))
                    .frame(width: 30, height: 30)
                if colorIndex == index {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func save() {
        var pet = existingPet ?? Pet(name: trimmedName, species: species)
        pet.name = trimmedName
        pet.species = species
        pet.birthDate = hasBirthDate ? birthDate : nil
        let normalizedWeight = weightText.replacingOccurrences(of: ",", with: ".")
        pet.weightKilograms = Double(normalizedWeight)
        pet.colorIndex = colorIndex

        if existingPet == nil {
            store.addPet(pet)
        } else {
            store.updatePet(pet)
        }
        dismiss()
    }
}
