import SwiftUI

@main
struct SmokeLessApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .tint(store.theme.primary)
                .onAppear {
                    PhoneSyncManager.shared.start(store: store)
                    store.onStateSaved = { _ in
                        PhoneSyncManager.shared.pushState()
                    }
                    if store.state.notificationsEnabled {
                        NotificationManager.scheduleDailyFact()
                    }
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        // Links arrive from widgets: smokeless://sos, smokeless://wishlist, smokeless://home
        switch url.host ?? "" {
        case "sos":
            store.showCravingSOS = true
        case "wishlist":
            store.selectedTab = .wishlist
        default:
            store.selectedTab = .home
        }
    }
}
