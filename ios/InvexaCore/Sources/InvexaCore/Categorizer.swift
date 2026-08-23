import Foundation

/// Правило „търговец → категория“.
public struct CategoryRule: Hashable, Codable, Sendable {
    /// Търси се като част от името на търговеца, без значение от регистър и
    /// диакритика.
    public let pattern: String
    public let categoryID: String
    /// Правилата, научени от поправка на потребителя, бият вградените.
    public let isLearned: Bool

    public init(pattern: String, categoryID: String, isLearned: Bool = false) {
        self.pattern = pattern
        self.categoryID = categoryID
        self.isLearned = isLearned
    }
}

/// Разпознава категорията по името на търговеца.
///
/// Нарочно скучно: речник от правила, който хваща голямата част от случаите
/// и се поправя с едно докосване. Модел на устройството има смисъл едва
/// когато има от какво да се учи, а в началото няма.
public struct Categorizer: Sendable {
    private var rules: [CategoryRule]

    public init(rules: [CategoryRule] = CategoryRule.starterSet) {
        self.rules = rules
    }

    public var allRules: [CategoryRule] { rules }

    public func categoryID(forMerchant merchant: String) -> String? {
        let needle = Self.normalize(merchant)
        guard !needle.isEmpty else { return nil }

        // Наученото бие вграденото; при равни условия печели по-дългото
        // съвпадение, защото е по-конкретно („лидл експрес“ пред „лидл“).
        let match = rules
            .filter { needle.contains(Self.normalize($0.pattern)) }
            .max { left, right in
                if left.isLearned != right.isLearned { return right.isLearned }
                return left.pattern.count < right.pattern.count
            }

        return match?.categoryID
    }

    /// Категорията за нов запис. Никога не връща `nil` — неразпознатото
    /// отива в „Друго“, откъдето потребителят го поправя с едно докосване.
    public func categorize(merchant: String) -> String {
        categoryID(forMerchant: merchant) ?? SpendingCategory.fallbackID
    }

    /// Поправката на потребителя става ново правило. Това е механизмът, който
    /// прави приложението точно след месец употреба.
    public mutating func learn(merchant: String, categoryID: String) {
        let pattern = Self.normalize(merchant)
        guard !pattern.isEmpty else { return }
        rules.removeAll { $0.isLearned && Self.normalize($0.pattern) == pattern }
        rules.append(CategoryRule(pattern: pattern, categoryID: categoryID, isLearned: true))
    }

    /// Сваля регистъра и диакритиката, за да съвпадат „Лидл“, „ЛИДЛ“ и
    /// „LIDL BG 1234“ — банковите извлечения пишат имената както им дойде.
    static func normalize(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive], locale: Locale(identifier: "bg_BG"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension CategoryRule {
    /// Начален набор за България. Кратък нарочно — истинският списък се
    /// напълва от поправките на реални потребители, а не от предположения.
    public static let starterSet: [CategoryRule] = [
        CategoryRule(pattern: "лидл", categoryID: "groceries"),
        CategoryRule(pattern: "lidl", categoryID: "groceries"),
        CategoryRule(pattern: "билла", categoryID: "groceries"),
        CategoryRule(pattern: "billa", categoryID: "groceries"),
        CategoryRule(pattern: "кауфланд", categoryID: "groceries"),
        CategoryRule(pattern: "kaufland", categoryID: "groceries"),
        CategoryRule(pattern: "фантастико", categoryID: "groceries"),
        CategoryRule(pattern: "t market", categoryID: "groceries"),

        CategoryRule(pattern: "bolt", categoryID: "transport"),
        CategoryRule(pattern: "uber", categoryID: "transport"),
        CategoryRule(pattern: "shell", categoryID: "transport"),
        CategoryRule(pattern: "omv", categoryID: "transport"),
        CategoryRule(pattern: "лукойл", categoryID: "transport"),
        CategoryRule(pattern: "центъра за градска мобилност", categoryID: "transport"),

        CategoryRule(pattern: "netflix", categoryID: "entertainment"),
        CategoryRule(pattern: "spotify", categoryID: "entertainment"),
        CategoryRule(pattern: "youtube", categoryID: "entertainment"),
        CategoryRule(pattern: "icloud", categoryID: "entertainment"),
        CategoryRule(pattern: "apple.com/bill", categoryID: "entertainment"),
        CategoryRule(pattern: "steam", categoryID: "entertainment"),

        CategoryRule(pattern: "виваком", categoryID: "utilities"),
        CategoryRule(pattern: "vivacom", categoryID: "utilities"),
        CategoryRule(pattern: "a1", categoryID: "utilities"),
        CategoryRule(pattern: "йеттел", categoryID: "utilities"),
        CategoryRule(pattern: "топлофикация", categoryID: "utilities"),
        CategoryRule(pattern: "електрохолд", categoryID: "utilities"),
        CategoryRule(pattern: "софийска вода", categoryID: "utilities"),

        CategoryRule(pattern: "аптека", categoryID: "health"),
        CategoryRule(pattern: "софарма", categoryID: "health"),
        CategoryRule(pattern: "remedium", categoryID: "health"),

        CategoryRule(pattern: "wizz", categoryID: "travel"),
        CategoryRule(pattern: "ryanair", categoryID: "travel"),
        CategoryRule(pattern: "booking.com", categoryID: "travel"),
        CategoryRule(pattern: "airbnb", categoryID: "travel"),

        CategoryRule(pattern: "ikea", categoryID: "shopping"),
        CategoryRule(pattern: "decathlon", categoryID: "shopping"),
        CategoryRule(pattern: "emag", categoryID: "shopping"),
        CategoryRule(pattern: "zara", categoryID: "shopping"),
    ]
}
