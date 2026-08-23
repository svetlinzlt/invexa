import Foundation

/// Чете CSV, както го изнасят банките — не както го описва стандартът.
///
/// Три неща правят наивното разделяне по запетая безполезно тук:
/// европейските банки разделят с точка и запетая, защото запетаята им е
/// десетичен знак; описанията съдържат разделители и затова са в кавички; а
/// краят на реда е ту `\n`, ту `\r\n`.
public enum CSVParser {

    /// Отгатва разделителя по първия непразен ред.
    ///
    /// Броим срещания извън кавички: описание като „Магазин, ул. Витоша“ би
    /// подвело простото броене и файл с точка и запетая ще бъде разчетен като
    /// файл със запетая.
    public static func detectDelimiter(in text: String) -> Character {
        guard let line = text.split(whereSeparator: \.isNewline).first else { return "," }

        var counts: [Character: Int] = [";": 0, ",": 0, "\t": 0, "|": 0]
        var insideQuotes = false

        for character in line {
            if character == "\"" {
                insideQuotes.toggle()
            } else if !insideQuotes, counts[character] != nil {
                counts[character, default: 0] += 1
            }
        }

        // При равенство точката и запетаята печели: тя е разделител само
        // когато е сложена нарочно, докато запетаята се появява и в текст.
        let best = counts.max { left, right in
            if left.value != right.value { return left.value < right.value }
            return left.key != ";"
        }

        return (best?.value ?? 0) > 0 ? (best?.key ?? ",") : ","
    }

    /// Разлага текста на редове от полета.
    public static func rows(from text: String, delimiter: Character? = nil) -> [[String]] {
        let separator = delimiter ?? detectDelimiter(in: text)

        var rows: [[String]] = []
        var fields: [String] = []
        var current = ""
        var insideQuotes = false

        var iterator = text.makeIterator()
        var pending: Character?

        func closeField() {
            fields.append(current.trimmingCharacters(in: .whitespaces))
            current = ""
        }

        func closeRow() {
            closeField()
            // Празните редове в края на файла не са записи.
            if fields.contains(where: { !$0.isEmpty }) { rows.append(fields) }
            fields = []
        }

        while let character = pending ?? iterator.next() {
            pending = nil

            if insideQuotes {
                if character == "\"" {
                    // Две кавички подред значат една кавичка в текста.
                    if let next = iterator.next() {
                        if next == "\"" { current.append("\"") } else {
                            insideQuotes = false
                            pending = next
                        }
                    } else {
                        insideQuotes = false
                    }
                } else {
                    current.append(character)
                }
                continue
            }

            switch character {
            case "\"":
                insideQuotes = true
            case separator:
                closeField()
            case "\r":
                // Поглъщаме `\r\n` като един край на ред.
                if let next = iterator.next(), next != "\n" { pending = next }
                closeRow()
            case "\n":
                closeRow()
            default:
                current.append(character)
            }
        }

        if !current.isEmpty || !fields.isEmpty { closeRow() }
        return rows
    }
}
