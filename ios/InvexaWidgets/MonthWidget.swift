import SwiftUI
import SwiftData
import WidgetKit
import InvexaCore

/// Виджетът чете същата база като приложението през App Group. Работи в
/// отделен процес, затова си прави собствен контекст при всяко обновяване.
struct MonthProvider: TimelineProvider {

    func placeholder(in context: Context) -> MonthEntry {
        MonthEntry.sample
    }

    func getSnapshot(in context: Context, completion: @escaping (MonthEntry) -> Void) {
        completion(context.isPreview ? .sample : load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MonthEntry>) -> Void) {
        // Приложението обновява виджета веднага след всяко записване. Тази
        // граница е само предпазна: в полунощ денят се сменя и кривата трябва
        // да мръдне, дори нищо да не е въведено.
        let midnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
        )
        completion(Timeline(entries: [load()], policy: .after(midnight)))
    }

    private func load() -> MonthEntry {
        let month = YearMonth(containing: .now)

        do {
            let container = try InvexaStore.makeContainer()
            let context = ModelContext(container)
            let flows = try InvexaStore.flows(in: month, context: context)
            return MonthEntry(
                date: .now,
                summary: MonthSummary(month: month, flows: flows),
                todayIndex: month.dayIndex(of: .now).map { $0 - 1 }
            )
        } catch {
            // Празният месец е по-честен от стари данни или от празен
            // правоъгълник без обяснение.
            return MonthEntry(
                date: .now,
                summary: MonthSummary(month: month, flows: []),
                todayIndex: month.dayIndex(of: .now).map { $0 - 1 }
            )
        }
    }
}

struct MonthEntry: TimelineEntry {
    let date: Date
    let summary: MonthSummary
    let todayIndex: Int?

    static var sample: MonthEntry {
        let month = YearMonth(containing: .now)
        let day = month.dayIndex(of: .now) ?? 21

        let flows = (1...day).map { index in
            FinancialFlow.expense(
                Money(euros: 30 + (index * 7) % 45),
                merchant: "Пример",
                on: Calendar.current.date(
                    from: DateComponents(year: month.year, month: month.month, day: index, hour: 12)
                ) ?? .now
            )
        }

        return MonthEntry(
            date: .now,
            summary: MonthSummary(month: month, flows: flows),
            todayIndex: day - 1
        )
    }
}

// MARK: - Изгледи

/// Среден виджет за началния екран.
struct MonthWidgetView: View {
    let entry: MonthEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("ПОХАРЧЕНО")
                        .font(.system(size: 9, weight: .medium))
                        .tracking(1.6)
                        .foregroundStyle(Palette.textFaint)
                    Text(entry.summary.spent.formatted())
                        .font(.amount(30))
                        .foregroundStyle(Palette.text)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Palette.ink)
                    .frame(width: 28, height: 28)
                    .background(Palette.violet, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            MonthCurve(dailySpending: entry.summary.dailySpending, todayIndex: entry.todayIndex)
                .frame(maxHeight: .infinity)
                .padding(.vertical, 6)

            HStack {
                Text("остават")
                    .font(.system(size: 9.5))
                    .foregroundStyle(Palette.textFaint)
                Spacer()
                Text(entry.summary.remaining.formatted())
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(Palette.mint)
            }
        }
    }
}

/// Заключен екран — правоъгълникът под часовника.
struct MonthAccessoryView: View {
    let entry: MonthEntry

    var body: some View {
        HStack(spacing: 8) {
            MonthCurve(dailySpending: entry.summary.dailySpending, todayIndex: entry.todayIndex)
                .frame(width: 42)

            VStack(alignment: .leading, spacing: 1) {
                Text("Похарчено")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text(entry.summary.spent.formatted())
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        // На заключен екран системата налага едноцветно изобразяване;
        // собствената палитра там не се вижда.
        .widgetAccentable()
    }
}

// MARK: - Обявяване

/// Едно и също съдържание в четири размера. Семейството се чете от средата —
/// WidgetKit го подава там, а не в записа.
struct MonthWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MonthEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            MonthAccessoryView(entry: entry)
        case .accessoryInline:
            Text("\(entry.summary.spent.formatted()) този месец")
        default:
            MonthWidgetView(entry: entry)
        }
    }
}

struct MonthWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MonthWidget", provider: MonthProvider()) { entry in
            MonthWidgetEntryView(entry: entry)
                .containerBackground(Palette.ground, for: .widget)
                // Докосването отваря записването. Сума не може да се въведе в
                // самия виджет, затова отваря приложението, а не записва.
                .widgetURL(URL(string: "invexa://add"))
        }
        .configurationDisplayName("Месецът")
        .description("Колко е излязло досега и как върви месецът.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}

@main
struct InvexaWidgets: WidgetBundle {
    var body: some Widget {
        MonthWidget()
    }
}
