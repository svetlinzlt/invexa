import Foundation

/// Един ден от дневника със записите в него.
public struct DaySection: Identifiable, Hashable, Sendable {
    /// Началото на деня, в местния календар.
    public let date: Date
    public let flows: [FinancialFlow]

    public var id: Date { date }

    /// Похарченото този ден. Движенията между собствени сметки не влизат —
    /// същото правило като в месечната равносметка.
    public var spent: Money {
        Money(minorUnits: flows.filter { $0.kind == .expense }
            .reduce(0) { $0 + $1.amount.minorUnits })
    }

    public var received: Money {
        Money(minorUnits: flows.filter { $0.kind == .income }
            .reduce(0) { $0 + $1.amount.minorUnits })
    }

    /// Каквото денят е добавил или отнел. Положително значи, че в този ден
    /// е влязло повече, отколкото е излязло.
    public var net: Money { received - spent }
}

extension DaySection {
    /// Подрежда записите по дни, най-новият ден отгоре, а вътре в деня —
    /// най-новият запис отгоре.
    public static func group(
        _ flows: [FinancialFlow],
        calendar: Calendar = .current
    ) -> [DaySection] {
        Dictionary(grouping: flows) { calendar.startOfDay(for: $0.date) }
            .map { day, items in
                DaySection(date: day, flows: items.sorted { $0.date > $1.date })
            }
            .sorted { $0.date > $1.date }
    }
}

/// Предстоящо плащане по повтарящо се правило.
public struct UpcomingCharge: Identifiable, Hashable, Sendable {
    public let rule: RecurringRule
    public let dueDate: Date

    /// Едно правило може да падне няколко пъти в даден отрязък — седмичните
    /// падат по четири-пет пъти в месец — затова идентификаторът включва и
    /// датата.
    public var id: String {
        "\(rule.id.uuidString)@\(Int(dueDate.timeIntervalSince1970))"
    }

    public func daysAway(from date: Date = .now, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: date)
        let due = calendar.startOfDay(for: dueDate)
        return calendar.dateComponents([.day], from: start, to: due).day ?? 0
    }
}

public enum Schedule {
    /// Всички падежи в отрязък, подредени по дата.
    ///
    /// Границата на итерациите не е предпазливост заради предпазливост:
    /// седмично правило в дълъг отрязък може да върне много записи, а
    /// екранът показва само следващите няколко.
    public static func upcoming(
        rules: [RecurringRule],
        after start: Date,
        until end: Date,
        calendar: Calendar = .current,
        limitPerRule: Int = 8
    ) -> [UpcomingCharge] {
        var result: [UpcomingCharge] = []

        for rule in rules where rule.isActive {
            var cursor = start
            var found = 0

            while found < limitPerRule,
                  let due = rule.nextDue(after: cursor, in: calendar),
                  due < end {
                result.append(UpcomingCharge(rule: rule, dueDate: due))
                cursor = due
                found += 1
            }
        }

        return result.sorted { $0.dueDate < $1.dueDate }
    }

    /// Колко предстои да излезе до края на месеца.
    public static func remainingThisMonth(
        rules: [RecurringRule],
        from date: Date = .now,
        calendar: Calendar = .current
    ) -> Money {
        let month = YearMonth(containing: date, in: calendar)
        let charges = upcoming(
            rules: rules,
            after: date,
            until: month.endDate(in: calendar),
            calendar: calendar
        )
        return Money(minorUnits: charges.reduce(0) { $0 + $1.rule.amount.minorUnits })
    }
}
