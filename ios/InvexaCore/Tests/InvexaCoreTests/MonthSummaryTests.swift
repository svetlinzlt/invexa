import Foundation
import Testing
@testable import InvexaCore

@Suite("Месечна равносметка")
struct MonthSummaryTests {

    /// Централното твърдение на целия продукт. Ако този тест падне,
    /// приложението лъже потребителя за това къде са парите му.
    @Test("Заделеното и инвестираното не влизат в похарченото")
    func movementsAreNotSpending() {
        let august = Fixed.month(2026, 8)
        let flows: [FinancialFlow] = [
            .income(Money(euros: 2340), source: "Заплата", on: Fixed.date(2026, 8, 5)),
            .expense(Money(euros: 312, cents: 80), merchant: "Лидл", on: Fixed.date(2026, 8, 6), category: "groceries"),
            .movement(Money(euros: 500), to: "Спестовна", on: Fixed.date(2026, 8, 7), as: .savings),
            .movement(Money(euros: 200), to: "Trading 212", on: Fixed.date(2026, 8, 8), as: .investment),
            .movement(Money(euros: 150), to: "Кредит", on: Fixed.date(2026, 8, 9), as: .debtRepayment),
        ]

        let summary = MonthSummary(month: august, flows: flows, calendar: Fixed.calendar)

        #expect(summary.spent == Money(euros: 312, cents: 80))
        #expect(summary.saved == Money(euros: 500))
        #expect(summary.invested == Money(euros: 200))
        #expect(summary.debtRepaid == Money(euros: 150))
    }

    @Test("Остатъкът е приходът минус всичко излязло и заделено")
    func remainingAddsUp() {
        let august = Fixed.month(2026, 8)
        let flows: [FinancialFlow] = [
            .income(Money(euros: 2340), source: "Заплата", on: Fixed.date(2026, 8, 5)),
            .expense(Money(euros: 1187, cents: 40), merchant: "Разни", on: Fixed.date(2026, 8, 10)),
            .movement(Money(euros: 500), to: "Спестовна", on: Fixed.date(2026, 8, 11), as: .savings),
        ]

        let summary = MonthSummary(month: august, flows: flows, calendar: Fixed.calendar)

        #expect(summary.remaining == Money(euros: 652, cents: 60))
    }

    @Test("Преводът между собствени сметки не мърда нито едно число")
    func internalTransferIsInvisible() {
        let august = Fixed.month(2026, 8)
        let flows: [FinancialFlow] = [
            .income(Money(euros: 1000), source: "Заплата", on: Fixed.date(2026, 8, 1)),
            .movement(Money(euros: 300), to: "Втора сметка", on: Fixed.date(2026, 8, 2), as: .internalTransfer),
        ]

        let summary = MonthSummary(month: august, flows: flows, calendar: Fixed.calendar)

        #expect(summary.spent == .zero)
        #expect(summary.saved == .zero)
        #expect(summary.remaining == Money(euros: 1000))
    }

    @Test("Записи от други месеци се пренебрегват")
    func othersMonthsAreIgnored() {
        let august = Fixed.month(2026, 8)
        let flows: [FinancialFlow] = [
            .expense(Money(euros: 100), merchant: "Юли", on: Fixed.date(2026, 7, 31)),
            .expense(Money(euros: 50), merchant: "Август", on: Fixed.date(2026, 8, 1)),
            .expense(Money(euros: 100), merchant: "Септември", on: Fixed.date(2026, 9, 1)),
        ]

        let summary = MonthSummary(month: august, flows: flows, calendar: Fixed.calendar)

        #expect(summary.spent == Money(euros: 50))
    }

    @Test("Дневните разходи имат по един ред за всеки ден от месеца")
    func dailyCoversWholeMonth() {
        let february = Fixed.month(2026, 2)
        let summary = MonthSummary(month: february, flows: [], calendar: Fixed.calendar)

        // Извикването стои извън `#expect` нарочно. Макросът разлага
        // извикванията на функции, за да опише израза при провал, а
        // `allSatisfy` е `rethrows` — разширението не слага `try` и
        // компилаторът спира. Изнасянето в променлива го заобикаля.
        let everyDayIsZero = summary.dailySpending.allSatisfy(\.isZero)

        #expect(summary.dailySpending.count == 28)
        #expect(everyDayIsZero)
    }

    @Test("Разходът пада на своя ден, а не на съседния")
    func dailyLandsOnCorrectDay() {
        let august = Fixed.month(2026, 8)
        let flows: [FinancialFlow] = [
            .expense(Money(euros: 34, cents: 20), merchant: "Лидл", on: Fixed.date(2026, 8, 21)),
            .expense(Money(euros: 6, cents: 80), merchant: "Bolt", on: Fixed.date(2026, 8, 21)),
        ]

        let summary = MonthSummary(month: august, flows: flows, calendar: Fixed.calendar)

        #expect(summary.dailySpending[20] == Money(euros: 41))
        #expect(summary.dailySpending[19].isZero)
        #expect(summary.dailySpending[21].isZero)
    }

    @Test("Категориите излизат подредени по големина")
    func categoriesSortedByAmount() {
        let august = Fixed.month(2026, 8)
        let flows: [FinancialFlow] = [
            .expense(Money(euros: 124, cents: 90), merchant: "Bolt", on: Fixed.date(2026, 8, 3), category: "transport"),
            .expense(Money(euros: 312, cents: 80), merchant: "Лидл", on: Fixed.date(2026, 8, 4), category: "groceries"),
            .expense(Money(euros: 280), merchant: "Наем", on: Fixed.date(2026, 8, 1), category: "housing"),
        ]

        let summary = MonthSummary(month: august, flows: flows, calendar: Fixed.calendar)

        #expect(summary.byCategory.map(\.categoryID) == ["groceries", "housing", "transport"])
        #expect(summary.byCategory[0].share > 0.42 && summary.byCategory[0].share < 0.44)
    }

    @Test("Празният месец не дели на нула")
    func emptyMonthIsSafe() {
        let summary = MonthSummary(month: Fixed.month(2026, 8), flows: [], calendar: Fixed.calendar)

        #expect(summary.spent == .zero)
        #expect(summary.remaining == .zero)
        #expect(summary.byCategory.isEmpty)
        #expect(summary.averagePerDay(through: 0) == .zero)
    }

    @Test("Прогнозата стъпва на темпото до момента")
    func projectionUsesPace() {
        let august = Fixed.month(2026, 8)
        let flows = (1...10).map { day in
            FinancialFlow.expense(Money(euros: 10), merchant: "Ден \(day)", on: Fixed.date(2026, 8, day))
        }

        let summary = MonthSummary(month: august, flows: flows, calendar: Fixed.calendar)

        #expect(summary.averagePerDay(through: 10) == Money(euros: 10))
        #expect(summary.projectedTotal(through: 10) == Money(euros: 310))
    }
}
