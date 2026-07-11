import SwiftUI

@main
struct SmokeLessWatchApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environmentObject(store)
                .tint(store.theme.primary)
                .onAppear {
                    WatchSyncManager.shared.start(store: store)
                }
        }
    }
}
