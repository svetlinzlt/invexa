import SwiftUI
import SwiftData
import InvexaCore

/// Началният екран. Отговаря на един въпрос: как върви този месец.
struct MonthScreen: View {
    private let month: YearMonth
    private let calendar: Calendar
    private let onAdd: () -> Void
    private let onSettings: () -> Void
    private let monthControl: () -> AnyView

    @Query private var stored: [StoredFlow]

    init(
        month: YearMonth = YearMonth(containing: .now),
        calendar: Calendar = .current,
        onAdd: @escaping () -> Void = {},
        onSettings: @escaping () -> Void = {},
        monthControl: @escaping () -> AnyView = { AnyView(EmptyView()) }
    ) {
        self.month = month
        self.calendar = calendar
        self.onAdd = onAdd
        self.onSettings = onSettings
        self.monthControl = monthControl

        // Заявката тегли само този месец. Предикатът има нужда от прости
        // локални стойности — не приема извикване на метод.
        let start = month.startDate(in: calendar)
        let end = month.endDate(in: calendar)
        _stored = Query(
            filter: #Predicate<StoredFlow> { $0.date >= start && $0.date < end },
            sort: \StoredFlow.date,
            order: .reverse
        )
    }

    private var summary: MonthSummary {
        MonthSummary(month: month, flows: stored.map(\.asFlow), calendar: calendar)
    }

    private var todayIndex: Int? {
        month.dayIndex(of: .now, in: calendar).map { $0 - 1 }
    }

    var body: some View {
        if stored.isEmpty {
            EmptyMonthView(month: month, onAdd: onAdd)
        } else {
            content
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                MonthCurve(dailySpending: summary.dailySpending, todayIndex: todayIndex)
                    .frame(height: 96)
                axis
                FlowTriplet(summary: summary)
                CategoryList(totals: summary.byCategory)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                monthControl()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(summary.spent.formatted())
                    .font(.amount(46))
                    .foregroundStyle(Palette.text)
                Text(subtitle)
                    .font(.ui(11))
                    .foregroundStyle(Palette.textDim)
            }
            Spacer()
            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16))
                    .foregroundStyle(Palette.textDim)
            }
            .accessibilityLabel("Настройки")
            .padding(.top, 4)
        }
        .padding(.horizontal, 4)
        .padding(.top, 12)
    }

    private var axis: some View {
        HStack {
            Text("1")
            Spacer()
            Text("ДНЕС")
            Spacer()
            Text("\(month.dayCount(in: calendar))")
        }
        .font(.ledger(8.5))
        .tracking(1)
        .foregroundStyle(Palette.textFaint)
        .padding(.horizontal, 4)
    }

    private var monthTitle: String {
        month.startDate(in: calendar)
            .formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "bg_BG")))
    }

    /// Текущият месец тече, миналите са приключили. Да пише „за 31 от 31 дни"
    /// на завършен месец е вярно и безполезно.
    private var subtitle: String {
        // `String(localized:)`, а не гол литерал: `Text(String)` подава текста
        // както е и не го превежда. Само `Text("литерал")` минава през
        // `LocalizedStringKey`.
        let total = month.dayCount(in: calendar)
        guard let day = month.dayIndex(of: .now, in: calendar) else {
            return String(localized: "похарчено за целия месец")
        }
        return String(localized: "похарчено за \(day) от \(total) дни")
    }
}

/// Влязло, заделено, остава. Заделеното стои до похарченото, а не вътре в
/// него — това е разликата, заради която приложението съществува.
struct FlowTriplet: View {
    let summary: MonthSummary

    var body: some View {
        HStack(spacing: 1) {
            cell("Влезли", summary.income, Palette.mint)
            cell("Заделени", summary.saved + summary.invested, Palette.brass)
            cell("Остават", summary.remaining, Palette.text)
        }
        .background(Palette.hairline)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private func cell(_ title: LocalizedStringResource, _ value: Money, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            CapLabel(title)
            Text(value.formatted())
                .font(.amount(17))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 11)
        .padding(.vertical, 12)
        .background(Palette.inkRaised.opacity(0.62))
    }
}

struct CategoryList: View {
    let totals: [CategoryTotal]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CapLabel("Къде отидоха")

            ForEach(totals.prefix(6), id: \.categoryID) { total in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(SpendingCategory.named(total.categoryID)?.name ?? total.categoryID)
                            .font(.ui(11.5, weight: .medium))
                            .foregroundStyle(Palette.text)
                        Spacer()
                        Text(total.amount.formatted())
                            .font(.ledger(10.5))
                            .foregroundStyle(Palette.textDim)
                    }

                    // Лентите са спрямо най-голямата категория, не спрямо
                    // общото: така разликите между съседните се виждат.
                    GeometryReader { geometry in
                        let widest = totals.first?.amount.minorUnits ?? 1
                        let fraction = widest == 0 ? 0 : Double(total.amount.minorUnits) / Double(widest)

                        ZStack(alignment: .leading) {
                            Capsule().fill(Palette.hairline)
                            Capsule()
                                .fill(Palette.violet)
                                .frame(width: geometry.size.width * fraction)
                        }
                    }
                    .frame(height: 3)
                }
            }
        }
        .padding(16)
        .frostedPanel()
    }
}

struct EmptyMonthView: View {
    let month: YearMonth
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            MonthCurve(dailySpending: Array(repeating: .zero, count: month.dayCount()))
                .frame(height: 60)
                .opacity(0.45)

            Text("Месецът още е празен")
                .font(.amount(24))
                .foregroundStyle(Palette.text)

            Text("Запиши първия разход. Отнема около три секунди и кривата започва да се оформя.")
                .font(.ui(12.5))
                .foregroundStyle(Palette.textDim)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 260)

            Button("Запиши разход", action: onAdd)
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(26)
        .frostedPanel(cornerRadius: 28)
        .padding(24)
    }
}

// MARK: - Общи стилове

extension View {
    /// Матовият панел от мокъпите. Стъкло има само там, където нещо плува —
    /// не навсякъде, иначе екранът става сива каша.
    func frostedPanel(cornerRadius: CGFloat = 20) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return self
            .background(.ultraThinMaterial, in: shape)
            .overlay(shape.stroke(Palette.hairline, lineWidth: 1))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    /// Цветът следва вида на действието: виолетово за разход, ментово за
    /// приход, месинг за заделяне. Бутонът потвърждава избора, преди да е
    /// натиснат.
    var tint: Color = Palette.violet

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.ui(14, weight: .semibold))
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                LinearGradient(
                    colors: [tint.opacity(0.85), tint],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}
