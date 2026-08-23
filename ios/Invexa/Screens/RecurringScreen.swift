import SwiftUI
import SwiftData
import InvexaCore

/// Повтарящите се плащания, подредени по дата на падеж, а не по азбучен ред.
/// Въпросът, на който екранът отговаря, е „какво идва", не „какво имам".
struct RecurringScreen: View {
    private let calendar: Calendar
    private let onAdd: () -> Void

    @Environment(\.modelContext) private var context
    @Query(sort: \StoredRecurringRule.name) private var stored: [StoredRecurringRule]
    @Query private var monthFlows: [StoredFlow]

    init(calendar: Calendar = .current, onAdd: @escaping () -> Void = {}) {
        self.calendar = calendar
        self.onAdd = onAdd

        let month = YearMonth(containing: .now, in: calendar)
        let start = month.startDate(in: calendar)
        let end = month.endDate(in: calendar)
        _monthFlows = Query(
            filter: #Predicate<StoredFlow> { $0.date >= start && $0.date < end }
        )
    }

    /// Дали падежът вече е записан в дневника.
    ///
    /// Приложението **не** създава записи само. Плащане може да се провали
    /// или да е с друга сума, а измислен запис е по-лош от липсващ — той
    /// изглежда като истина. Затова се пита и се записва с едно докосване.
    private func isRecorded(_ charge: UpcomingCharge) -> Bool {
        monthFlows.contains { record in
            record.recurringRuleID == charge.rule.id
                && calendar.isDate(record.date, inSameDayAs: charge.dueDate)
        }
    }

    private func record(_ charge: UpcomingCharge) {
        let flow = FinancialFlow(
            date: charge.dueDate,
            amount: charge.rule.amount,
            merchant: charge.rule.name,
            kind: .expense,
            categoryID: charge.rule.categoryID ?? SpendingCategory.fallbackID,
            recurringRuleID: charge.rule.id
        )
        context.insert(StoredFlow(flow))
        InvexaStore.refreshWidgets()
    }

    private var rules: [RecurringRule] { stored.map(\.asRule) }

    private var upcoming: [UpcomingCharge] {
        let month = YearMonth(containing: .now, in: calendar)
        return Schedule.upcoming(
            rules: rules,
            after: .now,
            until: month.next.endDate(in: calendar),
            calendar: calendar
        )
    }

    /// Платените в този месец. Стоят избледнели вместо да изчезват, за да е
    /// проверима месечната сума отгоре.
    private var alreadyPaid: [UpcomingCharge] {
        let month = YearMonth(containing: .now, in: calendar)
        return Schedule.upcoming(
            rules: rules,
            after: calendar.date(byAdding: .day, value: -1, to: month.startDate(in: calendar)) ?? .now,
            until: .now,
            calendar: calendar
        )
    }

    var body: some View {
        List {
            header
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 12, leading: 4, bottom: 8, trailing: 4))

