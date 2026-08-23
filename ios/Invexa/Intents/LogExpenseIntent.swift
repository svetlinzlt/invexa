import AppIntents
import Foundation
import SwiftData
import InvexaCore

/// „Добави 12 евро обяд“ — казано на Siri, писано в Преки пътища или
/// закачено на Action Button.
///
/// Този интент е истинският път към трите секунди. Отварянето на
/// приложението и писането в лист е по-бавното решение.
struct LogExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "Запиши разход"
    static let description = IntentDescription(
        "Записва разход в Invexa, без да отваря приложението.",
        categoryName: "Разходи"
    )

    /// Записът минава наум — няма какво да се покаже на екрана.
    static var openAppWhenRun: Bool { false }

    @Parameter(title: "Сума", requestValueDialog: "Колко?")
    var amount: Double

    @Parameter(title: "Къде", requestValueDialog: "За какво?")
    var merchant: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Запиши \(\.$amount) за \(\.$merchant)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try InvexaStore.makeContainer()
        let context = ModelContext(container)

        // Единственото място, където Double се превръща в пари. Закръгля се
        // веднага, за да не тръгне грешката надолу през сметките.
        let money = Money(rounding: amount)
        guard money.minorUnits > 0 else {
            throw $amount.needsValueError("Сумата трябва да е над нула.")
        }

        let name = merchant?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let learned = (try? InvexaStore.learnedRules(context: context)) ?? []
        let categorizer = Categorizer(rules: CategoryRule.starterSet + learned)

        let flow = FinancialFlow.expense(
            money,
            merchant: name.isEmpty ? "Без име" : name,
            on: .now,
            category: categorizer.categorize(merchant: name)
        )

        context.insert(StoredFlow(flow))
        try context.save()
        InvexaStore.refreshWidgets()

        // Отговорът включва и остатъка за месеца: човекът пита за едно нещо,
        // но иска да знае другото.
        let month = YearMonth(containing: .now)
        let summary = MonthSummary(
            month: month,
            flows: try InvexaStore.flows(in: month, context: context)
        )

        return .result(
            dialog: IntentDialog(
                "Записах \(money.formatted()). Остават \(summary.remaining.formatted()) за месеца."
            )
        )
    }
}

/// Питане за остатъка, без да се отваря нищо.
struct RemainingThisMonthIntent: AppIntent {
    static let title: LocalizedStringResource = "Колко остават този месец"
    static var openAppWhenRun: Bool { false }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try InvexaStore.makeContainer()
        let context = ModelContext(container)
        let month = YearMonth(containing: .now)
        let summary = MonthSummary(
            month: month,
            flows: try InvexaStore.flows(in: month, context: context)
        )

        return .result(
            dialog: IntentDialog(
                "Похарчил си \(summary.spent.formatted()). Остават \(summary.remaining.formatted())."
            )
        )
    }
}

/// Фразите, с които Siri разпознава действията. Появяват се в Преки пътища
/// веднага след първото пускане, без потребителят да настройва нищо.
struct InvexaShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogExpenseIntent(),
            phrases: [
                "Запиши разход в \(.applicationName)",
                "Добави разход в \(.applicationName)",
                "Похарчих пари, \(.applicationName)",
            ],
            shortTitle: "Запиши разход",
            systemImageName: "plus.circle"
        )

        AppShortcut(
            intent: RemainingThisMonthIntent(),
            phrases: [
                "Колко остават в \(.applicationName)",
                "Колко похарчих според \(.applicationName)",
            ],
            shortTitle: "Остатък за месеца",
            systemImageName: "chart.bar"
        )
    }
}
