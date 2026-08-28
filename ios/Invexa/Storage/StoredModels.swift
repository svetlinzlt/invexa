import Foundation
import SwiftData
import InvexaCore

// Съхранението стои отделно от логиката нарочно. `FinancialFlow` от
// InvexaCore е чиста стойност, която не знае нищо за бази данни; тези типове
// знаят само как да я запишат. Ако утре хранилището се смени, логиката и
// тестовете ѝ остават непокътнати.
//
// ВАЖНО за CloudKit: синхронизацията през iCloud изисква всяко свойство да
// има стойност по подразбиране или да е незадължително, и забранява
// `@Attribute(.unique)`. Правилата се спазват от самото начало — иначе
// моделът се пренаписва точно когато вече има потребители с данни.

@Model
public final class StoredFlow {
    public var id: UUID = UUID()
    public var date: Date = Date()
    /// Евроцентове. Целочислено, за да няма грешки от плаваща запетая.
    public var minorUnits: Int = 0
    public var merchant: String = ""
    /// Суров низ от `FlowKind`, за да не се чупи схемата при добавяне на нов вид.
    public var kindRaw: String = FlowKind.expense.rawValue
    public var movementRaw: String?
    public var categoryID: String?
    public var note: String?
    public var recurringRuleID: UUID?

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        minorUnits: Int = 0,
        merchant: String = "",
        kindRaw: String = FlowKind.expense.rawValue,
        movementRaw: String? = nil,
        categoryID: String? = nil,
        note: String? = nil,
        recurringRuleID: UUID? = nil
    ) {
        self.id = id
        self.date = date
        self.minorUnits = minorUnits
        self.merchant = merchant
        self.kindRaw = kindRaw
        self.movementRaw = movementRaw
        self.categoryID = categoryID
        self.note = note
        self.recurringRuleID = recurringRuleID
    }
}

extension StoredFlow {
    public convenience init(_ flow: FinancialFlow) {
        self.init(
            id: flow.id,
            date: flow.date,
            minorUnits: flow.amount.minorUnits,
            merchant: flow.merchant,
            kindRaw: flow.kind.rawValue,
            movementRaw: flow.movement?.rawValue,
            categoryID: flow.categoryID,
            note: flow.note,
            recurringRuleID: flow.recurringRuleID
        )
    }

    /// Обратно към чистата стойност. Непознат вид пада към разход — по-добре
    /// да покажем нещо разумно, отколкото да изтървем записа.
    public var asFlow: FinancialFlow {
        FinancialFlow(
            id: id,
            date: date,
            amount: Money(minorUnits: minorUnits),
            merchant: merchant,
            kind: FlowKind(rawValue: kindRaw) ?? .expense,
            movement: movementRaw.flatMap(MovementKind.init(rawValue:)),
            categoryID: categoryID,
            note: note,
            recurringRuleID: recurringRuleID
        )
    }
}

@Model
public final class StoredRecurringRule {
    public var id: UUID = UUID()
    public var name: String = ""
    public var minorUnits: Int = 0
    public var frequencyRaw: String = RecurringRule.Frequency.monthly.rawValue
    public var anchorDay: Int = 1
    public var anchorMonth: Int?
    public var categoryID: String?
    public var isActive: Bool = true

    public init(
        id: UUID = UUID(),
        name: String = "",
        minorUnits: Int = 0,
        frequencyRaw: String = RecurringRule.Frequency.monthly.rawValue,
        anchorDay: Int = 1,
        anchorMonth: Int? = nil,
        categoryID: String? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.minorUnits = minorUnits
        self.frequencyRaw = frequencyRaw
        self.anchorDay = anchorDay
        self.anchorMonth = anchorMonth
        self.categoryID = categoryID
        self.isActive = isActive
    }
}

extension StoredRecurringRule {
    public convenience init(_ rule: RecurringRule) {
        self.init(
            id: rule.id,
            name: rule.name,
            minorUnits: rule.amount.minorUnits,
            frequencyRaw: rule.frequency.rawValue,
            anchorDay: rule.anchorDay,
            anchorMonth: rule.anchorMonth,
            categoryID: rule.categoryID,
            isActive: rule.isActive
        )
    }

    public var asRule: RecurringRule {
        RecurringRule(
            id: id,
            name: name,
            amount: Money(minorUnits: minorUnits),
            frequency: RecurringRule.Frequency(rawValue: frequencyRaw) ?? .monthly,
            anchorDay: anchorDay,
            anchorMonth: anchorMonth,
            categoryID: categoryID,
            isActive: isActive
        )
    }
}

/// Месечен лимит за категория.
///
/// Пази се само зададеното. Липсващ запис значи „няма лимит", а не „лимит
/// нула" — разликата е между категория, която не следиш, и категория, в която
/// нямаш право да харчиш.
@Model
public final class StoredBudget {
    public var categoryID: String = SpendingCategory.fallbackID
    public var minorUnits: Int = 0

    public init(categoryID: String = SpendingCategory.fallbackID, minorUnits: Int = 0) {
        self.categoryID = categoryID
        self.minorUnits = minorUnits
    }

    public var asBudget: Budget {
        Budget(categoryID: categoryID, limit: Money(minorUnits: minorUnits))
    }
}

/// Правилата, научени от поправките на потребителя. Вградените живеят в кода
/// и не се записват — само наученото има нужда да преживее преинсталация.
@Model
public final class StoredCategoryRule {
    public var pattern: String = ""
    public var categoryID: String = SpendingCategory.fallbackID
    public var createdAt: Date = Date()

    public init(
        pattern: String = "",
        categoryID: String = SpendingCategory.fallbackID,
        createdAt: Date = Date()
    ) {
        self.pattern = pattern
        self.categoryID = categoryID
        self.createdAt = createdAt
    }

    public var asRule: CategoryRule {
        CategoryRule(pattern: pattern, categoryID: categoryID, isLearned: true)
    }
}
