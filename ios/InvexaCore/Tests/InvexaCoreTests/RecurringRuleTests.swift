import Foundation
import Testing
@testable import InvexaCore

@Suite("Повтарящи се плащания")
struct RecurringRuleTests {

    private func rent(day: Int) -> RecurringRule {
        RecurringRule(
            name: "Наем",
            amount: Money(euros: 280),
            frequency: .monthly,
            anchorDay: day,
            categoryID: "housing"
        )
    }

    @Test("Месечният падеж отива в следващия месец")
    func monthlyMovesForward() {
        let due = rent(day: 1).nextDue(after: Fixed.date(2026, 8, 15), in: Fixed.calendar)
        #expect(due == Fixed.calendar.date(from: DateComponents(year: 2026, month: 9, day: 1)))
    }

    @Test("Падеж по-късно в същия месец не прескача напред")
    func laterInSameMonth() {
        let due = rent(day: 28).nextDue(after: Fixed.date(2026, 8, 15), in: Fixed.calendar)
        #expect(due == Fixed.calendar.date(from: DateComponents(year: 2026, month: 8, day: 28)))
    }

    /// Ръбът, който чупи повечето прости реализации: 31-ви февруари не
    /// съществува, но наемът пак трябва да се плати.
    @Test("Падеж на 31-ви се притегля към последния ден на февруари")
    func day31ClampsInFebruary() {
        let due = rent(day: 31).nextDue(after: Fixed.date(2026, 1, 31), in: Fixed.calendar)
        #expect(due == Fixed.calendar.date(from: DateComponents(year: 2026, month: 2, day: 28)))
    }

    @Test("Високосната година дава 29 февруари")
    func leapYearGives29() {
        let due = rent(day: 31).nextDue(after: Fixed.date(2028, 1, 31), in: Fixed.calendar)
        #expect(due == Fixed.calendar.date(from: DateComponents(year: 2028, month: 2, day: 29)))
    }

    @Test("Спряното плащане няма следващ падеж")
    func inactiveHasNoDueDate() {
        var rule = rent(day: 1)
        rule.isActive = false
        #expect(rule.nextDue(after: Fixed.date(2026, 8, 15), in: Fixed.calendar) == nil)
    }

    @Test("Падежите в даден месец се намират точно")
    func dueDatesWithinMonth() {
        let dates = rent(day: 15).due(in: Fixed.month(2026, 8), calendar: Fixed.calendar)
        #expect(dates.count == 1)
        #expect(Fixed.calendar.component(.day, from: dates[0]) == 15)
    }

    @Test("Седмичното плащане пада няколко пъти в месеца")
    func weeklyRepeatsWithinMonth() {
        let rule = RecurringRule(
            name: "Фитнес",
            amount: Money(euros: 10),
            frequency: .weekly,
            anchorDay: 2  // понеделник
        )
        let dates = rule.due(in: Fixed.month(2026, 8), calendar: Fixed.calendar)
        #expect(dates.count >= 4 && dates.count <= 5)
    }

    @Test("Годишното плащане се връща след цяла година")
    func yearlyRepeats() {
        let rule = RecurringRule(
            name: "Застраховка",
            amount: Money(euros: 240),
            frequency: .yearly,
            anchorDay: 10,
            anchorMonth: 3
        )
        let due = rule.nextDue(after: Fixed.date(2026, 8, 1), in: Fixed.calendar)
        #expect(due == Fixed.calendar.date(from: DateComponents(year: 2027, month: 3, day: 10)))
    }

    /// Седмичните се привеждат по 52/12, а не по 4. Разликата е цял месец
    /// разход за година.
    @Test("Месечната тежест привежда седмичните и годишните вярно")
    func monthlyLoadConverts() {
        let rules = [
            RecurringRule(name: "Наем", amount: Money(euros: 280), frequency: .monthly, anchorDay: 1),
            RecurringRule(name: "Кафе", amount: Money(euros: 10), frequency: .weekly, anchorDay: 2),
            RecurringRule(name: "Застраховка", amount: Money(euros: 240), frequency: .yearly, anchorDay: 10, anchorMonth: 3),
        ]

        // 280,00 + (10,00 × 52 ÷ 12 = 43,33) + (240,00 ÷ 12 = 20,00)
        #expect(rules.monthlyLoad() == Money(euros: 343, cents: 33))
    }

    @Test("Спрените плащания не се броят в месечната тежест")
    func inactiveExcludedFromLoad() {
        var stopped = rent(day: 1)
        stopped.isActive = false
        #expect([stopped].monthlyLoad() == .zero)
    }
}
