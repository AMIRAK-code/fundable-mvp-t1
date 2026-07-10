import Foundation
import UserNotifications

/// Local notifications: the weekly "reset your space" nudge and an optional
/// morning kickoff. Settings toggles are read from UserDefaults so the same
/// keys back the @AppStorage properties in SettingsView.
enum NotificationService {
    static let cleaningReminderID = "weekly-cleaning-reminder"
    static let morningKickoffID = "morning-kickoff"

    enum Keys {
        static let cleaningEnabled = "weeklyCleaningReminder"
        static let cleaningWeekday = "cleaningWeekday" // 1 = Sunday … 7 = Saturday
        static let morningKickoff = "morningKickoff"
    }

    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        default:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        }
    }

    /// Re-applies all schedules based on current settings.
    static func syncSchedules() async {
        let defaults = UserDefaults.standard
        let cleaningEnabled = defaults.object(forKey: Keys.cleaningEnabled) as? Bool ?? true
        let weekday = defaults.object(forKey: Keys.cleaningWeekday) as? Int ?? 1
        let kickoffEnabled = defaults.bool(forKey: Keys.morningKickoff)

        if cleaningEnabled {
            await scheduleWeeklyCleaningReminder(weekday: weekday)
        } else {
            cancel(id: cleaningReminderID)
        }
        if kickoffEnabled {
            await scheduleMorningKickoff()
        } else {
            cancel(id: morningKickoffID)
        }
    }

    static func scheduleWeeklyCleaningReminder(weekday: Int, hour: Int = 10) async {
        let content = UNMutableNotificationContent()
        content.title = "Reset your space 🧹"
        content.body = "A clean room is a clean mind. Take 20 minutes to reset your space — then check it off in Dream Chaser."
        content.sound = .default

        var components = DateComponents()
        components.weekday = weekday
        components.hour = hour
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: cleaningReminderID, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    static func scheduleMorningKickoff(hour: Int = 7) async {
        let content = UNMutableNotificationContent()
        content.title = "Chase it. 🔥"
        content.body = QuoteStore.shared.todaysQuote().text
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: morningKickoffID, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    static func cancel(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}
