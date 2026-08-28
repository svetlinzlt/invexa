import Foundation
import Testing
@testable import InvexaCore

@Suite("Бюджети")
struct BudgetTests {

    private func summary(_ spentInGroceries: Int, day: Int = 15) -> MonthSummary {
        let flows = [
            FinancialFlow.expense(
                Money(euros: spentInGroceries),
                merchant: "Лидл",
                on: Fixed.date(2026, 8, day),
                category: "groceries"
            )
        ]
        return MonthSummary(month: Fixed.month(2026, 8), flows: flows, calendar: Fixed.calendar)
    }

    private let limit = [Budget(categoryID: "groceries", limit: Money(euros: 300))]

    /// Ръбът, заради който сравнението е с темпото, а не с целия лимит.
    /// На 5-ти 40% от месечния лимит е предупреждение; на 25-ти е нормално.
    @Test("Рано в месеца висок дял е предупреждение")
    func earlyHighShareWarns() {
        // 120 от 300 на 5-ти: очакваното темпо е 300 × 5/31 ≈ 48.
        let status = summary(120, day: 5)
            .budgetStatuses(limit, through: 5, calendar: Fixed.calendar)[0]

        #expect(status.state == .ahead)
        #expect(!status.isOver)
    }

    @Test("Късно в месеца същият дял е спокоен")
    func lateSameShareIsFine() {
        // 120 от 300 на 25-ти: очакваното темпо е 300 × 25/31 ≈ 242.
        let status = summary(120, day: 25)
            .budgetStatuses(limit, through: 25, calendar: Fixed.calendar)[0]

        #expect(status.state == .comfortable)
    }

    @Test("Надхвърленият лимит е надхвърлен, независимо от деня")
    func overIsOverWheneverItHappens() {
        let early = summary(310, day: 3)
            .budgetStatuses(limit, through: 3, calendar: Fixed.calendar)[0]
        let late = summary(310, day: 30)
            .budgetStatuses(limit, through: 30, calendar: Fixed.calendar)[0]

        #expect(early.state == .over)
        #expect(late.state == .over)
    }

    @Test("Остатъкът може да стане отрицателен и това е вярно")
    func remainingGoesNegative() {
        let status = summary(340)
            .budgetStatuses(limit, through: 15, calendar: Fixed.calendar)[0]

        #expect(status.remaining == Money(euros: -40))
        #expect(status.share > 1)
    }

    @Test("Категория без разходи стои на нула, а не липсва")
    func untouchedCategoryStillAppears() {
        let budgets = [
            Budget(categoryID: "groceries", limit: Money(euros: 300)),
            Budget(categoryID: "travel", limit: Money(euros: 200)),
        ]
        let statuses = summary(50).budgetStatuses(budgets, through: 15, calendar: Fixed.calendar)

        #expect(statuses.count == 2)
        #expect(statuses.first { $0.categoryID == "travel" }?.spent == .zero)
    }

    @Test("Най-напрегнатото излиза отгоре")
    func mostStrainedFirst() {
        let flows = [
            FinancialFlow.expense(Money(euros: 280), merchant: "Лидл", on: Fixed.date(2026, 8, 5), category: "groceries"),
            FinancialFlow.expense(Money(euros: 20), merchant: "Bolt", on: Fixed.date(2026, 8, 5), category: "transport"),
        ]
        let month = MonthSummary(month: Fixed.month(2026, 8), flows: flows, calendar: Fixed.calendar)
        let statuses = month.budgetStatuses([
            Budget(categoryID: "transport", limit: Money(euros: 200)),
            Budget(categoryID: "groceries", limit: Money(euros: 300)),
        ], through: 5, calendar: Fixed.calendar)

        #expect(statuses[0].categoryID == "groceries")
    }

    @Test("Лимит нула се пренебрегва, вместо да дели на нула")
    func zeroLimitIsIgnored() {
        let statuses = summary(50).budgetStatuses(
            [Budget(categoryID: "groceries", limit: .zero)],
            through: 15, calendar: Fixed.calendar
        )
        #expect(statuses.isEmpty)
    }

    @Test("Отрицателен лимит се приема като положителен")
    func negativeLimitIsNormalised() {
        #expect(Budget(categoryID: "x", limit: Money(euros: -100)).limit == Money(euros: 100))
    }
}
