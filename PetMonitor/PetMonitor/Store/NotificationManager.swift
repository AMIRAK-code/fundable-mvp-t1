import Foundation
import UserNotifications

/// Schedules the periodic check-in cycle, daily tips, and urgent vet alerts.
///
/// All of these are local notifications. When the iPhone is locked and a
/// paired Apple Watch is on the wrist, iOS mirrors them to the watch
/// automatically — that is how "watch alerts" work here, no watch app needed.
enum NotificationManager {

    private static let checkInIDs = [
        "checkin.morning", "checkin.evening", "checkin.daily",
        "checkin.interval", "checkin.weekly",
    ]
    private static let tipIDPrefix = "dailytip."

    static func requestAuthorization() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func rescheduleAll(settings: AppSettings, pet: Pet?) {
        let center = UNUserNotificationCenter.current()
        var identifiers = checkInIDs
        for offset in 0..<7 {
            identifiers.append("\(tipIDPrefix)\(offset)")
        }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)

        guard let pet else { return }

        if settings.remindersEnabled {
            scheduleCheckInReminders(settings: settings, pet: pet, center: center)
        }
        if settings.dailyTipEnabled {
            scheduleDailyTips(settings: settings, pet: pet, center: center)
        }
    }

    /// Immediate alert used when urgent symptoms are logged or the symptom
    /// checker finds red flags. Mirrors to a paired Apple Watch.
    static func sendVetAlert(petName: String, symptomNames: [String]) {
        let content = UNMutableNotificationContent()
        content.title = "Check on \(petName)"
        content.body = "Signs that need veterinary attention: \(symptomNames.joined(separator: ", ")). Please contact your vet."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(
            identifier: "vetalert.\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Check-in cycle

    private static func scheduleCheckInReminders(settings: AppSettings, pet: Pet, center: UNUserNotificationCenter) {
        let title = "\(pet.name)'s check-in"
        let body = "A calm minute of observation. How is \(pet.name) doing?"

        switch settings.cadence {
        case .morningAndEvening:
            add(id: "checkin.morning", title: title, body: body,
                trigger: dailyTrigger(hour: settings.reminderHour, minute: settings.reminderMinute),
                center: center)
            add(id: "checkin.evening", title: title,
                body: "An evening look before the day winds down. How is \(pet.name)?",
                trigger: dailyTrigger(hour: 19, minute: 30),
                center: center)
        case .daily:
            add(id: "checkin.daily", title: title, body: body,
                trigger: dailyTrigger(hour: settings.reminderHour, minute: settings.reminderMinute),
                center: center)
        case .everyOtherDay:
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2 * 24 * 3_600, repeats: true)
            add(id: "checkin.interval", title: title, body: body, trigger: trigger, center: center)
        case .weekly:
            var components = DateComponents()
            components.weekday = Calendar.current.component(.weekday, from: Date())
            components.hour = settings.reminderHour
            components.minute = settings.reminderMinute
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            add(id: "checkin.weekly", title: title, body: body, trigger: trigger, center: center)
        }
    }

    // MARK: - Daily tips

    /// Tips change every day, so a repeating trigger with static text won't
    /// do. Instead the next 7 days are scheduled individually and refreshed
    /// whenever the app becomes active.
    private static func scheduleDailyTips(settings: AppSettings, pet: Pet, center: UNUserNotificationCenter) {
        let calendar = Calendar.current
        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: Date()) else { continue }
            var components = calendar.dateComponents([.year, .month, .day], from: day)
            components.hour = settings.tipHour
            components.minute = settings.tipMinute
            guard let fireDate = calendar.date(from: components), fireDate > Date() else { continue }

            let tip = TipsLibrary.dailyTip(for: pet.species, on: day)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            add(id: "\(tipIDPrefix)\(offset)",
                title: "Today's \(pet.species.displayName.lowercased()) tip",
                body: tip.text,
                trigger: trigger,
                center: center)
        }
    }

    // MARK: - Helpers

    private static func dailyTrigger(hour: Int, minute: Int) -> UNCalendarNotificationTrigger {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
    }

    private static func add(id: String, title: String, body: String, trigger: UNNotificationTrigger, center: UNUserNotificationCenter) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }
}

/// Shows notification banners even while the app is in the foreground.
final class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationCenterDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
