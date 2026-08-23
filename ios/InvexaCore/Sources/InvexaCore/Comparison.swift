import Foundation

/// Един месец в сравнението.
public struct MonthPoint: Identifiable, Hashable, Sendable {
    public let month: YearMonth
    /// Похарченото за целия месец. За текущия месец това е сумата дотук.
    public let spent: Money
    /// Похарченото до определен ден включително. Това число прави
    /// сравнението честно.
    public let spentThroughDay: Money

    public var id: YearMonth { month }
}

/// Промяна в една категория спрямо предходния месец.
public struct CategoryDelta: Identifiable, Hashable, Sendable {
    public let categoryID: String
    public let current: Money
    public let previous: Money

    public var id: String { categoryID }
    public var delta: Money { current - previous }
    public var isIncrease: Bool { delta.minorUnits > 0 }
}

public struct MonthComparison: Sendable {
    /// Най-старият месец е първи — така се чете отляво надясно като графика.
    public let points: [MonthPoint]
    public let current: MonthPoint
    public let previous: MonthPoint?

    /// Разликата спрямо предходния месец **на същия ден**.
    public let delta: Money

    /// Средно за завършените месеци.
    ///
    /// Текущият месец нарочно не влиза: той е непълен и би дръпнал средното
    /// надолу, което кара всеки месец да изглежда по-добър, отколкото е.
    public let averageOfCompleted: Money

    public let categoryDeltas: [CategoryDelta]

    /// Най-високата стойност в графиката — мащабът на стълбовете.
    public var peak: Money {
        points.map(\.spent).max() ?? .zero
    }
}

public enum Comparison {

    /// Сглобява сравнението за последните `monthCount` месеца.
    ///
    /// `throughDay` е денят, до който се брои при честното сравнение —
    /// обикновено днешният. Сравняването на пълен месец срещу непълен винаги
    /// показва подобрение, което не съществува.
    public static func build(
        flows: [FinancialFlow],
        endingAt month: YearMonth,
        throughDay: Int,
        monthCount: Int = 6,
        calendar: Calendar = .current
    ) -> MonthComparison {
        let span = max(1, monthCount)

        let points: [MonthPoint] = (0..<span).reversed().map { offset in
            let target = month.advanced(by: -offset, in: calendar)
            let expenses = flows.filter {
                $0.kind == .expense && target.contains($0.date, in: calendar)
            }

            let total = expenses.reduce(0) { $0 + $1.amount.minorUnits }
            let toDay = expenses
                .filter { calendar.component(.day, from: $0.date) <= throughDay }
                .reduce(0) { $0 + $1.amount.minorUnits }

            return MonthPoint(
                month: target,
                spent: Money(minorUnits: total),
                spentThroughDay: Money(minorUnits: toDay)
            )
        }

        let current = points[points.count - 1]
        let previous = points.count > 1 ? points[points.count - 2] : nil

        let completed = points.dropLast()
        let average = completed.isEmpty
            ? Money.zero
            : Money(minorUnits: completed.reduce(0) { $0 + $1.spent.minorUnits } / completed.count)

        return MonthComparison(
            points: points,
            current: current,
            previous: previous,
            delta: current.spentThroughDay - (previous?.spentThroughDay ?? .zero),
            averageOfCompleted: average,
            categoryDeltas: deltas(
                flows: flows,
                current: current.month,
                previous: previous?.month,
                throughDay: throughDay,
                calendar: calendar
            )
        )
    }

    private static func deltas(
        flows: [FinancialFlow],
        current: YearMonth,
        previous: YearMonth?,
        throughDay: Int,
        calendar: Calendar
    ) -> [CategoryDelta] {
        guard let previous else { return [] }

        func totals(for month: YearMonth) -> [String: Int] {
            var result: [String: Int] = [:]
            for flow in flows where flow.kind == .expense
                && month.contains(flow.date, in: calendar)
                && calendar.component(.day, from: flow.date) <= throughDay {
                result[flow.categoryID ?? SpendingCategory.fallbackID, default: 0] += flow.amount.minorUnits
            }
            return result
        }

        let now = totals(for: current)
        let before = totals(for: previous)

        return Set(now.keys).union(before.keys)
            .map { key in
                CategoryDelta(
                    categoryID: key,
                    current: Money(minorUnits: now[key] ?? 0),
                    previous: Money(minorUnits: before[key] ?? 0)
                )
            }
            .filter { !$0.delta.isZero }
            // Най-голямата промяна отгоре, без значение в коя посока —
            // спестените 94 € са толкова интересни, колкото похарчените 48.
            .sorted { abs($0.delta.minorUnits) > abs($1.delta.minorUnits) }
    }
}
