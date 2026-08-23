import SwiftUI
import InvexaCore

/// Превключване между месеците.
///
/// Продуктът се върти около месеца, но досега показваше само текущия. Щом
/// дойде септември, август ставаше недостижим — а точно тогава човек иска да
/// го погледне, вече завършен.
///
/// Напред не се минава отвъд текущия месец: бъдещето е празно и празният
/// екран изглежда като загубени данни.
struct MonthStepper: View {
    @Binding var month: YearMonth
    var calendar: Calendar = .current

    private var current: YearMonth { YearMonth(containing: .now, in: calendar) }
    private var canGoForward: Bool { month < current }

    var body: some View {
        HStack(spacing: 10) {
            step(back: true)

            Text(label)
                .font(.ledger(9))
                .tracking(1.5)
                .textCase(.uppercase)
                .foregroundStyle(month == current ? Palette.textFaint : Palette.violet)
                .frame(minWidth: 108)
                // Докосване на името връща в текущия месец. По-бързо е от
                // няколко натискания назад, когато си се зачел в март.
                .onTapGesture { if month != current { month = current } }

            step(back: false)
        }
    }

    private func step(back: Bool) -> some View {
        Button {
            month = month.advanced(by: back ? -1 : 1, in: calendar)
        } label: {
            Image(systemName: back ? "chevron.left" : "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Palette.textDim)
                .frame(width: 26, height: 26)
                .contentShape(Rectangle())
        }
        .disabled(back ? false : !canGoForward)
        .opacity(back ? 1 : (canGoForward ? 1 : 0.25))
        .accessibilityLabel(back ? "Предходен месец" : "Следващ месец")
    }

    private var label: String {
        month.startDate(in: calendar)
            .formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "bg_BG")))
    }
}
