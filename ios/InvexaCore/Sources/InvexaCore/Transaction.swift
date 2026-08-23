import Foundation

/// Един запис в дневника.
///
/// `amount` е винаги положителна, а посоката живее в `kind`. Знакът върху
/// сумата е класически източник на грешки: достатъчно е един път да
/// забравиш минуса при внасяне на CSV и месецът излиза наопаки.
public struct FinancialFlow: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var date: Date
    public var amount: Money
    public var merchant: String
    public var kind: FlowKind

    /// Попълва се само когато `kind == .movement`.
    public var movement: MovementKind?
    /// Попълва се само когато `kind == .expense`.
    public var categoryID: String?

    public var note: String?
    /// Свързва записа с повтарящо се плащане, ако е породен от такова.
    public var recurringRuleID: UUID?

    public init(
        id: UUID = UUID(),
        date: Date,
        amount: Money,
        merchant: String,
        kind: FlowKind,
        movement: MovementKind? = nil,
        categoryID: String? = nil,
        note: String? = nil,
        recurringRuleID: UUID? = nil
    ) {
        self.id = id
        self.date = date
        self.amount = amount.magnitude
        self.merchant = merchant
        self.kind = kind
        self.movement = kind == .movement ? (movement ?? .internalTransfer) : nil
        self.categoryID = kind == .expense ? (categoryID ?? SpendingCategory.fallbackID) : nil
        self.note = note
        self.recurringRuleID = recurringRuleID
    }
}

extension FinancialFlow {
    public static func expense(
        _ amount: Money,
        merchant: String,
        on date: Date,
        category: String = SpendingCategory.fallbackID
    ) -> FinancialFlow {
        FinancialFlow(date: date, amount: amount, merchant: merchant, kind: .expense, categoryID: category)
    }

    public static func income(
        _ amount: Money,
        source: String,
        on date: Date
    ) -> FinancialFlow {
        FinancialFlow(date: date, amount: amount, merchant: source, kind: .income)
    }

    public static func movement(
        _ amount: Money,
        to destination: String,
        on date: Date,
        as movement: MovementKind
    ) -> FinancialFlow {
        FinancialFlow(date: date, amount: amount, merchant: destination, kind: .movement, movement: movement)
    }
}
