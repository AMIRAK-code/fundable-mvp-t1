import Foundation
import Combine

enum AppTab: Hashable {
    case home, journal, wishlist, learn, settings
}

/// Single observable source of truth. All mutations funnel through here so
/// persistence, widget reloads and watch sync stay consistent.
final class AppStore: ObservableObject {
    @Published var state: AppState

    // Transient UI state (not persisted).
    @Published var selectedTab: AppTab = .home
    @Published var showCravingSOS = false

    /// Set by the host app to push state to the paired device after each save.
    var onStateSaved: ((AppState) -> Void)?

    init() {
        state = Persistence.load() ?? AppState()
    }

    var theme: AppTheme { AppTheme.theme(withID: state.themeID) }

    var stats: Stats { Stats(state: state, now: Date()) }

    func save(pushToCounterpart: Bool = true) {
        state.bestStreakCache = max(state.bestStreakCache, stats.streakDays)
        Persistence.save(state)
        if pushToCounterpart {
            onStateSaved?(state)
        }
    }

    /// Replace local state with a synced copy from the paired device.
    func replaceState(_ newState: AppState) {
        state = newState
        Persistence.save(newState)
    }

    // MARK: Mutations

    func completeOnboarding(profile: UserProfile) {
        state.profile = profile
        state.onboardingComplete = true
        save()
    }

    func updateProfile(_ profile: UserProfile) {
        state.profile = profile
        save()
    }

    func logSlip(units: Double, date: Date = Date(), note: String? = nil) {
        // Bank the streak that is about to be broken.
        state.bestStreakCache = max(state.bestStreakCache, stats.streakDays)
        state.slips.append(SlipEntry(date: date, units: units, note: note))
        state.slips.sort { $0.date < $1.date }
        save()
    }

    func removeSlip(id: UUID) {
        state.slips.removeAll { $0.id == id }
        save()
    }

    func logResistedCraving() {
        state.resistedCravings.append(Date())
        save()
    }

    func addWishlistItem(name: String, price: Double, emoji: String) {
        state.wishlist.append(WishlistItem(name: name, price: price, emoji: emoji))
        save()
    }

    func removeWishlistItem(id: UUID) {
        state.wishlist.removeAll { $0.id == id }
        save()
    }

    func markPurchased(_ item: WishlistItem) {
        guard let index = state.wishlist.firstIndex(where: { $0.id == item.id }) else { return }
        state.wishlist[index].purchasedAt = Date()
        save()
    }

    func setTheme(_ id: String) {
        state.themeID = id
        save()
    }

    func setNotificationsEnabled(_ enabled: Bool) {
        state.notificationsEnabled = enabled
        save()
    }

    /// Restart the quit attempt today, keeping wishlist and best streak.
    func restartQuit() {
        state.bestStreakCache = max(state.bestStreakCache, stats.streakDays)
        state.profile.startDate = Date()
        state.slips = []
        save()
    }

    func resetAllData() {
        state = AppState()
        save()
    }
}
