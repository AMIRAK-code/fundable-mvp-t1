import Foundation
import Combine
import WidgetKit

struct PetAlert: Identifiable {
    let id: String
    let message: String
    let urgency: SymptomUrgency
}

@MainActor
final class PetStore: ObservableObject {

    @Published private(set) var pets: [Pet] = []
    @Published private(set) var entries: [LogEntry] = []

    @Published var settings: AppSettings = AppSettings() {
        didSet {
            persistSettings()
            if settings.reminderFingerprint != oldValue.reminderFingerprint {
                rescheduleNotifications()
            }
            if settings.selectedPetID != oldValue.selectedPetID {
                refreshWidgetSnapshot()
            }
        }
    }

    init() {
        pets = SharedStorage.load([Pet].self, from: SharedStorage.petsFile) ?? []
        entries = SharedStorage.load([LogEntry].self, from: SharedStorage.entriesFile) ?? []
        settings = SharedStorage.load(AppSettings.self, from: SharedStorage.settingsFile) ?? AppSettings()
        if settings.selectedPetID == nil || !pets.contains(where: { $0.id == settings.selectedPetID }) {
            settings.selectedPetID = pets.first?.id
            persistSettings()
        }
        refreshWidgetSnapshot()
    }

    // MARK: - Selection

    var selectedPet: Pet? {
        pets.first { $0.id == settings.selectedPetID } ?? pets.first
    }

    func selectPet(_ pet: Pet) {
        settings.selectedPetID = pet.id
    }

    // MARK: - Pets

    func addPet(_ pet: Pet) {
        pets.append(pet)
        persistPets()
        settings.selectedPetID = pet.id
        refreshWidgetSnapshot()
    }

    func updatePet(_ pet: Pet) {
        guard let index = pets.firstIndex(where: { $0.id == pet.id }) else { return }
        pets[index] = pet
        persistPets()
        refreshWidgetSnapshot()
    }

    func deletePet(_ pet: Pet) {
        pets.removeAll { $0.id == pet.id }
        entries.removeAll { $0.petID == pet.id }
        persistPets()
        persistEntries()
        if settings.selectedPetID == pet.id {
            settings.selectedPetID = pets.first?.id
        }
        refreshWidgetSnapshot()
    }

    // MARK: - Log entries

    /// Saves an entry and returns any urgent symptoms it contained.
    /// Urgent symptoms also fire a local "contact your vet" notification,
    /// which mirrors to a paired Apple Watch.
    @discardableResult
    func addEntry(_ entry: LogEntry) -> [PetSymptom] {
        entries.append(entry)
        entries.sort { $0.date > $1.date }
        persistEntries()
        refreshWidgetSnapshot()

        let urgent = urgentSymptoms(in: entry)
        if !urgent.isEmpty, let pet = pets.first(where: { $0.id == entry.petID }) {
            NotificationManager.sendVetAlert(petName: pet.name, symptomNames: urgent.map { $0.name })
        }
        return urgent
    }

    func deleteEntry(_ entry: LogEntry) {
        entries.removeAll { $0.id == entry.id }
        persistEntries()
        refreshWidgetSnapshot()
    }

    func entries(for pet: Pet) -> [LogEntry] {
        entries.filter { $0.petID == pet.id }.sorted { $0.date > $1.date }
    }

    func urgentSymptoms(in entry: LogEntry) -> [PetSymptom] {
        guard let pet = pets.first(where: { $0.id == entry.petID }) else { return [] }
        return entry.symptomIDs
            .compactMap { SymptomLibrary.symptom(id: $0, for: pet.species) }
            .filter { $0.urgency == .urgent }
    }

    // MARK: - Derived state

    func lastEntryDate(for pet: Pet) -> Date? {
        entries(for: pet).first?.date
    }

    func streak(for pet: Pet) -> Int {
        let calendar = Calendar.current
        let days = Set(entries(for: pet).map { calendar.startOfDay(for: $0.date) })
        guard !days.isEmpty else { return 0 }

        var day = calendar.startOfDay(for: Date())
        if !days.contains(day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day),
                  days.contains(yesterday) else { return 0 }
            day = yesterday
        }

        var count = 0
        while days.contains(day) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    /// 0–100 score from the last 7 days of mood, energy and appetite,
    /// reduced by logged symptoms. Nil until there is at least one entry.
    func wellnessScore(for pet: Pet) -> Int? {
        let cutoff = Date().addingTimeInterval(-7 * 86_400)
        let recent = entries(for: pet).filter { $0.date > cutoff }
        guard !recent.isEmpty else { return nil }

        let averageRating = recent.reduce(0.0) { partial, entry in
            partial + Double(entry.mood + entry.energy + entry.appetite) / 3.0
        } / Double(recent.count)

        var score = averageRating / 5.0 * 100.0

        let symptomPenalty = recent.reduce(0.0) { total, entry in
            let entryPenalty = entry.symptomIDs
                .compactMap { SymptomLibrary.symptom(id: $0, for: pet.species) }
                .reduce(0.0) { $0 + penalty(for: $1.urgency) }
            return total + entryPenalty
        }
        score -= min(symptomPenalty, 40)

        return max(5, min(100, Int(score.rounded())))
    }

