import Foundation
import UserNotifications

enum NotificationManager {
    private static let dailyFactID = "smokeless.dailyfact"

    static func requestAndScheduleDailyFact(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    scheduleDailyFact()
                }
                completion(granted)
            }
        }
    }

    /// One notification every morning at 9:00 pointing at today's fact.
    static func scheduleDailyFact() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyFactID])

        let content = UNMutableNotificationContent()
        content.title = "SmokeLess daily check-in"
        content.body = "Your streak is growing. Open today's fact about what smoking really costs you."
        content.sound = .default

        var components = DateComponents()
        components.hour = 9
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: dailyFactID, content: content, trigger: trigger)
        center.add(request)
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
