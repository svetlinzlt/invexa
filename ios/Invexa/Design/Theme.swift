import SwiftUI

/// Визуалният език от одобрените мокъпи.
///
/// Цветът кодира посоката на парите и правилото важи навсякъде: виолетово за
/// излизащото, ментово за оставащото, месинг само за заделеното. Потребителят
/// го научава веднъж.
public enum Palette {
    public static let ink = Color(hex: 0x0A0F1F)
    public static let inkRaised = Color(hex: 0x101731)

    /// Похарчено.
    public static let violet = Color(hex: 0x8F7BFF)
    public static let violetLift = Color(hex: 0xB8ACFF)
    /// Остатък и приходи.
    public static let mint = Color(hex: 0x4FE3C1)
    /// Заделено. Единствената топла точка — пази се само за това.
    public static let brass = Color(hex: 0xE0C77E)

    public static let text = Color(hex: 0xDEE5FA)
    public static let textDim = Color(hex: 0x9AA6CC)
    public static let textFaint = Color(hex: 0x64709A)

    public static let hairline = Color(hex: 0x96AAE1).opacity(0.16)

    /// Фонът, върху който стоят матовите панели. Без текстура — стъклото има
    /// нужда от чиста светлина, за да изглежда като стъкло.
    public static let ground = LinearGradient(
        colors: [Color(hex: 0x18213F), Color(hex: 0x0A0F1F), Color(hex: 0x0C1428)],
        startPoint: .top,
        endPoint: .bottom
    )
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

/// Шрифтовете изискват файловете да са добавени към целта и обявени в
/// Info.plist под `UIAppFonts`. Ако липсват, `Font.custom` тихо пада към
/// системния — затова имената стоят на едно място, за да се проверят наведнъж.
public enum Typeface {
    public static let display = "BodoniModa-Bold"
    public static let ui = "HankenGrotesk-Regular"
    public static let uiMedium = "HankenGrotesk-Medium"
    public static let uiSemibold = "HankenGrotesk-SemiBold"
    public static let mono = "SplineSansMono-Regular"
}

extension Font {
    /// Големите суми. Табулярните цифри пречат на числото да подскача,
    /// докато се обновява.
    public static func amount(_ size: CGFloat) -> Font {
        .custom(Typeface.display, size: size).monospacedDigit()
    }

    public static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name = switch weight {
        case .semibold, .bold: Typeface.uiSemibold
        case .medium: Typeface.uiMedium
        default: Typeface.ui
        }
        return .custom(name, size: size)
    }

    public static func ledger(_ size: CGFloat) -> Font {
        .custom(Typeface.mono, size: size).monospacedDigit()
    }
}

/// Малкият надпис над всяко число. Едно място за разредката, за да не се
/// разминава между екраните.
public struct CapLabel: View {
    private let text: String

    /// Приема `LocalizedStringResource`, а не `String`. Разликата е
    /// съществена: `Text(String)` подава текста както е и **не** превежда,
    /// затова надписи като „Влезли" щяха да останат на български завинаги.
    public init(_ resource: LocalizedStringResource) {
        self.text = String(localized: resource)
    }

    /// За текст, който вече е форматиран — име на месец, сума, име на
    /// търговец. Той не се превежда, защото няма какво.
    public init(verbatim text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text.uppercased())
            .font(.ledger(9))
            .tracking(1.5)
            .foregroundStyle(Palette.textFaint)
    }
}
