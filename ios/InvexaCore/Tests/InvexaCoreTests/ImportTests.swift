import Foundation
import Testing
@testable import InvexaCore

@Suite("Разчитане на CSV")
struct CSVParserTests {

    /// Причината да не се разделя наивно по запетая: българските банки пишат
    /// с точка и запетая, защото запетаята им е десетичен знак.
    @Test("Точката и запетаята се разпознава като разделител")
    func detectsSemicolon() {
        let text = "Дата;Сума;Описание\n21.08.2026;-34,20;Лидл"
        #expect(CSVParser.detectDelimiter(in: text) == ";")
    }

    @Test("Запетаята се разпознава, когато тя е разделителят")
    func detectsComma() {
        let text = "date,amount,description\n2026-08-21,-34.20,Lidl"
        #expect(CSVParser.detectDelimiter(in: text) == ",")
    }

    @Test("Табулацията се разпознава")
    func detectsTab() {
        let text = "Дата\tСума\tОписание\n21.08.2026\t-34,20\tЛидл"
        #expect(CSVParser.detectDelimiter(in: text) == "\t")
    }

    /// Разделител вътре в кавички не е разделител.
    @Test("Кавичките пазят разделителя вътре в текста")
    func quotedDelimiterIsText() {
        let text = "a,b\n\"Магазин, ул. Витоша\",10"
        let rows = CSVParser.rows(from: text)

        #expect(rows.count == 2)
        #expect(rows[1][0] == "Магазин, ул. Витоша")
        #expect(rows[1][1] == "10")
    }

    @Test("Две кавички подред са една кавичка в текста")
    func escapedQuotes() {
        let rows = CSVParser.rows(from: "a\n\"Кафе \"\"Ателие\"\"\"")
        #expect(rows[1][0] == "Кафе \"Ателие\"")
    }

    @Test("Windows и Unix краища на ред дават еднакъв резултат")
    func handlesBothLineEndings() {
        let windows = CSVParser.rows(from: "a;b\r\n1;2\r\n")
        let unix = CSVParser.rows(from: "a;b\n1;2\n")
        #expect(windows == unix)
    }

    @Test("Празните редове в края не стават записи")
    func trailingBlankLinesIgnored() {
        let rows = CSVParser.rows(from: "a;b\n1;2\n\n\n")
        #expect(rows.count == 2)
    }
}

@Suite("Внос на извлечение")
struct StatementImporterTests {

    private let bulgarianStatement = """
    Дата;Сума;Описание
    21.08.2026;-34,20;ЛИДЛ БГ 0421 СОФИЯ
    20.08.2026;-18,99;ВИВАКОМ
    18.08.2026;1170,00;Работна заплата
    """

    @Test("Отрицателните са разходи, положителните — приходи")
    func signDecidesDirection() {
        let report = StatementImporter.read(csv: bulgarianStatement, calendar: Fixed.calendar)

        #expect(report.candidates.count == 3)
        #expect(report.candidates[0].kind == .expense)
        #expect(report.candidates[0].amount == Money(euros: 34, cents: 20))
        #expect(report.candidates[2].kind == .income)
        #expect(report.candidates[2].amount == Money(euros: 1170))
    }

    @Test("Категорията идва предложена от описанието")
    func suggestsCategory() {
        let report = StatementImporter.read(csv: bulgarianStatement, calendar: Fixed.calendar)
        #expect(report.candidates[0].suggestedCategory == "groceries")
        #expect(report.candidates[1].suggestedCategory == "utilities")
    }

    @Test("Датите в европейска наредба се четат вярно")
    func parsesEuropeanDates() {
        let report = StatementImporter.read(csv: bulgarianStatement, calendar: Fixed.calendar)
        let day = Fixed.calendar.component(.day, from: report.candidates[0].date)
        let month = Fixed.calendar.component(.month, from: report.candidates[0].date)

        #expect(day == 21)
        #expect(month == 8)
    }

    @Test("Датите в ISO наредба също се четат")
    func parsesISODates() {
        let csv = "date,amount,description\n2026-08-21,-34.20,Lidl"
        let report = StatementImporter.read(csv: csv, calendar: Fixed.calendar)

        #expect(Fixed.calendar.component(.day, from: report.candidates[0].date) == 21)
        #expect(Fixed.calendar.component(.month, from: report.candidates[0].date) == 8)
    }

    /// Много български извлечения имат отделни колони, а числата в тях са
    /// без знак. Ако се четат наивно, всички разходи стават приходи.
    @Test("Отделни колони за дебит и кредит дават правилната посока")
    func separateDebitCreditColumns() {
        let csv = """
        Дата;Дебит;Кредит;Описание
        21.08.2026;34,20;;ЛИДЛ
        18.08.2026;;1170,00;Заплата
        """
        let report = StatementImporter.read(csv: csv, calendar: Fixed.calendar)

        #expect(report.candidates.count == 2)
        #expect(report.candidates[0].kind == .expense)
        #expect(report.candidates[0].amount == Money(euros: 34, cents: 20))
        #expect(report.candidates[1].kind == .income)
    }

    @Test("Счетоводните скоби значат отрицателно")
    func parenthesesMeanNegative() {
        #expect(StatementImporter.normalize("(123,45)") == "-123,45")
        #expect(StatementImporter.normalize("123,45") == "123,45")
    }

    @Test("Нечетимите редове се пропускат с причина, не изчезват")
    func unreadableRowsAreReported() {
        let csv = """
        Дата;Сума;Описание
        21.08.2026;-34,20;Лидл
        безсмислица;-10,00;Нещо
        20.08.2026;;Без сума
        19.08.2026;0,00;Нула
        """
        let report = StatementImporter.read(csv: csv, calendar: Fixed.calendar)

        #expect(report.candidates.count == 1)
        #expect(report.skipped.count == 3)
        #expect(report.skipped.map(\.reason) == [.noDate, .noAmount, .zeroAmount])
        #expect(report.skipped[0].rowNumber == 3)
    }

    @Test("Разпознатите колони се отчитат, за да е ясно кое кое е")
    func reportsMatchedColumns() {
        let report = StatementImporter.read(csv: bulgarianStatement, calendar: Fixed.calendar)
        #expect(report.matchedColumns["Дата"] == "Дата")
        #expect(report.matchedColumns["Описание"] == "Описание")
    }

    @Test("Файл само със заглавие не чупи нищо")
    func headerOnlyIsSafe() {
        let report = StatementImporter.read(csv: "Дата;Сума;Описание", calendar: Fixed.calendar)
        #expect(report.candidates.isEmpty)
        #expect(report.skipped.isEmpty)
    }

    @Test("Двойният внос се разпознава по ден, сума и описание")
    func detectsDuplicates() {
        let report = StatementImporter.read(csv: bulgarianStatement, calendar: Fixed.calendar)
        let existing = report.candidates[0].asFlow()

        #expect(report.candidates[0].looksLike(existing, calendar: Fixed.calendar))
        #expect(!report.candidates[1].looksLike(existing, calendar: Fixed.calendar))
    }
}
