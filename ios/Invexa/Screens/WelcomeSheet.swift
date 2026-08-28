import SwiftUI
import InvexaCore

/// Три екрана при първо отваряне.
///
/// Съществува заради една конкретна причина: разделението разход / движение е
/// разликата на продукта, а нищо не го обясняваше. Нов потребител виждаше три
/// числа и не разбираше защо заделените пари стоят отделно.
///
/// Три страници, не повече, и всяка се пропуска. Обучение, което не може да се
/// прескочи, е стена, а не помощ.
struct WelcomeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    private struct Page {
        let title: LocalizedStringResource
        let body: LocalizedStringResource
        let tint: Color
    }

    private let pages: [Page] = [
        Page(
            title: "Един въпрос",
            body: "Отваряш и виждаш как върви месецът: колко е влязло, колко е излязло, колко остава и къде отиде. Без система, която трябва да учиш.",
            tint: Palette.violet
        ),
        Page(
            title: "Заделеното не е похарчено",
            body: "Парите, които спестяваш или инвестираш, се броят отделно от разходите. Вноска към спестовна сметка не е разход — тя още е твоя. Повечето прости приложения ги смесват и показват грешна картина.",
            tint: Palette.brass
        ),
        Page(
            title: "Три секунди",
            body: "Записваш с ➕ отдолу, през виджет на началния екран или като кажеш на Siri „добави 12 евро обяд“. Колкото по-малко усилие, толкова по-вярна е картината.",
            tint: Palette.mint
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Пропусни") { finish() }
                    .font(.ui(13))
                    .foregroundStyle(Palette.textFaint)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)

            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    pageView(pages[index]).tag(index)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button(page == pages.count - 1 ? "Започни" : "Нататък") {
                if page == pages.count - 1 { finish() }
                else { withAnimation { page += 1 } }
            }
            .buttonStyle(PrimaryButtonStyle(tint: pages[page].tint))
            .padding(20)
        }
        .background(Palette.ground.ignoresSafeArea())
        .interactiveDismissDisabled()
    }

    private func pageView(_ item: Page) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()

            // Знакът на приложението, оцветен според страницата: кривата е
            // единственото, което човек ще види отново на всеки екран.
            MonthCurve(dailySpending: sampleCurve, todayIndex: 20)
                .frame(height: 70)
                .opacity(0.9)

            Text(item.title)
                .font(.amount(28))
                .foregroundStyle(Palette.text)

            Text(item.body)
                .font(.ui(14))
                .foregroundStyle(Palette.textDim)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 26)
    }

    private var sampleCurve: [Money] {
        [88, 22, 14, 41, 30, 18, 55, 26, 12, 34, 47, 20, 29, 63, 16, 24, 38, 44, 58, 31, 27]
            .map { Money(minorUnits: $0 * 100) }
            + Array(repeating: Money.zero, count: 10)
    }

    private func finish() {
        UserDefaults(suiteName: InvexaStore.appGroupID)?
            .set(true, forKey: WelcomeSheet.seenKey)
        dismiss()
    }

    static let seenKey = "welcome.seen"

    /// Показва се само веднъж. Настройката живее в App Group, за да не се
    /// повтори при преинсталиране на разширение.
    static var shouldShow: Bool {
        !(UserDefaults(suiteName: InvexaStore.appGroupID)?.bool(forKey: seenKey) ?? false)
    }
}
