import Foundation

// MARK: - Species

enum PetSpecies: String, Codable, CaseIterable, Identifiable {
    case dog
    case cat
    case rabbit
    case hamster
    case parrot

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dog: return "Dog"
        case .cat: return "Cat"
        case .rabbit: return "Rabbit"
        case .hamster: return "Hamster"
        case .parrot: return "Parrot"
        }
    }

    var symbolName: String {
        switch self {
        case .dog: return "dog.fill"
        case .cat: return "cat.fill"
        case .rabbit: return "hare.fill"
        case .hamster: return "pawprint.fill"
        case .parrot: return "bird.fill"
        }
    }

    /// A short, species-specific reminder shown on the check-in screen.
    var checkInFocus: String {
        switch self {
        case .dog: return "Watch appetite, energy on walks, and anything unusual in movement."
        case .cat: return "Litter habits, hiding, and grooming changes say the most about cats."
        case .rabbit: return "Hay intake and droppings are the two signals that matter most."
        case .hamster: return "Evening activity and food stashing are your best daily signals."
        case .parrot: return "Droppings, feather posture, and voice tell you how your bird feels."
        }
    }
}

// MARK: - Pet

struct Pet: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var species: PetSpecies
    var birthDate: Date? = nil
    var weightKilograms: Double? = nil
    var colorIndex: Int = 0

    var ageDescription: String? {
        guard let birthDate else { return nil }
        let components = Calendar.current.dateComponents([.year, .month], from: birthDate, to: Date())
        let years = components.year ?? 0
        let months = components.month ?? 0
        if years <= 0 && months <= 0 { return "under a month old" }
        if years <= 0 { return "\(months) mo old" }
        if months == 0 { return "\(years) yr old" }
        return "\(years) yr \(months) mo old"
    }
}

// MARK: - Log entries

enum HydrationLevel: String, Codable, CaseIterable, Identifiable {
    case low
    case normal
    case high

    var id: String { rawValue }

    var label: String {
        switch self {
        case .low: return "Less than usual"
        case .normal: return "Normal"
        case .high: return "More than usual"
        }
    }

    var shortLabel: String {
        switch self {
        case .low: return "Less"
        case .normal: return "Normal"
        case .high: return "More"
        }
    }
}

struct LogEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var petID: UUID
    var date: Date = Date()
    var mood: Int
    var energy: Int
    var appetite: Int
    var hydration: HydrationLevel = .normal
    var weightKilograms: Double? = nil
    var symptomIDs: [String] = []
    var notes: String = ""
}

enum RatingScale {
    static let labels = ["Very low", "Low", "Okay", "Good", "Great"]

    static func label(for value: Int) -> String {
        let index = min(max(value - 1, 0), labels.count - 1)
        return labels[index]
    }
}

// MARK: - Check-in cycle

enum CheckInCadence: String, Codable, CaseIterable, Identifiable {
    case morningAndEvening
    case daily
    case everyOtherDay
    case weekly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .morningAndEvening: return "Morning & evening"
        case .daily: return "Once a day"
        case .everyOtherDay: return "Every other day"
        case .weekly: return "Once a week"
        }
    }

    var lengthInDays: Double {
        switch self {
        case .morningAndEvening: return 0.5
        case .daily: return 1
        case .everyOtherDay: return 2
        case .weekly: return 7
        }
    }
}

// MARK: - Settings

struct AppSettings: Codable, Equatable {
    var cadence: CheckInCadence = .daily
    var remindersEnabled: Bool = true
    var reminderHour: Int = 9
    var reminderMinute: Int = 0
    var dailyTipEnabled: Bool = true
    var tipHour: Int = 8
    var tipMinute: Int = 30
    var vetName: String = ""
    var vetPhone: String = ""
    var selectedPetID: UUID? = nil

    /// Changes to any of these fields require notifications to be rescheduled.
    var reminderFingerprint: String {
        "\(cadence.rawValue)-\(remindersEnabled)-\(reminderHour):\(reminderMinute)-\(dailyTipEnabled)-\(tipHour):\(tipMinute)-\(selectedPetID?.uuidString ?? "none")"
    }
}

// MARK: - Widget snapshot

/// A small, flat summary the app writes for the widgets to read.
struct WidgetSnapshot: Codable {
    var petName: String
    var speciesRawValue: String
    var wellnessScore: Int? = nil
    var streakDays: Int = 0
    var lastLogDate: Date? = nil
    var dueDescription: String = ""
    var generatedAt: Date = Date()

    var species: PetSpecies { PetSpecies(rawValue: speciesRawValue) ?? .dog }
}
