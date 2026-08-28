import Foundation
import SwiftData
import WidgetKit
import InvexaCore

/// Хранилището, споделено между приложението, виджетите и App Intents.
///
/// Виджетът се изпълнява в отделен процес и няма достъп до папката на
/// приложението. Затова базата живее в **App Group** — обща папка, която и
/// двата процеса виждат. Ако това се пропусне, виджетът просто показва
/// празен месец и грешката изглежда като липсващи данни.
public enum InvexaStore {

    /// Трябва да е регистрирана в Apple Developer портала и добавена като
    /// възможност към целта на приложението **и** към целта на виджета.
    public static let appGroupID = "group.app.invexa"

    /// Изчислимо, а не `static let`: `Schema` е клас и не е `Sendable`, а
    /// Swift 6 отхвърля споделено изменяемо глобално състояние. Строенето му
    /// е евтино и се случва веднъж на процес.
    public static var schema: Schema {
        Schema([
            StoredFlow.self,
            StoredRecurringRule.self,
            StoredCategoryRule.self,
            StoredBudget.self,
        ])
    }

    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            groupContainer: .identifier(appGroupID),
            cloudKitDatabase: .automatic
        )
        return try ModelContainer(for: schema, configurations: configuration)
    }

    /// Виджетите не забелязват промени в базата сами. Извиква се след всяко
    /// записване или изтриване — иначе числото на началния екран се разминава
    /// с това във виджета и потребителят не знае на кое да вярва.
    public static func refreshWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

extension InvexaStore {
    /// Тегли записите за даден месец. Ползва се от виджета и от App Intents,
    /// където няма `@Query`.
    public static func flows(
        in month: YearMonth,
        context: ModelContext,
        calendar: Calendar = .current
    ) throws -> [FinancialFlow] {
        let start = month.startDate(in: calendar)
        let end = month.endDate(in: calendar)

        let descriptor = FetchDescriptor<StoredFlow>(
            predicate: #Predicate { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor).map(\.asFlow)
    }

    public static func learnedRules(context: ModelContext) throws -> [CategoryRule] {
        try context.fetch(FetchDescriptor<StoredCategoryRule>()).map(\.asRule)
    }
}