    private func penalty(for urgency: SymptomUrgency) -> Double {
        switch urgency {
        case .mild: return 2
        case .concerning: return 6
        case .urgent: return 15
        }
    }

    func isCheckInDue(for pet: Pet) -> Bool {
        guard let last = lastEntryDate(for: pet) else { return true }
        return Date().timeIntervalSince(last) > settings.cadence.lengthInDays * 86_400
    }

    func dueDescription(for pet: Pet) -> String {
        guard let last = lastEntryDate(for: pet) else { return "First check-in awaits" }
        let next = last.addingTimeInterval(settings.cadence.lengthInDays * 86_400)
        if next <= Date() { return "Check-in due" }
        return "Next check-in " + next.formatted(.relative(presentation: .named))
    }

    func alerts(for pet: Pet) -> [PetAlert] {
        var result: [PetAlert] = []
        let recentCutoff = Date().addingTimeInterval(-48 * 3_600)
        let recent = entries(for: pet).filter { $0.date > recentCutoff }

        let recentSymptoms = recent
            .flatMap { $0.symptomIDs }
            .compactMap { SymptomLibrary.symptom(id: $0, for: pet.species) }

        if recentSymptoms.contains(where: { $0.urgency == .urgent }) {
            result.append(PetAlert(
                id: "urgent-symptoms",
                message: "An urgent sign was logged in the last two days. Please contact your vet if you haven't yet.",
                urgency: .urgent
            ))
        } else if recentSymptoms.contains(where: { $0.urgency == .concerning }) {
            result.append(PetAlert(
                id: "concerning-symptoms",
                message: "Some concerning signs were logged recently — worth mentioning to your vet.",
                urgency: .concerning
            ))
        }

        if let last = lastEntryDate(for: pet),
           Date().timeIntervalSince(last) > settings.cadence.lengthInDays * 86_400 * 2 {
            result.append(PetAlert(
                id: "overdue",
                message: "It's been a while since \(pet.name)'s last check-in. A quick log keeps trends honest.",
                urgency: .mild
            ))
        }

        let weights = entries(for: pet).compactMap { $0.weightKilograms }
        if weights.count >= 2 {
            let latest = weights[0]
            let previous = weights[1]
            if previous > 0, abs(latest - previous) / previous >= 0.10 {
                result.append(PetAlert(
                    id: "weight-change",
                    message: "Weight changed notably between the last two measurements — a good thing to raise with your vet.",
                    urgency: .concerning
                ))
            }
        }

        return result.sorted { $0.urgency > $1.urgency }
    }

    // MARK: - App lifecycle

    func handleAppActive() {
        rescheduleNotifications()
        refreshWidgetSnapshot()
    }

    func rescheduleNotifications() {
        NotificationManager.rescheduleAll(settings: settings, pet: selectedPet)
    }

    // MARK: - Export / reset

    func exportJSON() -> String {
        struct Export: Encodable {
            let exportedAt: Date
            let pets: [Pet]
            let entries: [LogEntry]
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let export = Export(exportedAt: Date(), pets: pets, entries: entries)
        guard let data = try? encoder.encode(export),
              let string = String(data: data, encoding: .utf8) else { return "{}" }
        return string
    }

    func resetAllData() {
        pets = []
        entries = []
        settings = AppSettings()
        persistPets()
        persistEntries()
        refreshWidgetSnapshot()
    }

    // MARK: - Persistence

    private func persistPets() {
        SharedStorage.save(pets, to: SharedStorage.petsFile)
    }

    private func persistEntries() {
        SharedStorage.save(entries, to: SharedStorage.entriesFile)
    }

    private func persistSettings() {
        SharedStorage.save(settings, to: SharedStorage.settingsFile)
    }

    private func refreshWidgetSnapshot() {
        if let pet = selectedPet {
            let snapshot = WidgetSnapshot(
                petName: pet.name,
                speciesRawValue: pet.species.rawValue,
                wellnessScore: wellnessScore(for: pet),
                streakDays: streak(for: pet),
                lastLogDate: lastEntryDate(for: pet),
                dueDescription: dueDescription(for: pet),
                generatedAt: Date()
            )
            SharedStorage.saveSnapshot(snapshot)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
