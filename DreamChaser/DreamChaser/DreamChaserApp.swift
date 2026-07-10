import SwiftData
import SwiftUI
import WidgetKit

@main
struct DreamChaserApp: App {
    private let container = SharedStore.makeContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .task {
                    SharedStore.seedIfNeeded(in: container)
                    if await NotificationService.requestPermission() {
                        await NotificationService.syncSchedules()
                    }
                    await QuoteStore.shared.refreshFromInternet()
                    WidgetCenter.shared.reloadAllTimelines()
                }
        }
        .modelContainer(container)
    }
}
