import Foundation
import Testing
@testable import InvexaCore

@Suite("Дневник по дни")
struct DaySectionTests {

    @Test("Записите се групират по ден, най-новият отгоре")
    func groupsNewestFirst() {
        let flows: [FinancialFlow] = [
            .expense(Money(euros: 10), merchant: "Вчера", on: Fixed.date(2026, 8, 20)),
            .expense(Money(euros: 20), merchant: "Днес", on: Fixed.date(2026, 8, 21)),
            .expense(Money(euros: 30), merchant: "Онзи ден", on: Fixed.date(2026, 8, 19)),
        ]

        let days = DaySection.group(flows, calendar: Fixed.calendar)

        #expect(days.count == 3)
        #expect(days[0].flows[0].merchant == "Днес")
        #expect(days[2].flows[0].merchant == "Онзи ден")
    }

    @Test("Няколко записа в един ден стоят заедно")
    func sameDayStaysTogether() {
        let flows: [FinancialFlow] = [
            .expense(Money(euros: 34, cents: 20), merchant: "Лидл", on: Fixed.date(2026, 8, 21)),
            .expense(Money(euros: 6, cents: 80), merchant: "Bolt", on: Fixed.date(2026, 8, 21)),
        ]

        let days = DaySection.group(flows, calendar: Fixed.calendar)

        #expect(days.count == 1)
        #expect(days[0].spent == Money(euros: 41))
    }

    @Test("Движенията не влизат в дневната сума")
    func movementsExcludedFromDayTotal() {
        let flows: [FinancialFlow] = [
            .expense(Money(euros: 20), merchant: "Обяд", on: Fixed.date(2026, 8, 21)),
            .movement(Money(euros: 500), to: "Спестовна", on: Fixed.date(2026, 8, 21), as: .savings),
        ]

        let days = DaySection.group(flows, calendar: Fixed.calendar)

        #expect(days[0].spent == Money(euros: 20))
        #expect(days[0].net == Money(euros: -20))
    }

    @Test("Ден със заплата излиза на плюс")
    func salaryDayIsPositive() {
        let flows: [FinancialFlow] = [
            .income(Money(euros: 1170), source: "Заплата", on: Fixed.date(2026, 8, 18)),
            .expense(Money(euros: 20), merchant: "Обяд", on: Fixed.date(2026, 8, 18)),
        ]

        let days = DaySection.group(flows, calendar: Fixed.calendar)

        #expect(days[0].net == Money(euros: 1150))
        #expect(days[0].received == Money(euros: 1170))
    }

    @Test("Празен списък дава празен дневник")
    func emptyIsEmpty() {
        #expect(DaySection.group([], calendar: Fixed.calendar).isEmpty)
    }
}

@Suite("Предстоящи падежи")
struct ScheduleTests {

    private var rules: [RecurringRule] {
        [
            RecurringRule(name: "Netflix", amount: Money(euros: 12, cents: 99), frequency: .monthly, anchorDay: 24),
            RecurringRule(name: "iCloud+", amount: Money(euros: 2, cents: 99), frequency: .monthly, anchorDay: 26),
            RecurringRule(name: "Наем", amount: Money(euros: 280), frequency: .monthly, anchorDay: 1),
        ]
    }

    @Test("Падежите излизат подредени по дата")
    func sortedByDate() {
        let charges = Schedule.upcoming(
            rules: rules,
            after: Fixed.date(2026, 8, 21),
            until: Fixed.date(2026, 9, 5),
            calendar: Fixed.calendar
        )

        #expect(charges.map(\.rule.name) == ["Netflix", "iCloud+", "Наем"])
    }

    @Test("До края на месеца се брои само това, което още не е излязло")
    func remainingExcludesPast() {
        // На 21 август остават Netflix на 24-ти и iCloud+ на 26-ти.
        // Наемът е на 1-ви и вече е платен.
        let remaining = Schedule.remainingThisMonth(
            rules: rules,
            from: Fixed.date(2026, 8, 21),
            calendar: Fixed.calendar
        )

        #expect(remaining == Money(euros: 15, cents: 98))
    }

    @Test("Спрените правила не се показват")
    func inactiveHidden() {
        var stopped = rules
        stopped[0].isActive = false

        let charges = Schedule.upcoming(
            rules: stopped,
            after: Fixed.date(2026, 8, 21),
            until: Fixed.date(2026, 9, 5),
            calendar: Fixed.calendar
        )

        #expect(!charges.contains { $0.rule.name == "Netflix" })
    }

    @Test("Седмичното правило пада няколко пъти в отрязъка")
    func weeklyRepeats() {
        let weekly = [
            RecurringRule(name: "Фитнес", amount: Money(euros: 10), frequency: .weekly, anchorDay: 2)
        ]

        let charges = Schedule.upcoming(
            rules: weekly,
            after: Fixed.date(2026, 8, 1),
            until: Fixed.date(2026, 9, 1),
            calendar: Fixed.calendar
        )

        #expect(charges.count >= 4 && charges.count <= 5)
    }

    @Test("Границата на брой падежи се спазва")
    func limitIsRespected() {
        let weekly = [
            RecurringRule(name: "Всяка седмица", amount: Money(euros: 1), frequency: .weekly, anchorDay: 2)
        ]

        let charges = Schedule.upcoming(
            rules: weekly,
            after: Fixed.date(2026, 1, 1),
            until: Fixed.date(2026, 12, 31),
            calendar: Fixed.calendar,
            limitPerRule: 3
        )

        #expect(charges.count == 3)
    }

    @Test("Едно правило с два падежа има различни идентификатори")
    func chargesAreDistinct() {
        let weekly = [
            RecurringRule(name: "Фитнес", amount: Money(euros: 10), frequency: .weekly, anchorDay: 2)
        ]

        let charges = Schedule.upcoming(
            rules: weekly,
            after: Fixed.date(2026, 8, 1),
            until: Fixed.date(2026, 9, 1),
            calendar: Fixed.calendar
        )

        #expect(Set(charges.map(\.id)).count == charges.count)
    }

    @Test("Броят дни до падежа се смята по календарни дни")
    func daysAwayCountsCalendarDays() {
        let charge = UpcomingCharge(
            rule: rules[0],
            dueDate: Fixed.date(2026, 8, 24)
        )

        #expect(charge.daysAway(from: Fixed.date(2026, 8, 21), calendar: Fixed.calendar) == 3)
    }
}
