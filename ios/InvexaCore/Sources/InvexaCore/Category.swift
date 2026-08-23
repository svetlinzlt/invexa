import Foundation

/// Разходна категория.
///
/// Идентификаторът е стабилен низ, а не UUID: категориите се създават от
/// приложението, а не от потребителя, и стабилният ключ позволява правилата
/// за автоматично разпознаване да оцелеят при преименуване и превод.
public struct SpendingCategory: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    /// Подредбата на началния екран при равни суми.
    public var order: Int

    public init(id: String, order: Int) {
        self.id = id
        self.order = order
    }

    /// Името се превежда, а не се пази.
    ///
    /// Идентификаторът остава стабилен и на английски, за да оцелеят
    /// правилата за разпознаване при смяна на езика — потребител, който мине
    /// на английски, не бива да загуби наученото.
    public var name: String {
        String(
            localized: String.LocalizationValue("category.\(id)"),
            bundle: .module,
            comment: "Име на разходна категория"
        )
    }
}

extension SpendingCategory {
    /// Единайсет категории — таванът, който началният екран показва, без да
    /// стане нечетим. Подкатегориите идват по-късно и стоят скрити.
    public static let defaults: [SpendingCategory] = [
        SpendingCategory(id: "housing", order: 0),
        SpendingCategory(id: "utilities", order: 1),
        SpendingCategory(id: "groceries", order: 2),
        SpendingCategory(id: "eating_out", order: 3),
        SpendingCategory(id: "transport", order: 4),
        SpendingCategory(id: "shopping", order: 5),
        SpendingCategory(id: "health", order: 6),
        SpendingCategory(id: "entertainment", order: 7),
        SpendingCategory(id: "travel", order: 8),
        SpendingCategory(id: "education", order: 9),
        SpendingCategory(id: "other", order: 10),
    ]

    /// Кошът, в който пада всичко неразпознато. Не е грешка — той е и
    /// работният списък: каквото стои тук, чака едно докосване, за да се
    /// превърне в ново правило.
    public static let fallbackID = "other"

    public static func named(_ id: String) -> SpendingCategory? {
        defaults.first { $0.id == id }
    }
}
