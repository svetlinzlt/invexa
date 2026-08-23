import SwiftUI
import SwiftData
import InvexaCore

/// Сравнение месец до месец.
///
/// Стълбовете показват истинските месеци, а разликата отдолу се смята на
/// същия ден. Ако сравняваш пълен юли срещу непълен август, август винаги
/// печели и числото те лъже в твоя полза.
struct ComparisonScreen: View {
    private let month: YearMonth
    private let calendar: Calendar
    private let monthCount = 6
    private let onPickMonth: (YearMonth) -> Void

    @Query private var stored: [StoredFlow]

    init(
        month: YearMonth = YearMonth(containing: .now),
        calendar: Calendar = .current,
        onPickMonth: @escaping (YearMonth) -> Void = { _ in }
    ) {
        self.month = month
        self.calendar = calendar
        self.onPickMonth = onPickMonth

        let start = month.advanced(by: -(6 - 1), in: calendar).startDate(in: calendar)
        let end = month.endDate(in: calendar)
        _stored = Query(
            filter: #Predicate<StoredFlow> { $0.date >= start && $0.date < end },
            sort: \StoredFlow.date
        )
    }

    private var today: Int {
        month.dayIndex(of: .now, in: calendar) ?? month.dayCount(in: calendar)
    }

    private var comparison: MonthComparison {
        Comparison.build(
            flows: stored.map(\.asFlow),
            endingAt: month,
            throughDay: today,
            monthCount: monthCount,
            calendar: calendar
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                chart
                if !comparison.categoryDeltas.isEmpty {
                    deltas
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            CapLabel("Последни \(monthCount) месеца")
            Text("Месец до месец")
                .font(.ui(17, weight: .bold))
                .foregroundStyle(Palette.text)
        }
        .padding(.horizontal, 4)
        .padding(.top, 12)
    }

    private var chart: some View {
        VStack(spacing: 15) {
            HStack(alignment: .bottom, spacing: 11) {
                ForEach(comparison.points) { point in
                    // Стълбът е въпрос; докосването отваря отговора —
                    // самия месец с неговите категории и дневник.
                    Button { onPickMonth(point.month) } label: {
                        BarColumn(
                            point: point,
                            peak: comparison.peak,
                            isCurrent: point.month == comparison.current.month,
                            calendar: calendar
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 128)

            verdict
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 17)
        .frostedPanel()
    }

    private var verdict: some View {
        let delta = comparison.delta
        let isBetter = delta.minorUnits <= 0
        let tint = isBetter ? Palette.mint : Palette.violet

        return HStack(spacing: 11) {
            Text(signed(delta))
                .font(.amount(19))
                .foregroundStyle(tint)

            Text(verdictText)
                .font(.ui(10.5))
                .foregroundStyle(Palette.textDim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(tint.opacity(0.26), lineWidth: 1)
        )
    }

    private var verdictText: String {
        guard comparison.previous != nil else {
            return "Още няма с какво да се сравни. Следващият месец ще има."
        }
        let direction = comparison.delta.minorUnits <= 0 ? "под" : "над"
        let average = comparison.averageOfCompleted.formatted()
        return "\(direction) предходния месец на същия ден. Средно за завършените месеци: \(average)."
    }

    private var deltas: some View {
        VStack(alignment: .leading, spacing: 12) {
            CapLabel("Най-голяма промяна")

            ForEach(comparison.categoryDeltas.prefix(4)) { item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(SpendingCategory.named(item.categoryID)?.name ?? item.categoryID)
                            .font(.ui(11.5, weight: .medium))
                            .foregroundStyle(Palette.text)
                        Spacer()
                        Text(signed(item.delta))
                            .font(.ledger(10.5))
                            .foregroundStyle(item.isIncrease ? Palette.violet : Palette.mint)
                    }

                    GeometryReader { geometry in
                        let widest = comparison.categoryDeltas.first.map { abs($0.delta.minorUnits) } ?? 1
                        let fraction = widest == 0 ? 0 : Double(abs(item.delta.minorUnits)) / Double(widest)

                        ZStack(alignment: .leading) {
                            Capsule().fill(Palette.hairline)
                            Capsule()
                                .fill(item.isIncrease ? Palette.violet : Palette.mint)
                                .frame(width: geometry.size.width * fraction)
                        }
                    }
                    .frame(height: 3)
                }
            }
        }
        .padding(16)
        .frostedPanel()
    }

    /// Знакът се показва изрично: „+48" и „−36" се четат по-бързо от цвят
    /// сам по себе си, а и цветът не стига за далтонисти.
    private func signed(_ value: Money) -> String {
        value.minorUnits > 0
            ? "+" + value.formatted()
            : value.formatted()
    }
}

private struct BarColumn: View {
    let point: MonthPoint
    let peak: Money
    let isCurrent: Bool
    let calendar: Calendar

    var body: some View {
        VStack(spacing: 7) {
            Text(point.spent.isZero ? "—" : compact)
                .font(.ledger(9.5))
                .foregroundStyle(Palette.textDim)

            GeometryReader { geometry in
                let fraction = peak.isZero ? 0 : Double(point.spent.minorUnits) / Double(peak.minorUnits)

                VStack {
                    Spacer(minLength: 0)
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(fill)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .stroke(isCurrent ? Palette.violet.opacity(0.55) : Palette.hairline, lineWidth: 1)
                        )
                        // Минимална височина, за да не изчезва месец с малко
                        // похарчено — иначе изглежда като липсващи данни.
                        .frame(height: max(3, geometry.size.height * fraction))
                }
            }

            Text(label)
                .font(.ledger(8.5))
                .tracking(1)
                .foregroundStyle(isCurrent ? Palette.violet : Palette.textFaint)
        }
        .frame(maxWidth: .infinity)
    }

    private var fill: LinearGradient {
        isCurrent
            ? LinearGradient(
                colors: [Palette.violetLift, Palette.violet.opacity(0.3)],
                startPoint: .top, endPoint: .bottom
              )
            : LinearGradient(colors: [Palette.hairline, Palette.hairline], startPoint: .top, endPoint: .bottom)
    }

    /// В стълбовете стотинките само пречат.
    private var compact: String {
        "\(point.spent.minorUnits / 100)"
    }

    private var label: String {
        point.month.startDate(in: calendar)
            .formatted(.dateTime.month(.abbreviated).locale(Locale(identifier: "bg_BG")))
            .uppercased()
    }
}
