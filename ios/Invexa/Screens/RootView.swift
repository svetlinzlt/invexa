import SwiftUI
import InvexaCore

/// Държи навигацията и двата листа за записване. Екраните под него не знаят
/// нищо за таб лентата — така всеки може да се отвори и самостоятелно,
/// включително от виджет или пряк път.
struct RootView: View {
    enum Tab: Hashable {
        case month, ledger, recurring, comparison
    }

    @State private var tab: Tab = .month
    @State private var isAddingFlow = false
    @State private var isAddingRule = false
    @State private var isImporting = false
    @State private var isShowingSettings = false
    @State private var editingFlow: FinancialFlow?
    /// Кой месец гледаме. Държи се тук, за да не се губи при смяна на таб —
    /// иначе прескачането между дневника и разбивката те връща в текущия
    /// месец и се губи мястото, докъдето си стигнал.
    @State private var month = YearMonth(containing: .now)
    @State private var isWelcoming = WelcomeSheet.shouldShow

    @Query private var rules: [StoredRecurringRule]

    var body: some View {
        ZStack {
            Palette.ground.ignoresSafeArea()

            // `.id(month)` е задължително: заявките на екраните се сглобяват
            // в `init` от избрания месец, а SwiftUI пресъздава изгледа само
            // когато самоличността му се смени.
            switch tab {
            case .month:
                MonthScreen(
                    month: month,
                    onAdd: { isAddingFlow = true },
                    onSettings: { isShowingSettings = true },
                    monthControl: { AnyView(MonthStepper(month: $month)) }
                )
                .id(month)
            case .ledger:
                LedgerScreen(
                    month: month,
                    onImport: { isImporting = true },
                    onEdit: { editingFlow = $0 },
                    monthControl: { AnyView(MonthStepper(month: $month)) }
                )
                .id(month)
            case .recurring:
                RecurringScreen(onAdd: { isAddingRule = true })
            case .comparison:
                ComparisonScreen(
                    month: month,
                    onPickMonth: { picked in
                        month = picked
                        tab = .month
                    }
                )
                .id(month)
            }
        }
        .safeAreaInset(edge: .bottom) {
            TabStrip(selection: $tab) { isAddingFlow = true }
        }
        .sheet(isPresented: $isAddingFlow) {
            QuickAddSheet()
                .presentationDetents([.height(430)])
                .presentationBackground(.clear)
        }
        .sheet(isPresented: $isAddingRule) {
            AddRecurringSheet()
                .presentationDetents([.height(520)])
                .presentationBackground(.clear)
        }
        .sheet(isPresented: $isImporting) {
            ImportSheet()
                .presentationDetents([.height(560)])
                .presentationBackground(.clear)
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsScreen()
        }
        .sheet(item: $editingFlow) { flow in
            QuickAddSheet(editing: flow)
                .presentationDetents([.height(470)])
                .presentationBackground(.clear)
        }
        .sheet(isPresented: $isWelcoming) {
            WelcomeSheet()
        }
        // Пренасрочва при всяка промяна в правилата и при първо отваряне.
        // Известие за отменено плащане е по-лошо от липсващо.
        .task(id: rules.count) {
            await Reminders.reschedule(rules: rules.map(\.asRule), calendar: .current)
        }
        .onOpenURL { url in
            // Докосването на виджета води тук. Схемата се обявява в Info.plist
            // под `CFBundleURLTypes`.
            guard url.scheme == "invexa" else { return }
            if url.host == "add" {
                tab = .month
                isAddingFlow = true
            }
        }
    }
}

struct TabStrip: View {
    @Binding var selection: RootView.Tab
    let onAdd: () -> Void

    var body: some View {
        HStack {
            tab("Месец", "square.grid.2x2", .month)
            tab("Дневник", "list.bullet", .ledger)

            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(Palette.ink)
                    .frame(width: 39, height: 39)
                    .background(
                        LinearGradient(
                            colors: [Palette.violetLift, Palette.violet],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                    )
            }
            .accessibilityLabel("Запиши разход")

            tab("Повтарящи", "arrow.triangle.2.circlepath", .recurring)
            tab("Сравнение", "chart.bar", .comparison)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 10)
        .frostedPanel(cornerRadius: 24)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }

    /// `nil` е за екраните, които още не съществуват — бутонът стои, но не
    /// води доникъде и е ясно недостъпен.
    private func tab(_ title: String, _ symbol: String, _ target: RootView.Tab?) -> some View {
        let isActive = target != nil && target == selection

        return Button {
            if let target { selection = target }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol).font(.system(size: 14))
                Text(title).font(.ui(8.5))
            }
            .foregroundStyle(isActive ? Palette.violet : Palette.textFaint)
            .frame(maxWidth: .infinity)
        }
        .disabled(target == nil)
        .opacity(target == nil ? 0.45 : 1)
    }
}
