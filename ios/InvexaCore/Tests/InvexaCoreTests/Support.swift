import Foundation
@testable import InvexaCore

/// Тестовете използват фиксиран календар в UTC. Без това резултатите се
/// менят според часовата зона на машината и падат само в чужбина — най-
/// неприятният вид счупен тест.
enum Fixed {
    // `let`, а не `var`: строгата проверка на конкурентността в Swift 6
    // отхвърля глобално изменяемо състояние.
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "bg_BG")
        return calendar
    }()

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    static func month(_ year: Int, _ month: Int) -> YearMonth {
        YearMonth(year: year, month: month)!
    }
}
