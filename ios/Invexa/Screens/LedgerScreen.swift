import SwiftUI
import SwiftData
import InvexaCore

/// Дневникът. Групиран по дни, с дневна сума в заглавието на всеки ден.
///
/// Построен е върху `List`, а не върху `ScrollView`: плъзгането за изтриване
/// е очакваният жест на iOS и идва наготово само тук. Грешно записан разход
/// трябва да се маха с един жест, не през меню.
struct LedgerScreen: View {
    private let month: YearMonth
    private let calendar: Calendar
    private let onImport: () -> Void
    private let onEdit: (FinancialFlow) -> Void
    private let monthControl: () -> AnyView

    @Environment(\.modelContext) private var context
    @Query private var stored: [StoredFlow]

    init(
        month: YearMonth = YearMonth(containing: .now),
        calendar: Calendar = .current,
        onImport: @escaping () -> Void = {},
        onEdit: @escaping (FinancialFlow) -> Void = { _ in },
        monthControl: @escaping () -> AnyView = { AnyView(EmptyView()) }
    ) {
        self.month = month
        self.calendar = calendar
        self.onImport = onImport
        self.onEdit = onEdit
        self.monthControl = monthControl

        let start = month.startDate(in: calendar)
        let end = month.endDate(in: calendar)
        _stored = Query(
            filter: #Predicate<StoredFlow> { $0.date >= start && $0.date < end },
            sort: \StoredFlow.date,
            order: .reverse
        )
    }

    private var days: [DaySection] {
        DaySection.group(stored.map(\.asFlow), calendar: calendar)
    }

    var body: some View {
        List {
            header
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 12, leading: 4, bottom: 8, trailing: 4))

            if days.isEmpty {
                emptyState
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            ForEach(days) { day in
                Section {
                    ForEach(day.flows) { flow in
                        Button { onEdit(flow) } label: {
                            FlowRow(flow: flow)
                        }
                            .buttonStyle(.plain)
                            .listRowBackground(Rectangle().fill(.ultraThinMaterial))
                            .listRowSeparatorTint(Palette.hairline)
                            .listRowInsets(EdgeInsets(top: 10, leading: 13, bottom: 10, trailing: 13))
                    }
                    .onDelete { offsets in delete(offsets, in: day) }
                } header: {
                    DayHeader(day: day)
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
                monthControl()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Дневник")
                    .font(.ui(17, weight: .bold))
                    .foregroundStyle(Palette.text)
            }
            Spacer()
            Button(action: onImport) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Palette.violet)
            }
            .accessibilityLabel("Внеси извлечение от файл")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        Text("Този месец още няма записи.")
            .font(.ui(13))
            .foregroundStyle(Palette.textDim)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 60)
    }

    private func delete(_ offsets: IndexSet, in day: DaySection) {
        // `offsets` сочи вътре в подредбата на деня, а не в заявката —
        // затова минаваме през идентификаторите, а не през индекси.
        let doomed = offsets.map { day.flows[$0].id }
        for record in stored where doomed.contains(record.id) {
            context.delete(record)
        }
        InvexaStore.refreshWidgets()
    }
}

private struct DayHeader: View {
    let day: DaySection

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            CapLabel(title)
            Spacer()
            Text(total)
                .font(.ledger(9))
                .tracking(1)
                .foregroundStyle(day.net.minorUnits > 0 ? Palette.mint : Palette.textFaint)
        }
        .padding(.horizontal, 5)
        .textCase(nil)
    }

    private var title: String {
        day.date.formatted(
            .dateTime.weekday(.wide).day().month(.wide)
                .locale(Locale(identifier: "bg_BG"))
        )
    }

    /// Дните на плюс се показват със знак — окото ги отделя, без да чете.
    private var total: String {
        day.net.minorUnits > 0
            ? "+" + day.net.formatted()
            : day.spent.formatted()
    }
}

private struct FlowRow: View {
    let flow: FinancialFlow

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: symbol)
                .font(.system(size: 12))
                .foregroundStyle(Palette.textDim)
                .frame(width: 29, height: 29)
                .background(
                    Color.white.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(flow.merchant)
                    .font(.ui(12, weight: .medium))
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.ui(9.5))
                    .foregroundStyle(Palette.textFaint)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(amountText)
                .font(.ledger(12))
                .foregroundStyle(flow.kind == .income ? Palette.mint : Palette.text)
        }
    }

    private var symbol: String {
        switch flow.kind {
        case .income: "arrow.down"
        case .movement: "arrow.left.arrow.right"
        case .expense: "square.grid.2x2"
        }
    }

    private var subtitle: String {
        var parts: [String] = []

        switch flow.kind {
        case .expense:
            // Името на категорията вече е преведено в ядрото.
            parts.append(
                SpendingCategory.named(flow.categoryID ?? "")?.name
                    ?? String(localized: "Друго")
            )
        case .income:
            parts.append(String(localized: "Приход"))
        case .movement:
            parts.append((flow.movement ?? .internalTransfer).name)
        }

        if flow.recurringRuleID != nil { parts.append(String(localized: "повтарящ се")) }
        return parts.joined(separator: " · ")
    }

    /// Движенията се показват без знак — те нито излизат, нито влизат.
    private var amountText: String {
        switch flow.kind {
        case .income: "+" + flow.amount.formatted()
        case .expense: "−" + flow.amount.formatted()
        case .movement: flow.amount.formatted()
        }
    }
}
