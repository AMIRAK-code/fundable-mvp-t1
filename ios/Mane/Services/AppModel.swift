import SwiftUI
import UIKit

/// Single source of truth for the app: profile, generated routine, catalog
/// data, scan history and daily-completion tracking.
@MainActor
final class AppModel: ObservableObject {

    // MARK: - Published state

    @Published private(set) var profile: HairProfile?
    @Published private(set) var routine: HairRoutine?
    @Published private(set) var products: [Product] = []
    @Published private(set) var tips: [Tip] = []
    @Published private(set) var sources: [DataSourceStatus] = []
    @Published private(set) var sessions: [ScanSession] = []
    @Published private(set) var isLoadingData = false
    /// Date key → completed step ids for that day.
    @Published private(set) var completions: [String: Set<String>] = [:]

    // MARK: - Storage

    private let defaults = UserDefaults.standard
    private let scanStore = ScanStore()

    private enum Keys {
        static let profile = "mane.profile"
        static let routine = "mane.routine"
        static let completions = "mane.completions"
    }

    init() {
        loadPersistedState()
        Task { await refreshData() }
    }

    // MARK: - Onboarding / profile

    func completeOnboarding(with profile: HairProfile) {
        self.profile = profile
        self.routine = RoutineEngine.buildRoutine(for: profile)
        persistProfileAndRoutine()
    }

    func resetProfile() {
        profile = nil
        routine = nil
        completions = [:]
        defaults.removeObject(forKey: Keys.profile)
        defaults.removeObject(forKey: Keys.routine)
        defaults.removeObject(forKey: Keys.completions)
    }

    // MARK: - Catalog data (multi-source)

    func refreshData() async {
        isLoadingData = true
        let result = await DataHub.shared.loadAll()
        products = result.products
        tips = result.tips
        sources = result.sources
        isLoadingData = false
    }

    func recommendedProducts(limit: Int = 6) -> [Product] {
        RoutineEngine.recommend(products: products, for: profile, limit: limit)
    }

    func tipOfTheDay() -> Tip? {
        guard !tips.isEmpty else { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return tips[day % tips.count]
    }

    // MARK: - Daily completions

    static func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func isDone(_ step: RoutineStep, on date: Date = Date()) -> Bool {
        completions[Self.dateKey(for: date)]?.contains(step.id) ?? false
    }

    func toggle(_ step: RoutineStep, on date: Date = Date()) {
        let key = Self.dateKey(for: date)
        var set = completions[key] ?? []
        if set.contains(step.id) {
            set.remove(step.id)
        } else {
            set.insert(step.id)
        }
        completions[key] = set
        persistCompletions()
    }

    /// Fraction of today's active steps completed (0 when none are active).
    func completionFraction(on date: Date = Date()) -> Double {
        guard let routine else { return 0 }
        let active = routine.steps(for: date)
        guard !active.isEmpty else { return 0 }
        let done = active.filter { isDone($0, on: date) }.count
        return Double(done) / Double(active.count)
    }

    /// Consecutive days (ending today or yesterday) with ≥75% of steps done.
    var streak: Int {
        guard routine != nil else { return 0 }
        let calendar = Calendar.current
        var day = calendar.startOfDay(for: Date())
        var count = 0
        if completionFraction(on: day) < 0.75 {
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = previous
        }
        while completionFraction(on: day) >= 0.75 && count < 365 {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    // MARK: - Scans

    var latestSession: ScanSession? { sessions.last }

    var trends: ScanTrends? { ScanTrends.compute(sessions: sessions) }

    func addSession(_ session: ScanSession, images: [ScanAngle: UIImage]) {
        scanStore.saveImages(images, for: session.id)
        sessions.append(session)
        sessions.sort { $0.date < $1.date }
        scanStore.saveSessions(sessions)
    }

    func deleteSession(_ session: ScanSession) {
        scanStore.deleteImages(for: session.id)
        sessions.removeAll { $0.id == session.id }
        scanStore.saveSessions(sessions)
    }

    func deleteAllSessions() {
        scanStore.deleteAll()
        sessions = []
    }

    func image(for session: ScanSession, angle: ScanAngle) -> UIImage? {
        scanStore.image(for: session.id, angle: angle)
    }

    // MARK: - Persistence

    private func loadPersistedState() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let data = defaults.data(forKey: Keys.profile),
           let stored = try? decoder.decode(HairProfile.self, from: data) {
            profile = stored
        }
        if let data = defaults.data(forKey: Keys.routine),
           let stored = try? decoder.decode(HairRoutine.self, from: data) {
            routine = stored
        }
        if profile != nil && routine == nil, let profile {
            routine = RoutineEngine.buildRoutine(for: profile)
        }
        if let data = defaults.data(forKey: Keys.completions),
           let stored = try? JSONDecoder().decode([String: Set<String>].self, from: data) {
            completions = stored
        }
        sessions = scanStore.loadSessions()
    }

    private func persistProfileAndRoutine() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let profile, let data = try? encoder.encode(profile) {
            defaults.set(data, forKey: Keys.profile)
        }
        if let routine, let data = try? encoder.encode(routine) {
            defaults.set(data, forKey: Keys.routine)
        }
    }

    private func persistCompletions() {
        if let data = try? JSONEncoder().encode(completions) {
            defaults.set(data, forKey: Keys.completions)
        }
    }
}
