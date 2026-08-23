import Foundation

/// Повтарящо се плащане — наем, абонамент, сметка.
public struct RecurringRule: Identifiable, Hashable, Codable, Sendable {
    public enum Frequency: String, Codable, Sendable, CaseIterable {
        case weekly
        case monthly
        case yearly
    }

    public let id: UUID
    public var name: String
    public var amount: Money
    public var frequency: Frequency
    /// За месечно: ден от месеца, 1…31. За седмично: ден от седмицата, 1…7,
    /// където 1 е неделя, както ги брои `Calendar`. За годишно: ден от месеца,
    /// а месецът идва от `anchorMonth`.
    public var anchorDay: Int
    /// Само за годишни плащания, 1…12.
    public var anchorMonth: Int?
    public var categoryID: String?
    public var isActive: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        amount: Money,
        frequency: Frequency,
        anchorDay: Int,
        anchorMonth: Int? = nil,
        categoryID: String? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.amount = amount.magnitude
        self.frequency = frequency
        self.anchorDay = anchorDay
        self.anchorMonth = anchorMonth
        self.categoryID = categoryID
        self.isActive = isActive
    }
}

extension RecurringRule {
    /// Следващият падеж строго след дадена дата.
    ///
    /// Месечните плащания с ден 29, 30 или 31 се притеглят към последния ден
    /// на по-късите месеци. Наем с падеж на 31-ви трябва да се плати на 28
    /// февруари, а не да изчезне.
    public func nextDue(after date: Date, in calendar: Calendar = .current) -> Date? {
        guard isActive else { return nil }

        switch frequency {
        case .weekly:
            var parts = DateComponents()
            parts.weekday = min(max(anchorDay, 1), 7)
            return calendar.nextDate(
                after: date,
                matching: parts,
                matchingPolicy: .nextTime
            )

        case .monthly:
            return nextMonthlyDue(after: date, in: calendar)

        case .yearly:
            guard let anchorMonth else { return nil }
            for yearOffset in 0...2 {
                let year = calendar.component(.year, from: date) + yearOffset
                guard let candidate = clampedDate(
                    year: year, month: anchorMonth, day: anchorDay, in: calendar
                ) else { continue }
                if candidate > date { return candidate }
            }
            return nil
        }
    }

    private func nextMonthlyDue(after date: Date, in calendar: Calendar) -> Date? {
        let start = YearMonth(containing: date, in: calendar)
        // Дванайсет опита стигат: месечно плащане винаги пада в следващия
        // месец, а запасът покрива и странни календари.
        for offset in 0...12 {
            let target = start.advanced(by: offset, in: calendar)
            guard let candidate = clampedDate(
                year: target.year, month: target.month, day: anchorDay, in: calendar
            ) else { continue }
            if candidate > date { return candidate }
        }
        return nil
    }

    /// Строи дата, като притегля деня към последния ден от месеца, ако
    /// исканият ден не съществува в него.
    private func clampedDate(year: Int, month: Int, day: Int, in calendar: Calendar) -> Date? {
        guard let monthValue = YearMonth(year: year, month: month) else { return nil }
        let lastDay = monthValue.dayCount(in: calendar)
        let safeDay = min(max(day, 1), lastDay)
        return calendar.date(from: DateComponents(year: year, month: month, day: safeDay))
    }

    /// Пада ли този разход в дадения месец и на коя дата.
    public func due(in month: YearMonth, calendar: Calendar = .current) -> [Date] {
        guard isActive else { return [] }
        var results: [Date] = []
        var cursor = calendar.date(byAdding: .day, value: -1, to: month.startDate(in: calendar))
            ?? month.startDate(in: calendar)

        while let next = nextDue(after: cursor, in: calendar), next < month.endDate(in: calendar) {
            if month.contains(next, in: calendar) { results.append(next) }
            cursor = next
        }
        return results
    }
}

extension Collection where Element == RecurringRule {
    /// Общата месечна тежест на всички повтарящи се плащания, приведена към
    /// един месец. Седмичните се броят по 4,33 пъти — средният брой седмици
    /// в месец, а не 4, което би подценило сумата с цял месец за година.
    public func monthlyLoad() -> Money {
        let minorUnits = reduce(0) { total, rule in
            guard rule.isActive else { return total }
            switch rule.frequency {
            case .monthly: return total + rule.amount.minorUnits
            case .weekly:  return total + Int((Double(rule.amount.minorUnits) * 52.0 / 12.0).rounded())
            case .yearly:  return total + Int((Double(rule.amount.minorUnits) / 12.0).rounded())
            }
        }
        return Money(minorUnits: minorUnits)
    }
}
