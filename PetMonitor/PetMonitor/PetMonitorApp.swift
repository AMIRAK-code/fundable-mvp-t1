import SwiftUI
import UserNotifications

@main
struct PetMonitorApp: App {
    @StateObject private var store = PetStore()

    init() {
        UNUserNotificationCenter.current().delegate = NotificationCenterDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
