import SwiftUI
import SwiftData
import InvexaCore

/// Приложението за Apple Watch.
///
/// Нарочно е малко. Часовникът не е място за въвеждане и разглеждане — той
/// отговаря на един въпрос при вдигане на китката: как върви месецът.
/// Записването остава на телефона, където има клавиатура.
///
/// Данните идват сами през iCloud. Часовникът е отделно устройство и не вижда
/// App Group-а на телефона; CloudKit е мостът между тях и точно затова беше
/// избран още в началото.
@main
struct InvexaWatchApp: App {
    private let container: ModelContainer = {
        do {
            return try InvexaStore.makeContainer()
        } catch {
            fatalError("Хранилището не се отвори: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            WatchMonthView()
        }
        .modelContainer(container)
    }
}

struct WatchMonthView: View {
    private let month = YearMonth(containing: .now)
    private let calendar = Calendar.current

    @Query private var stored: [StoredFlow]

    init() {
        let start = YearMonth(containing: .now).startDate()
        let end = YearMonth(containing: .now).endDate()
        _stored = Query(
            filter: #Predicate<StoredFlow> { $0.date >= start && $0.date < end },
            sort: \StoredFlow.date,
            order: .reverse
        )
    }

    private var summary: MonthSummary {
        MonthSummary(month: month, flows: stored.map(\.asFlow), calendar: calendar)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    CapLabel("Похарчено")
                    Text(summary.spent.formatted())
                        .font(.amount(26))
                        .foregroundStyle(Palette.text)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }

                MonthCurve(
                    dailySpending: summary.dailySpending,
                    todayIndex: month.dayIndex(of: .now, in: calendar).map { $0 - 1 }
                )
                .frame(height: 42)

                Divider()

                row("Влезли", summary.income, Palette.mint)
                row("Заделени", summary.saved + summary.invested, Palette.brass)
                row("Остават", summary.remaining, Palette.text)
            }
            .padding(.horizontal, 4)
        }
        .containerBackground(Palette.ground, for: .navigation)
    }

    private func row(_ title: LocalizedStringResource, _ value: Money, _ tint: Color) -> some View {
        HStack {
            Text(title)
                .font(.ui(12))
                .foregroundStyle(Palette.textDim)
            Spacer()
            Text(value.formatted())
                .font(.ui(12, weight: .semibold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}
