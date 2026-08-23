import Foundation
import Testing
@testable import InvexaCore

@Suite("Пари")
struct MoneyTests {

    /// Причината `Money` изобщо да съществува. Същата сметка с `Double`
    /// връща 0.30000000000000004.
    @Test("Стотинките се събират точно")
    func centsAddUpExactly() {
        let total = [
            Money(euros: 0, cents: 10),
            Money(euros: 0, cents: 20),
        ].total()

        #expect(total == Money(euros: 0, cents: 30))
        #expect(total.minorUnits == 30)
    }

    @Test("Хиляда записа не трупат грешка")
    func thousandEntriesStayExact() {
        let total = Array(repeating: Money(euros: 0, cents: 1), count: 1000).total()
        #expect(total == Money(euros: 10))
    }

    @Test("Отрицателните суми пазят стотинките от правилната страна")
    func negativeAmountsKeepCents() {
        #expect(Money(euros: -5, cents: 50).minorUnits == -550)
    }

    @Test("Изваждането може да мине под нулата")
    func subtractionGoesNegative() {
        let result = Money(euros: 100) - Money(euros: 150)
        #expect(result == Money(euros: -50))
        #expect(result.isNegative)
        #expect(result.magnitude == Money(euros: 50))
    }

    @Test("Делът от нула е нула, а не срив")
    func shareOfZeroIsZero() {
        #expect(Money(euros: 10).share(of: .zero) == 0)
    }

    @Test("Делът се смята вярно")
    func shareIsCorrect() {
        let share = Money(euros: 25).share(of: Money(euros: 100))
        #expect(abs(share - 0.25) < 0.0001)
    }

    @Test("Сумите се подреждат по големина")
    func comparable() {
        #expect(Money(euros: 5) < Money(euros: 10))
        #expect([Money(euros: 3), Money(euros: 1), Money(euros: 2)].max() == Money(euros: 3))
    }
}

@Suite("Превръщане от Double")
struct MoneyRoundingTests {

    /// Класическият капан: 12,10 не се представя точно в двоична плаваща
    /// запетая. Умножението по 100 дава 1209,9999…, а отрязването би дало
    /// 12,09. Затова закръгляме, не отрязваме.
    @Test("Стойности, които плаващата запетая не пази точно, се закръглят вярно")
    func roundsRatherThanTruncates() {
        // 12,10 × 100 дава 1210,0000000000002; отрязването би дало 12,09.
        #expect(Money(rounding: 12.10) == Money(euros: 12, cents: 10))
        // 0,29 × 100 дава 28,999999999999996; отрязването би дало 0,28.
        #expect(Money(rounding: 0.29) == Money(euros: 0, cents: 29))
    }

    /// Известно ограничение, записано нарочно като тест.
    ///
    /// 1,005 не съществува в двоична плаваща запетая — най-близкото число е
    /// 1,00499999999999989, тоест **под** ръба на закръгляне. Затова резултатът
    /// е 1,00, не 1,01. Това не е поправимо, докато стойността идва като
    /// `Double`; поправимо е само ако сумата дойде като текст.
    @Test("Половин стотинка на ръба следва реалната стойност на числото")
    func halfCentFollowsTheActualDouble() {
        #expect(Money(rounding: 1.005) == Money(euros: 1, cents: 0))
        // Същата сума като текст се чете точно — затова клавиатурата в
        // приложението минава през `Money(text:)`, а не през `Double`.
        #expect(Money(text: "1,01") == Money(euros: 1, cents: 1))
    }

    @Test("Цели числа минават непроменени")
    func wholeNumbers() {
        #expect(Money(rounding: 34) == Money(euros: 34))
        #expect(Money(rounding: 0) == .zero)
    }

    @Test("Отрицателните се закръглят към правилната страна")
    func negativeRounding() {
        #expect(Money(rounding: -12.10) == Money(euros: -12, cents: 10))
    }

    @Test("Безкрайност и NaN дават нула, вместо да сринат приложението")
    func nonFiniteIsZero() {
        #expect(Money(rounding: .nan) == .zero)
        #expect(Money(rounding: .infinity) == .zero)
    }
}

@Suite("Разбор на въведена сума")
struct MoneyParsingTests {

    @Test("Запетая и точка вършат една и съща работа")
    func commaAndDotAgree() {
        #expect(Money(text: "12,50") == Money(euros: 12, cents: 50))
        #expect(Money(text: "12.50") == Money(euros: 12, cents: 50))
    }

    /// Ръбът, който бърка сумата десет пъти: „12,5“ значи 12,50, а не 12,05.
    @Test("Една цифра след запетаята са десетки стотинки")
    func singleDecimalIsTens() {
        #expect(Money(text: "12,5") == Money(euros: 12, cents: 50))
    }

    @Test("Цяло число без запетая")
    func wholeNumber() {
        #expect(Money(text: "34") == Money(euros: 34))
    }

    @Test("Разделителят за хиляди и знакът за валута се пренебрегват")
    func stripsNoiseFromStatements() {
        #expect(Money(text: "1 234,56") == Money(euros: 1234, cents: 56))
        #expect(Money(text: "1\u{00A0}234,56") == Money(euros: 1234, cents: 56))
        #expect(Money(text: "12,50 €") == Money(euros: 12, cents: 50))
    }

    @Test("Отрицателните суми от извлечение се четат")
    func negativeFromStatement() {
        #expect(Money(text: "-34,20") == Money(euros: -34, cents: 20))
    }

    @Test("Повече от две цифри след запетаята се отрязват")
    func extraDecimalsAreCut() {
        #expect(Money(text: "12,509") == Money(euros: 12, cents: 50))
    }

    @Test("Водеща запетая се чете като нула цяло")
    func leadingSeparator() {
        #expect(Money(text: ",50") == Money(euros: 0, cents: 50))
    }

    @Test("Безсмислен текст връща nil, а не нула")
    func nonsenseIsNil() {
        #expect(Money(text: "") == nil)
        #expect(Money(text: "абв") == nil)
        #expect(Money(text: "12,34,56") == nil)
        #expect(Money(text: "-") == nil)
    }
}
