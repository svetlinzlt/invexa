import Foundation

/// Сумата за една категория през месеца.
public struct CategoryTotal: Hashable, Sendable {
    public let categoryID: String
    public let amount: Money
    /// Дял от общо похарченото, 0…1.
    public let share: Double
}

/// Всичко, което началният екран показва, сметнато на едно място.
///
/// Изчислява се от записите, не се пази: така е невъзможно да се разсинхронизира
/// с дневника, а един месец с няколкостотин записа се смята за части от
/// милисекундата.
public struct MonthSummary: Sendable {
    public let month: YearMonth

    public let income: Money
    public let spent: Money
    public let saved: Money
    public let invested: Money
    public let debtRepaid: Money

    /// Похарченото по дни, индекс 0 = първи ден от месеца. Това храни
    /// кривата на началния екран, виджета и часовника.
    public let dailySpending: [Money]

    /// Категориите, подредени по големина.
    public let byCategory: [CategoryTotal]

    /// Каквото е останало от приходите, след като извадим всичко излязло и
    /// всичко заделено.
    ///
    /// Заделеното се вади, защото вече не е на разположение за харчене — но
    /// се вади **отделно** от похарченото, за да не изглежда като разход.
    public var remaining: Money {
        income - spent - saved - invested - debtRepaid
    }

    /// Среден дневен разход за изтеклите дни. Прогнозата за края на месеца
    /// стъпва на него.
    public func averagePerDay(through day: Int) -> Money {
        let days = max(1, min(day, dailySpending.count))
        return Money(minorUnits: spent.minorUnits / days)
    }

    /// Проекция накъде върви месецът при същото темпо.
    public func projectedTotal(through day: Int) -> Money {
        let perDay = averagePerDay(through: day)
        return Money(minorUnits: perDay.minorUnits * dailySpending.count)
    }
}

extension MonthSummary {
    public init(
        month: YearMonth,
        flows: [FinancialFlow],
        calendar: Calendar = .current
    ) {
        self.month = month

        let dayCount = month.dayCount(in: calendar)
        var daily = [Int](repeating: 0, count: dayCount)

        var income = 0
        var spent = 0
        var saved = 0
        var invested = 0
        var debtRepaid = 0
        var perCategory: [String: Int] = [:]

        for flow in flows where month.contains(flow.date, in: calendar) {
            let value = flow.amount.minorUnits

            switch flow.kind {
            case .income:
                income += value

            case .expense:
                spent += value
                perCategory[flow.categoryID ?? SpendingCategory.fallbackID, default: 0] += value
                if let day = month.dayIndex(of: flow.date, in: calendar) {
                    daily[day - 1] += value
                }

            case .movement:
                switch flow.movement ?? .internalTransfer {
                case .savings: saved += value
                case .investment: invested += value
                case .debtRepayment: debtRepaid += value
                case .internalTransfer: break  // между твои сметки — нищо не влиза и нищо не излиза
                }
            }
        }

        self.income = Money(minorUnits: income)
        self.spent = Money(minorUnits: spent)
        self.saved = Money(minorUnits: saved)
        self.invested = Money(minorUnits: invested)
        self.debtRepaid = Money(minorUnits: debtRepaid)
        self.dailySpending = daily.map(Money.init(minorUnits:))

        let order = Dictionary(
            uniqueKeysWithValues: SpendingCategory.defaults.map { ($0.id, $0.order) }
        )

        self.byCategory = perCategory
            .map { key, value in
                CategoryTotal(
                    categoryID: key,
                    amount: Money(minorUnits: value),
                    share: spent == 0 ? 0 : Double(value) / Double(spent)
                )
            }
            .sorted { left, right in
                if left.amount != right.amount { return left.amount > right.amount }
                // При равни суми подреждаме предвидимо, а не както дойде от речника.
                return (order[left.categoryID] ?? .max) < (order[right.categoryID] ?? .max)
            }
    }
}
