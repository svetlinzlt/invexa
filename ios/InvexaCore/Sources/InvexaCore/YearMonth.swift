import Foundation

/// Месец като стойност — годината и месецът, без ден и без часова зона.
///
/// Целият продукт се върти около месеца, затова той заслужава собствен тип.
/// Ако месецът е просто `Date`, рано или късно някой го сравнява с точност
/// до секундата и краят на месеца започва да се държи странно.
public struct YearMonth: Hashable, Codable, Sendable, Comparable {
    public let year: Int
    /// 1…12
    public let month: Int

    public init?(year: Int, month: Int) {
        guard (1...12).contains(month) else { return nil }
        self.year = year
        self.month = month
    }

    public init(containing date: Date, in calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.year, .month], from: date)
        self.year = parts.year ?? 1970
        self.month = parts.month ?? 1
    }

    public static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }
}

extension YearMonth {
    public func startDate(in calendar: Calendar = .current) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? .distantPast
    }

    /// Първият миг на следващия месец. Използва се като горна граница при
    /// филтриране — интервалът е полуотворен, за да не изпусне последната
    /// секунда на месеца.
    public func endDate(in calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .month, value: 1, to: startDate(in: calendar)) ?? .distantFuture
    }

    public func dayCount(in calendar: Calendar = .current) -> Int {
        calendar.range(of: .day, in: .month, for: startDate(in: calendar))?.count ?? 30
    }

    public func contains(_ date: Date, in calendar: Calendar = .current) -> Bool {
        date >= startDate(in: calendar) && date < endDate(in: calendar)
    }

    public func advanced(by months: Int, in calendar: Calendar = .current) -> YearMonth {
        let moved = calendar.date(byAdding: .month, value: months, to: startDate(in: calendar))
        return YearMonth(containing: moved ?? startDate(in: calendar), in: calendar)
    }

    public var previous: YearMonth { advanced(by: -1) }
    public var next: YearMonth { advanced(by: 1) }

    /// Кой ден от месеца е тази дата, 1-базирано. `nil`, ако датата е извън
    /// месеца.
    public func dayIndex(of date: Date, in calendar: Calendar = .current) -> Int? {
        guard contains(date, in: calendar) else { return nil }
        return calendar.component(.day, from: date)
    }
}
