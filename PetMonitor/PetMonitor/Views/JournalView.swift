import SwiftUI

struct JournalView: View {
    @EnvironmentObject private var store: PetStore
    @State private var showingLogSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                CalmBackground()
                if let pet = store.selectedPet {
                    let petEntries = store.entries(for: pet)
                    if petEntries.isEmpty {
                        VStack {
                            EmptyStateCard(
                                symbolName: "book.closed.fill",
                                title: "No check-ins yet",
                                message: "Each check-in becomes a page in \(pet.name)'s journal — and a data point your vet will love."
                            )
                            .padding(16)
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(petEntries) { entry in
                                EntryRow(entry: entry, species: pet.species)
                                    .listRowBackground(Color.primary.opacity(0.03))
                            }
                            .onDelete { offsets in
                                delete(offsets, from: petEntries)
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingLogSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingLogSheet) {
                if let pet = store.selectedPet {
                    LogEntryView(pet: pet)
                }
            }
        }
    }

    private func delete(_ offsets: IndexSet, from list: [LogEntry]) {
        for index in offsets {
            store.deleteEntry(list[index])
        }
    }
}

struct EntryRow: View {
    let entry: LogEntry
    let species: PetSpecies

    private var symptoms: [PetSymptom] {
        entry.symptomIDs.compactMap { SymptomLibrary.symptom(id: $0, for: species) }
    }

    private var worstUrgency: SymptomUrgency? {
        symptoms.map { $0.urgency }.max()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if let worstUrgency {
                    UrgencyBadge(urgency: worstUrgency)
                }
            }
            HStack(spacing: 14) {
                metric("face.smiling", entry.mood)
                metric("bolt.heart", entry.energy)
                metric("fork.knife", entry.appetite)
                if let weight = entry.weightKilograms {
                    Label(String(format: "%.1f kg", weight), systemImage: "scalemass")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            if !symptoms.isEmpty {
                Text(symptoms.map { $0.name }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(CalmPalette.amber)
            }
            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 3)
    }

    private func metric(_ symbolName: String, _ value: Int) -> some View {
        Label("\(value)/5", systemImage: symbolName)
    }
}