            if stored.isEmpty {
                emptyState
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                totals
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))

                Section {
                    ForEach(upcoming) { charge in
                        ChargeRow(charge: charge, calendar: calendar, isPaid: false)
                            .listRowBackground(Rectangle().fill(.ultraThinMaterial))
                            .listRowSeparatorTint(Palette.hairline)
                            .listRowInsets(EdgeInsets(top: 10, leading: 13, bottom: 10, trailing: 13))
                            .swipeActions(edge: .trailing) {
                                Button("Спри", role: .destructive) { stop(charge.rule) }
                            }
                    }
                }

                if !alreadyPaid.isEmpty {
                    Section {
                        ForEach(alreadyPaid) { charge in
                            ChargeRow(
                                charge: charge,
                                calendar: calendar,
                                isPaid: isRecorded(charge),
                                onRecord: isRecorded(charge) ? nil : { record(charge) }
                            )
                            .listRowBackground(Rectangle().fill(.ultraThinMaterial))
                            .listRowSeparatorTint(Palette.hairline)
                            .listRowInsets(EdgeInsets(top: 10, leading: 13, bottom: 10, trailing: 13))
                        }
                    } header: {
                        CapLabel("Минали този месец").textCase(nil).padding(.horizontal, 5)
                    }
                }
            }
        }
        .listStyle(.plain)
        .listSectionSpacing(16)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .environment(\.defaultMinListRowHeight, 0)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                CapLabel("Абонаменти и сметки")
                Text("Повтарящи се")
                    .font(.ui(17, weight: .bold))
                    .foregroundStyle(Palette.text)
            }
            Spacer()
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Palette.violet)
            }
            .accessibilityLabel("Добави повтарящо се плащане")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var totals: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                CapLabel("Месечно")
                Text(rules.monthlyLoad().formatted())
                    .font(.amount(27))
                    .foregroundStyle(Palette.text)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                CapLabel("Предстоят")
                Text(Schedule.remainingThisMonth(rules: rules, calendar: calendar).formatted())
                    .font(.amount(27))
                    .foregroundStyle(Palette.violet)
            }
        }
        .padding(17)
        .frostedPanel()
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("Още няма повтарящи се плащания")
                .font(.ui(15, weight: .semibold))
                .foregroundStyle(Palette.text)

            Text("Добави наема, тока и абонаментите. После приложението ще ти казва какво идва, преди да е излязло.")
                .font(.ui(12.5))
                .foregroundStyle(Palette.textDim)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 260)

            Button("Добави плащане", action: onAdd)
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: 240)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }

    /// Спирането пази правилото, но го изважда от сметките. Изтриването би
    /// изкривило историята на месеците, в които плащането наистина е излизало.
    private func stop(_ rule: RecurringRule) {
        guard let match = stored.first(where: { $0.id == rule.id }) else { return }
        match.isActive = false
    }
}

private struct ChargeRow: View {
    let charge: UpcomingCharge
    let calendar: Calendar
    let isPaid: Bool
    /// Показва бутон „Записах го“ за минал падеж, който още не е в дневника.
    var onRecord: (() -> Void)?

    private var daysAway: Int { charge.daysAway(calendar: calendar) }
    /// Жълтото в мокъпите маркира само това, което идва в следващите седем
    /// дни. Ако всичко е маркирано, нищо не е.
    private var isSoon: Bool { !isPaid && daysAway <= 7 }

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 1) {
                Text(charge.dueDate.formatted(.dateTime.day()))
                    .font(.ledger(13.5))
                Text(charge.dueDate.formatted(
                    .dateTime.month(.abbreviated).locale(Locale(identifier: "bg_BG"))
                ))
                .font(.ledger(8))
                .tracking(1)
                .foregroundStyle(Palette.textFaint)
            }
            .frame(width: 33)
            .foregroundStyle(isSoon ? Palette.violet : Palette.text)

            VStack(alignment: .leading, spacing: 1) {
                Text(charge.rule.name)
                    .font(.ui(12, weight: .medium))
                    .foregroundStyle(Palette.text)
                Text(subtitle)
                    .font(.ui(9.5))
                    .foregroundStyle(Palette.textFaint)
            }

            Spacer(minLength: 8)

            if let onRecord {
                Button("Записах го", action: onRecord)
                    .font(.ui(10.5, weight: .semibold))
                    .foregroundStyle(Palette.brass)
                    .buttonStyle(.plain)
            }

            Text(charge.rule.amount.formatted())
                .font(.ledger(12))
                .foregroundStyle(Palette.text)
        }
        .opacity(isPaid ? 0.42 : 1)
    }

    private var subtitle: String {
        let category = SpendingCategory.named(charge.rule.categoryID ?? "")?.name
        let timing: String

        if isPaid {
            timing = "записан"
        } else if onRecord != nil {
            timing = "не е в дневника"
        } else if daysAway == 0 {
            timing = "днес"
        } else if daysAway == 1 {
            timing = "утре"
        } else if daysAway <= 7 {
            timing = "след \(daysAway) дни"
        } else {
            timing = "следващ месец"
        }

        return [timing, category].compactMap { $0 }.joined(separator: " · ")
    }
}
