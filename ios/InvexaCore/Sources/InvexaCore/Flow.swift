import Foundation

/// Посоката на едно движение на пари.
///
/// Това е централното решение в целия продукт. Повечето прости тракери имат
/// само „разход“ и „приход“, затова вноската от 500 € към брокера влиза при
/// разходите и приложението докладва, че си похарчил пари, които всъщност
/// още са твои. Тук парите между собствени сметки са трети вид и никога не
/// влизат в „похарчено този месец“.
public enum FlowKind: String, Codable, Sendable, CaseIterable {
    /// Парите напускат бюджета — храна, наем, гориво.
    case expense
    /// Парите влизат — заплата, дивидент, върнат заем.
    case income
    /// Парите се местят между твои сметки. Не са разход.
    case movement
}

/// Какъв вид движение е, когато `FinancialFlow` е `.movement`.
///
/// Разграничението не е педантичност: началният екран показва „заделени“ и
/// „инвестирани“ като отделни редове до „похарчено“, а погасяването на
/// кредит намалява задължение, не купува нищо.
public enum MovementKind: String, Codable, Sendable, CaseIterable {
    case savings
    case investment
    case debtRepayment
    case internalTransfer
}

extension FlowKind {
    /// Влиза ли този вид в сумата „похарчено този месец“.
    public var countsAsSpending: Bool { self == .expense }
}

extension MovementKind {
    /// Показва ли се като отделен ред на началния екран.
    public var isHighlightedOnHome: Bool {
        switch self {
        case .savings, .investment: true
        case .debtRepayment, .internalTransfer: false
        }
    }

    /// Името за показване. Живее тук, а не в екраните, защото се появява на
    /// три места и не бива да се разминава между тях.
    public var name: String {
        String(
            localized: String.LocalizationValue("movement.\(rawValue)"),
            bundle: .module,
            comment: "Вид движение на пари между собствени сметки"
        )
    }
}
