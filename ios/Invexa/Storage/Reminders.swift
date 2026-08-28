import Foundation
import UserNotifications
import InvexaCore

/// Напомняния за предстоящи плащания.
///
/// Екранът с повтарящите се беше пасивен: показваше какво идва, само ако сам
/// го отвориш. Смисълът е обратният — приложението да каже, преди парите да
/// излязат.
///
/// Известията са **локални**. Няма сървър, няма push, нищо не напуска
/// устройството.
public enum Reminders {

    private static let prefix = "invexa.due."

    /// Пита веднъж. Отказът не се преиграва — човек, който е казал не, не
    /// бива да бъде питан на всяко отваряне.
    public static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional: return true
        case .denied: return false
        default:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        }
    }

    /// Пренасрочва всички напомняния наново.
    ///
    /// Изтрива старите преди това: правило може да е спряно, преименувано или
    /// с друга сума, а остатъчно известие за отменено плащане е по-лошо от
    /// липсващо.
    public static func reschedule(
        rules: [RecurringRule],
        calendar: Calendar = .current
    ) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(
            withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        )

        guard await requestPermission() else { return }

        let horizon = calendar.date(byAdding: .day, value: 60, to: .now) ?? .now
        let charges = Schedule.upcoming(
            rules: rules, after: .now, until: horizon, calendar: calendar, limitPerRule: 2
        )

        for charge in charges.prefix(30) {
            // Сутринта на падежа, не в полунощ: известие в 00:01 се вижда
            // чак на другия ден и вече е закъсняло.
            var when = calendar.dateComponents([.year, .month, .day], from: charge.dueDate)
            when.hour = 9
            guard let fire = calendar.date(from: when), fire > .now else { continue }

            let content = UNMutableNotificationContent()
            content.title = charge.rule.name
            content.body = String(
                localized: "Днес излизат \(charge.rule.amount.formatted())."
            )
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: calendar.dateComponents([.year, .month, .day, .hour], from: fire),
                repeats: false
            )

            try? await center.add(
                UNNotificationRequest(
                    identifier: prefix + charge.id,
                    content: content,
                    trigger: trigger
                )
            )
        }
    }

    public static func cancelAll() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(
            withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        )
    }
}
