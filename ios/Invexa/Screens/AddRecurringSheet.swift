import SwiftUI
import SwiftData
import InvexaCore

/// Добавяне на повтарящо се плащане.
struct AddRecurringSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var amountText = ""
    @State private var frequency: RecurringRule.Frequency = .monthly
    @State private var anchorDay = 1
    @State private var categoryID = SpendingCategory.fallbackID
    @FocusState private var nameFocused: Bool

    private var amount: Money? { Money(text: amountText) }

    private var canSave: Bool {
        guard let amount, amount.minorUnits > 0 else { return false }
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 14) {
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 4)

            CapLabel("Ново повтарящо се плащане")

            TextField("Например: Наем", text: $name)
                .font(.ui(15))
                .foregroundStyle(Palette.text)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.words)
                .focused($nameFocused)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.06), in: Capsule())

            TextField("0,00", text: $amountText)
                .font(.amount(40))
                .foregroundStyle(Palette.text)
                .multilineTextAlignment(.center)
                .keyboardType(.decimalPad)

            Picker("Колко често", selection: $frequency) {
                Text("Месечно").tag(RecurringRule.Frequency.monthly)
                Text("Седмично").tag(RecurringRule.Frequency.weekly)
                Text("Годишно").tag(RecurringRule.Frequency.yearly)
            }
            .pickerStyle(.segmented)

            dayPicker
            categoryPicker

            Button("Запиши", action: save)
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.5)
        }
        .padding(18)
        .frostedPanel(cornerRadius: 32)
        .padding(10)
        .onAppear { nameFocused = true }
    }

    @ViewBuilder
    private var dayPicker: some View {
        HStack {
            Text(frequency == .weekly ? "Ден от седмицата" : "Ден от месеца")
                .font(.ui(12))
                .foregroundStyle(Palette.textDim)

            Spacer()

            if frequency == .weekly {
                Picker("", selection: $anchorDay) {
                    ForEach(Array(weekdayNames.enumerated()), id: \.offset) { index, title in
                        Text(title).tag(index + 1)
                    }
                }
                .tint(Palette.violet)
            } else {
                Picker("", selection: $anchorDay) {
                    ForEach(1...31, id: \.self) { day in
                        Text("\(day)").tag(day)
                    }
                }
                .tint(Palette.violet)
            }
        }
    }

    /// `Calendar` брои от неделя, затова неделя е първа и тук — иначе изборът
    /// на потребителя ще се разминава с падежа с един ден.
    /// Имената идват от календара на устройството, а не от закован списък:
    /// така се превеждат сами и следват езика, без да се поддържат тук.
    private var weekdayNames: [String] {
        var calendar = Calendar.current
        calendar.locale = .autoupdatingCurrent
        return calendar.standaloneWeekdaySymbols
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                ForEach(SpendingCategory.defaults) { category in
                    let isOn = category.id == categoryID

                    Button {
                        categoryID = category.id
                    } label: {
                        Text(category.name)
                            .font(.ui(10.5, weight: isOn ? .medium : .regular))
                            .foregroundStyle(isOn ? Palette.violetLift : Palette.textDim)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(
                                    isOn ? Palette.violet.opacity(0.2) : Color.white.opacity(0.06)
                                )
                            )
                    }
                }
            }
            .padding(.horizontal, 2)
        }
        .scrollIndicators(.hidden)
    }

    private func save() {
        guard let amount, amount.minorUnits > 0 else { return }

        let rule = RecurringRule(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amount,
            frequency: frequency,
            anchorDay: anchorDay,
            // Годишните плащания се закотвят в месеца, в който се добавят.
            // Редактирането идва по-късно; сега приемаме най-честия случай.
            anchorMonth: frequency == .yearly
                ? Calendar.current.component(.month, from: .now)
                : nil,
            categoryID: categoryID
        )

        context.insert(StoredRecurringRule(rule))
        dismiss()
    }
}
