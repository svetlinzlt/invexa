import Foundation

/// Сума в най-малките единици на валутата — евроцентове.
///
/// Никога `Double`. Числата с плаваща запетая не могат да представят точно
/// 0,10 и при събиране на стотици редове грешката излиза наяве точно там,
/// където потребителят я вижда: в общата сума за месеца.
public struct Money: Hashable, Codable, Sendable, Comparable {
    public let minorUnits: Int

    public init(minorUnits: Int) {
        self.minorUnits = minorUnits
    }

    /// `Money(euros: 34, cents: 20)` е 34,20 €.
    public init(euros: Int, cents: Int = 0) {
        let sign = euros < 0 ? -1 : 1
        self.minorUnits = euros * 100 + sign * abs(cents)
    }

    public static let zero = Money(minorUnits: 0)

    public var isZero: Bool { minorUnits == 0 }
    public var isNegative: Bool { minorUnits < 0 }
    public var magnitude: Money { Money(minorUnits: abs(minorUnits)) }
    public var decimalValue: Decimal { Decimal(minorUnits) / 100 }

    public static func + (lhs: Money, rhs: Money) -> Money {
        Money(minorUnits: lhs.minorUnits + rhs.minorUnits)
    }

    public static func - (lhs: Money, rhs: Money) -> Money {
        Money(minorUnits: lhs.minorUnits - rhs.minorUnits)
    }

    public static prefix func - (value: Money) -> Money {
        Money(minorUnits: -value.minorUnits)
    }

    public static func += (lhs: inout Money, rhs: Money) { lhs = lhs + rhs }
    public static func -= (lhs: inout Money, rhs: Money) { lhs = lhs - rhs }

    public static func < (lhs: Money, rhs: Money) -> Bool {
        lhs.minorUnits < rhs.minorUnits
    }

    /// Дял от друга сума, 0…1. Връща 0, когато основата е нула — така
    /// извикващият код няма нужда да пази срещу деление на нула.
    public func share(of total: Money) -> Double {
        guard total.minorUnits != 0 else { return 0 }
        return Double(minorUnits) / Double(total.minorUnits)
    }
}

extension Money {
    /// Форматирането минава през `FormatStyle`, а не през ръчно сглобяване
    /// на низове: разделителят за хиляди и позицията на знака за валута се
    /// различават по локал, а приложението е двуезично.
    public func formatted(
        currencyCode: String = "EUR",
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        decimalValue.formatted(.currency(code: currencyCode).locale(locale))
    }
}

extension Money {
    /// Единственото място, където число с плаваща запетая се превръща в сума.
    ///
    /// Siri и App Intents подават стойността като `Double` — това е рамката,
    /// не наш избор. Затова закръгляме веднага на входа и нататък в кода
    /// `Double` няма достъп до пари.
    public init(rounding amount: Double) {
        guard amount.isFinite else {
            self.init(minorUnits: 0)
            return
        }
        self.init(minorUnits: Int((amount * 100).rounded()))
    }
}

extension Money {
    /// Разбира и „12“, и „12,50“, и „12.50“, и „1 234,56“.
    ///
    /// Приложението е на български, но клавиатурите пишат ту запетая, ту
    /// точка, а вносът от CSV носи каквото е записала банката.
    public init?(text: String) {
        let cleaned = text
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\u{00A0}", with: "")
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else { return nil }

        let isNegative = cleaned.hasPrefix("-")
        let digits = isNegative ? String(cleaned.dropFirst()) : cleaned
        // Само знак минус, без цифри, не е сума нула — това е празно поле.
        guard !digits.isEmpty else { return nil }

        let parts = digits.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count <= 2 else { return nil }

        let wholePart = parts[0].isEmpty ? "0" : String(parts[0])
        guard let whole = Int(wholePart) else { return nil }

        var cents = 0
        if parts.count == 2 {
            let fraction = parts[1].prefix(2)
            guard !fraction.isEmpty, let value = Int(fraction) else { return nil }
            // „12,5“ значи 12,50, а не 12,05.
            cents = fraction.count == 1 ? value * 10 : value
        }

        let total = whole * 100 + cents
        self.init(minorUnits: isNegative ? -total : total)
    }
}

extension Money: CustomStringConvertible {
    public var description: String { formatted() }
}

extension Sequence where Element == Money {
    public func total() -> Money {
        Money(minorUnits: reduce(0) { $0 + $1.minorUnits })
    }
}
