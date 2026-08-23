import Foundation

/// Ред от извлечение, готов за преглед преди записване.
public struct ImportCandidate: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let date: Date
    public let amount: Money
    public let merchant: String
    public let kind: FlowKind
    public let suggestedCategory: String
    /// Ред от файла, за да може човекът да провери какво е разчетено.
    public let rowNumber: Int

    public func asFlow() -> FinancialFlow {
        FinancialFlow(
            id: id,
            date: date,
            amount: amount,
            merchant: merchant,
            kind: kind,
            categoryID: kind == .expense ? suggestedCategory : nil
        )
    }

    /// Същият ден, същата сума, същият търговец. По-строга проверка няма
    /// смисъл: банките не дават стабилен идентификатор на транзакция в CSV.
    public func looksLike(_ flow: FinancialFlow, calendar: Calendar = .current) -> Bool {
        amount == flow.amount
            && kind == flow.kind
            && calendar.isDate(date, inSameDayAs: flow.date)
            && merchant.caseInsensitiveCompare(flow.merchant) == .orderedSame
    }
}

public struct SkippedRow: Identifiable, Hashable, Sendable {
    public enum Reason: String, Sendable {
        case noDate
        case noAmount
        case zeroAmount

        /// Текстът за показване. Суровата стойност остава стабилен ключ —
        /// тестовете и лог файловете не бива да зависят от езика.
        public var text: String {
            String(
                localized: String.LocalizationValue("import.skip.\(rawValue)"),
                bundle: .module,
                comment: "Причина ред от банково извлечение да бъде пропуснат"
            )
        }
    }

    public let rowNumber: Int
    public let reason: Reason
    public let raw: String

    public var id: Int { rowNumber }
}

public struct ImportReport: Sendable {
    public let candidates: [ImportCandidate]
    public let skipped: [SkippedRow]
    /// Заглавията, които са разпознати. Показват се, за да е ясно кое кое е.
    public let matchedColumns: [String: String]
}

public enum StatementImporter {

    // Банките пишат заглавията както си искат. Списъците са отворени —
    // допълват се, когато реален файл не се разчете.
    private static let dateKeys = [
        "дата", "date", "датa", "вальор", "value date", "дата на осчетоводяване",
        "booking date", "transaction date",
    ]
    private static let amountKeys = [
        "сума", "amount", "стойност", "value", "сума на транзакцията",
    ]
    private static let debitKeys = ["дебит", "debit", "изходяща", "разход"]
    private static let creditKeys = ["кредит", "credit", "входяща", "приход"]
    private static let merchantKeys = [
        "описание", "description", "контрагент", "основание", "детайли",
        "merchant", "details", "narrative", "получател",
    ]

