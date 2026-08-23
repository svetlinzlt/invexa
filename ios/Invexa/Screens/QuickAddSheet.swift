import SwiftUI
import SwiftData
import InvexaCore

/// Записване и редактиране.
///
/// Един екран с два режима, не два почти еднакви екрана. Полетата са същите,
/// а разликата е само в заглавието, в бутона и в наличието на изтриване —
/// това не оправдава дублиране на сто реда.
struct QuickAddSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \StoredCategoryRule.createdAt, order: .reverse)
    private var learned: [StoredCategoryRule]

    private let editing: FinancialFlow?

    @State private var kind: FlowKind
    @State private var movement: MovementKind
    @State private var amountText: String
    @State private var merchant: String
    @State private var categoryID: String
    @State private var date: Date
    @State private var didPickCategory: Bool
    @State private var isPickingDate = false
    @FocusState private var amountFocused: Bool

    init(editing: FinancialFlow? = nil) {
        self.editing = editing

        _kind = State(initialValue: editing?.kind ?? .expense)
        _movement = State(initialValue: editing?.movement ?? .savings)
        _merchant = State(initialValue: editing?.merchant ?? "")
        _categoryID = State(initialValue: editing?.categoryID ?? SpendingCategory.fallbackID)
        _date = State(initialValue: editing?.date ?? .now)
        // При редакция категорията е избрана от човек и не бива да се
        // пренаписва от разпознаването при първата промяна на името.
        _didPickCategory = State(initialValue: editing != nil)

        if let amount = editing?.amount {
            let whole = abs(amount.minorUnits) / 100
            let cents = abs(amount.minorUnits) % 100
            _amountText = State(initialValue: String(format: "%d,%02d", whole, cents))
        } else {
            _amountText = State(initialValue: "")
        }
    }

    private var isEditing: Bool { editing != nil }

    private var categorizer: Categorizer {
        Categorizer(rules: CategoryRule.starterSet + learned.map(\.asRule))
    }

    private var amount: Money? { Money(text: amountText) }
    private var canSave: Bool { (amount?.minorUnits ?? 0) > 0 }

    private var tint: Color {
        switch kind {
        case .expense: Palette.violet
        case .income: Palette.mint
        case .movement: Palette.brass
        }
    }

    var body: some View {
        VStack(spacing: 13) {
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 4)

            kindPicker

            VStack(spacing: 5) {
                // `title` вече е минал през `String(localized:)`.
                CapLabel(verbatim: title)

                TextField("0,00", text: $amountText)
                    .font(.amount(46))
                    .foregroundStyle(Palette.text)
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .focused($amountFocused)
            }

            TextField(placeholder, text: $merchant)
                .font(.ui(15))
                .foregroundStyle(Palette.text)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.words)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.06), in: Capsule())
                .onChange(of: merchant) { _, name in
                    guard kind == .expense, !didPickCategory else { return }
                    categoryID = categorizer.categorize(merchant: name)
                }

            dateRow
            detail

            HStack(spacing: 10) {
                if isEditing {
                    Button(role: .destructive, action: remove) {
                        Image(systemName: "trash")
                            .font(.system(size: 15))
                            .foregroundStyle(Palette.text)
                            .frame(width: 48, height: 46)
                            .background(
                                Color.white.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                            )
                    }
                    .accessibilityLabel("Изтрий записа")
                }

                Button(isEditing ? "Запази" : "Запиши", action: save)
                    .buttonStyle(PrimaryButtonStyle(tint: tint))
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.5)
            }
        }
        .padding(18)
        .frostedPanel(cornerRadius: 32)
        .padding(10)
        .onAppear { if !isEditing { amountFocused = true } }
    }

    // MARK: - Части

    private var kindPicker: some View {
        HStack(spacing: 6) {
            segment("Разход", .expense)
            segment("Приход", .income)
            segment("Заделяне", .movement)
        }
        .padding(3)
        .background(Color.white.opacity(0.06), in: Capsule())
    }

    private func segment(_ title: String, _ value: FlowKind) -> some View {
        let isOn = kind == value

        return Button {
            kind = value
            if !isEditing { didPickCategory = false }
        } label: {
            Text(title)
                .font(.ui(11.5, weight: isOn ? .semibold : .regular))
                .foregroundStyle(isOn ? Palette.ink : Palette.textDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(Capsule().fill(isOn ? tint : Color.clear))
        }
    }

    /// Датата по подразбиране е днес и не иска докосване — бързият път остава
    /// бърз. Но вечер човек наваксва за целия ден, а понякога и за вчера,
    /// затова датата трябва да се сменя.
    private var dateRow: some View {
        Button {
            isPickingDate.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 11))
                Text(dateLabel)
                    .font(.ui(11.5))
            }
            .foregroundStyle(isToday ? Palette.textDim : tint)
        }
        .popover(isPresented: $isPickingDate) {
            DatePicker("Дата", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .presentationCompactAdaptation(.popover)
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch kind {
        case .expense:
            chips(SpendingCategory.defaults.map { ($0.id, $0.name) }, selected: categoryID) { id in
                categoryID = id
                didPickCategory = true
            }

        case .movement:
            chips(
                MovementKind.allCases.map { ($0.rawValue, $0.name) },
                selected: movement.rawValue
            ) { raw in
                movement = MovementKind(rawValue: raw) ?? .savings
            }

        case .income:
            Text("Приходите не се категоризират.")
                .font(.ui(11))
                .foregroundStyle(Palette.textFaint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
    }

    private func chips(
        _ options: [(String, String)],
        selected: String,
        onPick: @escaping (String) -> Void
    ) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                ForEach(options, id: \.0) { id, name in
                    let isOn = id == selected

                    Button { onPick(id) } label: {
                        Text(name)
                            .font(.ui(10.5, weight: isOn ? .medium : .regular))
                            .foregroundStyle(isOn ? tint : Palette.textDim)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(isOn ? tint.opacity(0.2) : Color.white.opacity(0.06))
                            )
                    }
                }
            }
            .padding(.horizontal, 2)
        }
        .scrollIndicators(.hidden)
        .frame(height: 32)
    }

    // MARK: - Текстове

    private var isToday: Bool { Calendar.current.isDateInToday(date) }

    private var dateLabel: String {
        if isToday { return String(localized: "Днес") }
        if Calendar.current.isDateInYesterday(date) { return String(localized: "Вчера") }
        // Датата се форматира по езика на устройството, не по закован локал.
        return date.formatted(.dateTime.day().month(.wide))
    }

    private var title: String {
        switch (isEditing, kind) {
        case (true, _): String(localized: "Редакция")
        case (false, .expense): String(localized: "Нов разход")
        case (false, .income): String(localized: "Нов приход")
        case (false, .movement): String(localized: "Заделяне")
        }
    }

    private var placeholder: String {
        switch kind {
        case .expense: String(localized: "Къде?")
        case .income: String(localized: "Откъде? Например: заплата")
        case .movement: String(localized: "Накъде? Например: спестовна сметка")
        }
    }

    private var defaultName: String {
        switch kind {
        case .expense: String(localized: "Без име")
        case .income: String(localized: "Приход")
        case .movement: String(localized: "Заделено")
        }
    }

    // MARK: - Действия

    private func record(for id: UUID) -> StoredFlow? {
        let descriptor = FetchDescriptor<StoredFlow>(predicate: #Predicate { $0.id == id })
        return try? context.fetch(descriptor).first
    }

    private func save() {
        guard let amount, amount.minorUnits > 0 else { return }

        let name = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        let label = name.isEmpty ? defaultName : name

        let flow = FinancialFlow(
            // При редакция запазваме същия идентификатор, за да не се загубят
            // връзките — например с повтарящото се плащане, което го е родило.
            id: editing?.id ?? UUID(),
            date: date,
            amount: amount,
            merchant: label,
            kind: kind,
            movement: movement,
            categoryID: categoryID,
            recurringRuleID: editing?.recurringRuleID
        )

        if let existing = editing, let target = record(for: existing.id) {
            let updated = StoredFlow(flow)
            target.date = updated.date
            target.minorUnits = updated.minorUnits
            target.merchant = updated.merchant
            target.kindRaw = updated.kindRaw
            target.movementRaw = updated.movementRaw
            target.categoryID = updated.categoryID
        } else {
            context.insert(StoredFlow(flow))
        }

        if kind == .expense, didPickCategory, !name.isEmpty,
           categorizer.categorize(merchant: name) != categoryID {
            context.insert(StoredCategoryRule(pattern: name, categoryID: categoryID))
        }

        InvexaStore.refreshWidgets()
        dismiss()
    }

    private func remove() {
        guard let existing = editing, let target = record(for: existing.id) else { return }
        context.delete(target)
        InvexaStore.refreshWidgets()
        dismiss()
    }
}
