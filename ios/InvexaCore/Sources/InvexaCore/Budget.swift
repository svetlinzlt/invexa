import Foundation

/// Месечен лимит за една категория.
public struct Budget: Identifiable, Hashable, Codable, Sendable {
    public let categoryID: String
    public var limit: Money

    public var id: String { categoryID }

    public init(categoryID: String, limit: Money) {
        self.categoryID = categoryID
        self.limit = limit.magnitude
    }
}

/// Докъде е стигнала една категория спрямо лимита си.
public struct BudgetStatus: Identifiable, Hashable, Sendable {
    public enum State: String, Sendable {
        /// Под темпото за деня от месеца.
        case comfortable
        /// Над темпото, но още в лимита. Има време да се коригира.
        case ahead
        /// Лимитът е надхвърлен.
        case over
    }

    public let categoryID: String
    public let spent: Money
    public let limit: Money
    public let state: State

    public var id: String { categoryID }

    /// Част от лимита, изразходвана дотук. Може да мине над 1.
    public var share: Double {
        guard limit.minorUnits > 0 else { return 0 }
        return Double(spent.minorUnits) / Double(limit.minorUnits)
    }

    public var remaining: Money { limit - spent }
    public var isOver: Bool { state == .over }
}

extension MonthSummary {
    /// Състоянието на всички зададени лимити.
    ///
    /// Сравнява се с **темпото за деня**, а не с целия лимит: на 5-ти да си
    /// похарчил 40% от месечния лимит е предупреждение, на 25-ти е нормално.
    /// Сравнението с целия лимит би мълчало точно когато има какво да се
    /// направи, и би крещяло, когато вече е късно.
    public func budgetStatuses(
        _ budgets: [Budget],
        through day: Int,
        calendar: Calendar = .current
    ) -> [BudgetStatus] {
        let totals = Dictionary(
            byCategory.map { ($0.categoryID, $0.amount) },
            uniquingKeysWith: { first, _ in first }
        )
        let days = max(1, dailySpending.count)
        let elapsed = min(max(day, 1), days)
        let pace = Double(elapsed) / Double(days)

        return budgets
            .filter { $0.limit.minorUnits > 0 }
            .map { budget in
                let spent = totals[budget.categoryID] ?? .zero
                let expected = Double(budget.limit.minorUnits) * pace

                let state: BudgetStatus.State
                if spent.minorUnits > budget.limit.minorUnits {
                    state = .over
                } else if Double(spent.minorUnits) > expected {
                    state = .ahead
                } else {
                    state = .comfortable
                }

                return BudgetStatus(
                    categoryID: budget.categoryID,
                    spent: spent,
                    limit: budget.limit,
                    state: state
                )
            }
            // Най-напрегнатото отгоре: там има какво да се направи.
            .sorted { $0.share > $1.share }
    }
}
