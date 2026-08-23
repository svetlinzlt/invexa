import SwiftUI
import SwiftData
import InvexaCore

/// Настройки.
///
/// Три неща живеят тук по необходимост, не по прищявка: заключването трябва
/// да може да се изключи, научените правила трябва да могат да се поправят, а
/// изтриването на всички данни е изискване, не любезност.
struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \StoredCategoryRule.createdAt, order: .reverse)
    private var learned: [StoredCategoryRule]

    @Query private var flows: [StoredFlow]
    @Query private var rules: [StoredRecurringRule]

    /// Настройката живее в App Group, за да я вижда и `AppLock`.
    @AppStorage("lock.enabled", store: UserDefaults(suiteName: InvexaStore.appGroupID))
    private var lockEnabled = true

    @State private var isConfirmingWipe = false

    var body: some View {
        NavigationStack {
            List {
                lockSection
                learnedSection
                dataSection
                aboutSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Palette.ground.ignoresSafeArea())
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Заключване

    private var lockSection: some View {
        Section {
            Toggle("Заключвай с Face ID", isOn: $lockEnabled)
                .tint(Palette.violet)
        } footer: {
            Text("Приложението показва целия ти месец. Заключването пречи на всеки, който вземе телефона отключен, да го види.")
        }
        .listRowBackground(Color.white.opacity(0.06))
    }

    // MARK: - Научени правила

    private var learnedSection: some View {
        Section {
            if learned.isEmpty {
                Text("Още няма научени правила.")
                    .foregroundStyle(Palette.textFaint)
            } else {
                ForEach(learned) { rule in
                    HStack {
                        Text(rule.pattern)
                            .foregroundStyle(Palette.text)
                            .lineLimit(1)
                        Spacer()
                        Text(SpendingCategory.named(rule.categoryID)?.name ?? rule.categoryID)
                            .font(.ui(12))
                            .foregroundStyle(Palette.textDim)
                    }
                }
                .onDelete { offsets in
                    for index in offsets { context.delete(learned[index]) }
                }
            }
        } header: {
            Text("Научени правила")
        } footer: {
            // Без този екран една грешна поправка се залепва завинаги и
            // приложението продължава да греши, без потребителят да разбира
            // защо.
            Text("Всеки път, когато поправиш категория, приложението го запомня. Тук се виждат тези правила и се махат с плъзгане.")
        }
        .listRowBackground(Color.white.opacity(0.06))
    }

    // MARK: - Данни

    private var dataSection: some View {
        Section {
            LabeledContent("Записи", value: "\(flows.count)")
            LabeledContent("Повтарящи се", value: "\(rules.count)")

            Button("Изтрий всички данни", role: .destructive) {
                isConfirmingWipe = true
            }
        } header: {
            Text("Данни")
        } footer: {
            Text("Данните живеят на телефона ти и в твоя iCloud. Нямам сървър и нямам достъп до тях. Изтриването тук ги маха от всички твои устройства.")
        }
        .listRowBackground(Color.white.opacity(0.06))
        .confirmationDialog(
            "Изтриване на всички данни",
            isPresented: $isConfirmingWipe,
            titleVisibility: .visible
        ) {
            Button("Изтрий всичко", role: .destructive, action: wipe)
            Button("Отказ", role: .cancel) {}
        } message: {
            Text("Изчезват \(flows.count) записа и \(rules.count) повтарящи се плащания. Няма връщане назад.")
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Версия", value: version)
            Link("Пиши ми", destination: URL(string: "mailto:hello@invexa.app")!)
        }
        .listRowBackground(Color.white.opacity(0.06))
    }

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "0.1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    /// Изтрива по тип, а не запис по запис — SwiftData го прави с една
    /// операция и без да зарежда всичко в паметта.
    private func wipe() {
        do {
            try context.delete(model: StoredFlow.self)
            try context.delete(model: StoredRecurringRule.self)
            try context.delete(model: StoredCategoryRule.self)
            try context.save()
            InvexaStore.refreshWidgets()
            dismiss()
        } catch {
            // Ако изтриването се провали, по-честно е да остане както си е,
            // отколкото да затворим екрана и да оставим впечатление, че е
            // минало.
            assertionFailure("Изтриването се провали: \(error)")
        }
    }
}
