import Foundation
import Testing
@testable import InvexaCore

@Suite("Разпознаване на категория")
struct CategorizerTests {

    @Test("Регистърът няма значение")
    func caseInsensitive() {
        let categorizer = Categorizer()
        #expect(categorizer.categorize(merchant: "ЛИДЛ") == "groceries")
        #expect(categorizer.categorize(merchant: "лидл") == "groceries")
        #expect(categorizer.categorize(merchant: "Лидл") == "groceries")
    }

    /// Банковите извлечения не пишат чисти имена — има кодове, градове и
    /// номера на терминали около самото име.
    @Test("Името се намира и вътре в редa от извлечението")
    func matchesInsideBankLine() {
        let categorizer = Categorizer()
        #expect(categorizer.categorize(merchant: "LIDL BG 0421 SOFIA") == "groceries")
        #expect(categorizer.categorize(merchant: "PAYMENT BOLT.EU/O/2508") == "transport")
    }

    @Test("Неразпознатото отива в Друго, не изчезва")
    func unknownFallsBack() {
        let categorizer = Categorizer()
        #expect(categorizer.categorize(merchant: "Магазин на ъгъла") == SpendingCategory.fallbackID)
        #expect(categorizer.categoryID(forMerchant: "Магазин на ъгъла") == nil)
    }

    @Test("Празното име не чупи нищо")
    func emptyMerchantIsSafe() {
        let categorizer = Categorizer()
        #expect(categorizer.categoryID(forMerchant: "") == nil)
        #expect(categorizer.categoryID(forMerchant: "   ") == nil)
    }

    @Test("Поправката на потребителя става правило")
    func correctionBecomesRule() {
        var categorizer = Categorizer()
        #expect(categorizer.categorize(merchant: "Кафе Ателие") == SpendingCategory.fallbackID)

        categorizer.learn(merchant: "Кафе Ателие", categoryID: "eating_out")

        #expect(categorizer.categorize(merchant: "Кафе Ателие") == "eating_out")
        #expect(categorizer.categorize(merchant: "КАФЕ АТЕЛИЕ СОФИЯ") == "eating_out")
    }

    @Test("Наученото бие вграденото")
    func learnedBeatsBuiltIn() {
        var categorizer = Categorizer()
        #expect(categorizer.categorize(merchant: "Лидл") == "groceries")

        categorizer.learn(merchant: "Лидл", categoryID: "shopping")

        #expect(categorizer.categorize(merchant: "Лидл") == "shopping")
    }

    @Test("Повторната поправка не трупа дублирани правила")
    func relearningReplaces() {
        var categorizer = Categorizer()
        let before = categorizer.allRules.count

        categorizer.learn(merchant: "Тест", categoryID: "health")
        categorizer.learn(merchant: "Тест", categoryID: "travel")

        #expect(categorizer.allRules.count == before + 1)
        #expect(categorizer.categorize(merchant: "Тест") == "travel")
    }

    @Test("По-конкретното правило печели пред по-общото")
    func longerPatternWins() {
        let categorizer = Categorizer(rules: [
            CategoryRule(pattern: "кафе", categoryID: "eating_out"),
            CategoryRule(pattern: "кафе машина сервиз", categoryID: "shopping"),
        ])

        #expect(categorizer.categorize(merchant: "Кафе машина сервиз ООД") == "shopping")
        #expect(categorizer.categorize(merchant: "Кафе Ателие") == "eating_out")
    }
}