    public static func read(
        csv: String,
        categorizer: Categorizer = Categorizer(),
        calendar: Calendar = .current
    ) -> ImportReport {
        let rows = CSVParser.rows(from: csv)
        guard let header = rows.first, rows.count > 1 else {
            return ImportReport(candidates: [], skipped: [], matchedColumns: [:])
        }

        let normalized = header.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        func column(matching keys: [String]) -> Int? {
            normalized.firstIndex { title in
                keys.contains { title == $0 } || keys.contains { title.contains($0) }
            }
        }

        let dateIndex = column(matching: dateKeys)
        let amountIndex = column(matching: amountKeys)
        let debitIndex = column(matching: debitKeys)
        let creditIndex = column(matching: creditKeys)
        let merchantIndex = column(matching: merchantKeys)

        var matched: [String: String] = [:]
        if let dateIndex { matched["Дата"] = header[dateIndex] }
        if let amountIndex { matched["Сума"] = header[amountIndex] }
        if let debitIndex { matched["Дебит"] = header[debitIndex] }
        if let creditIndex { matched["Кредит"] = header[creditIndex] }
        if let merchantIndex { matched["Описание"] = header[merchantIndex] }

        var candidates: [ImportCandidate] = []
        var skipped: [SkippedRow] = []

        for (offset, row) in rows.dropFirst().enumerated() {
            let rowNumber = offset + 2  // ред 1 е заглавието

            func field(_ index: Int?) -> String {
                guard let index, row.indices.contains(index) else { return "" }
                return row[index]
            }

            guard let date = parseDate(field(dateIndex), calendar: calendar) else {
                skipped.append(SkippedRow(rowNumber: rowNumber, reason: .noDate, raw: row.joined(separator: " · ")))
                continue
            }

            guard let signed = amount(
                single: field(amountIndex),
                debit: field(debitIndex),
                credit: field(creditIndex)
            ) else {
                skipped.append(SkippedRow(rowNumber: rowNumber, reason: .noAmount, raw: row.joined(separator: " · ")))
                continue
            }

            guard signed.minorUnits != 0 else {
                skipped.append(SkippedRow(rowNumber: rowNumber, reason: .zeroAmount, raw: row.joined(separator: " · ")))
                continue
            }

            let fallback = String(
                localized: "import.fallbackMerchant",
                bundle: .module,
                comment: "Име по подразбиране, когато редът няма описание"
            )
            let merchant = field(merchantIndex).isEmpty ? fallback : field(merchantIndex)
            // Отрицателното значи излизащи пари. Приходите не се категоризират.
            let kind: FlowKind = signed.isNegative ? .expense : .income

            candidates.append(
                ImportCandidate(
                    id: UUID(),
                    date: date,
                    amount: signed.magnitude,
                    merchant: merchant,
                    kind: kind,
                    suggestedCategory: kind == .expense
                        ? categorizer.categorize(merchant: merchant)
                        : SpendingCategory.fallbackID,
                    rowNumber: rowNumber
                )
            )
        }

        return ImportReport(candidates: candidates, skipped: skipped, matchedColumns: matched)
    }

    /// Отделни колони за дебит и кредит са често срещани в български
    /// извлечения. Когато ги има, знакът идва от колоната, не от числото.
    static func amount(single: String, debit: String, credit: String) -> Money? {
        if let outgoing = Money(text: normalize(debit)), !outgoing.isZero {
            return -outgoing.magnitude
        }
        if let incoming = Money(text: normalize(credit)), !incoming.isZero {
            return incoming.magnitude
        }
        return Money(text: normalize(single))
    }

    /// Счетоводните файлове пишат отрицателните в скоби.
    static func normalize(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("("), trimmed.hasSuffix(")") else { return trimmed }
        return "-" + trimmed.dropFirst().dropLast()
    }

    static func parseDate(_ value: String, calendar: Calendar) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        // Само явни, недвусмислени наредби. Автоматичното разпознаване на
        // дати бърка 03/04 между двата ѝ възможни прочита, а сгрешен месец
        // мести разхода в друг месечен отчет.
        let separators: [Character] = [".", "/", "-"]
        let digits = trimmed.prefix(while: { $0.isNumber || separators.contains($0) })
        let parts = digits.split(whereSeparator: { separators.contains($0) }).map(String.init)
        guard parts.count >= 3 else { return nil }

        let numbers = parts.compactMap(Int.init)
        guard numbers.count >= 3 else { return nil }

        var components = DateComponents()
        if parts[0].count == 4 {
            // 2026-08-21
            components.year = numbers[0]
            components.month = numbers[1]
            components.day = numbers[2]
        } else {
            // 21.08.2026 — редът, който ползват банките в Европа.
            components.day = numbers[0]
            components.month = numbers[1]
            components.year = numbers[2] < 100 ? 2000 + numbers[2] : numbers[2]
        }
        components.hour = 12

        guard let month = components.month, (1...12).contains(month),
              let day = components.day, (1...31).contains(day) else { return nil }

        return calendar.date(from: components)
    }
}
