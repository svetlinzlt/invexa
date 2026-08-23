import Foundation
import Testing
@testable import InvexaCore

@Suite("Сравнение месец до месец")
struct ComparisonTests {

    /// Ако сравняваш пълен юли срещу непълен август, август винаги печели.
    /// Тестът пази точно това: разликата се смята на същия ден.
    @Test("Сравнява се на същия ден от месеца, не пълен срещу непълен")
    func comparesAtSameDayOfMonth() {
        let flows: [FinancialFlow] = [
            // Юли: 100 до 10-ти, още 900 след това.
            .expense(Money(euros: 100), merchant: "Юли рано", on: Fixed.date(2026, 7, 5)),
            .expense(Money(euros: 900), merchant: "Юли късно", on: Fixed.date(2026, 7, 25)),
            // Август: 150 до 10-ти.
            .expense(Money(euros: 150), merchant: "Август", on: Fixed.date(2026, 8, 8)),
        ]

        let result = Comparison.build(
            flows: flows,
            endingAt: Fixed.month(2026, 8),
            throughDay: 10,
            monthCount: 2,
            calendar: Fixed.calendar
        )

        // Честното сравнение: 150 срещу 100, тоест 50 € повече.
        #expect(result.delta == Money(euros: 50))
        // А стълбовете показват истинските месеци.
        #expect(result.points[0].spent == Money(euros: 1000))
        #expect(result.points[1].spent == Money(euros: 150))
    }

    @Test("Средното пропуска текущия месец, защото е непълен")
    func averageSkipsCurrentMonth() {
        let flows: [FinancialFlow] = [
            .expense(Money(euros: 1000), merchant: "Юни", on: Fixed.date(2026, 6, 10)),
            .expense(Money(euros: 1400), merchant: "Юли", on: Fixed.date(2026, 7, 10)),
            .expense(Money(euros: 100), merchant: "Август дотук", on: Fixed.date(2026, 8, 2)),
        ]

        let result = Comparison.build(
            flows: flows,
            endingAt: Fixed.month(2026, 8),
            throughDay: 21,
            monthCount: 3,
            calendar: Fixed.calendar
        )

        // (1000 + 1400) ÷ 2, а не ÷ 3.
        #expect(result.averageOfCompleted == Money(euros: 1200))
    }

    @Test("Движенията не влизат в сравнението")
    func movementsExcluded() {
        let flows: [FinancialFlow] = [
            .expense(Money(euros: 100), merchant: "Обяд", on: Fixed.date(2026, 8, 5)),
            .movement(Money(euros: 500), to: "Спестовна", on: Fixed.date(2026, 8, 6), as: .savings),
            .income(Money(euros: 2000), source: "Заплата", on: Fixed.date(2026, 8, 7)),
        ]

        let result = Comparison.build(
            flows: flows,
            endingAt: Fixed.month(2026, 8),
            throughDay: 21,
            monthCount: 1,
            calendar: Fixed.calendar
        )

        #expect(result.current.spent == Money(euros: 100))
    }

    @Test("Месеците излизат подредени от най-стария към най-новия")
    func pointsAreChronological() {
        let result = Comparison.build(
            flows: [],
            endingAt: Fixed.month(2026, 8),
            throughDay: 21,
            monthCount: 6,
            calendar: Fixed.calendar
        )

        #expect(result.points.count == 6)
        #expect(result.points.first?.month == Fixed.month(2026, 3))
        #expect(result.points.last?.month == Fixed.month(2026, 8))
        #expect(result.current.month == Fixed.month(2026, 8))
    }

    @Test("Месеците без записи дават нули, а не пропуски в графиката")
    func emptyMonthsStillAppear() {
        let flows: [FinancialFlow] = [
            .expense(Money(euros: 50), merchant: "Само август", on: Fixed.date(2026, 8, 3)),
        ]

        let result = Comparison.build(
            flows: flows,
            endingAt: Fixed.month(2026, 8),
            throughDay: 21,
            monthCount: 4,
            calendar: Fixed.calendar
        )

        #expect(result.points.count == 4)
        #expect(result.points[0].spent == .zero)
        #expect(result.peak == Money(euros: 50))
    }

    @Test("Един месец история не чупи нищо")
    func singleMonthIsSafe() {
        let result = Comparison.build(
            flows: [],
            endingAt: Fixed.month(2026, 8),
            throughDay: 21,
            monthCount: 1,
            calendar: Fixed.calendar
        )

        #expect(result.previous == nil)
        #expect(result.delta == .zero)
        #expect(result.averageOfCompleted == .zero)
        #expect(result.categoryDeltas.isEmpty)
    }
}

@Suite("Промени по категории")
struct CategoryDeltaTests {

    private var flows: [FinancialFlow] {
        [
            .expense(Money(euros: 120), merchant: "Заведения юли", on: Fixed.date(2026, 7, 5), category: "eating_out"),
            .expense(Money(euros: 168), merchant: "Заведения август", on: Fixed.date(2026, 8, 5), category: "eating_out"),
            .expense(Money(euros: 160), merchant: "Транспорт юли", on: Fixed.date(2026, 7, 6), category: "transport"),
            .expense(Money(euros: 124), merchant: "Транспорт август", on: Fixed.date(2026, 8, 6), category: "transport"),
            .expense(Money(euros: 90), merchant: "Жилище юли", on: Fixed.date(2026, 7, 1), category: "housing"),
            .expense(Money(euros: 90), merchant: "Жилище август", on: Fixed.date(2026, 8, 1), category: "housing"),
        ]
    }

    @Test("Най-голямата промяна е отгоре, независимо в коя посока")
    func biggestChangeFirst() {
        let result = Comparison.build(
            flows: flows,
            endingAt: Fixed.month(2026, 8),
            throughDay: 21,
            monthCount: 2,
            calendar: Fixed.calendar
        )

        // Транспорт е −36, заведения +48 — заведенията водят по големина.
        #expect(result.categoryDeltas.map(\.categoryID) == ["eating_out", "transport"])
        #expect(result.categoryDeltas[0].delta == Money(euros: 48))
        #expect(result.categoryDeltas[0].isIncrease)
        #expect(result.categoryDeltas[1].delta == Money(euros: -36))
        #expect(!result.categoryDeltas[1].isIncrease)
    }

    @Test("Непроменените категории не заемат място")
    func unchangedCategoriesAreHidden() {
        let result = Comparison.build(
            flows: flows,
            endingAt: Fixed.month(2026, 8),
            throughDay: 21,
            monthCount: 2,
            calendar: Fixed.calendar
        )

        #expect(!result.categoryDeltas.contains { $0.categoryID == "housing" })
    }

    @Test("Нова категория този месец се показва като цял прираст")
    func brandNewCategoryShowsAsFullIncrease() {
        var withNew = flows
        withNew.append(
            .expense(Money(euros: 55), merchant: "Аптека", on: Fixed.date(2026, 8, 9), category: "health")
        )

        let result = Comparison.build(
            flows: withNew,
            endingAt: Fixed.month(2026, 8),
            throughDay: 21,
            monthCount: 2,
            calendar: Fixed.calendar
        )

        let health = result.categoryDeltas.first { $0.categoryID == "health" }
        #expect(health?.previous == .zero)
        #expect(health?.delta == Money(euros: 55))
    }
}
