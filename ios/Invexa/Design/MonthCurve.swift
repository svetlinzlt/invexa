import SwiftUI
import InvexaCore

/// Кривата на месеца — подписът на приложението.
///
/// Дните текат отляво надясно, височината е дневният разход. След днешния ден
/// линията ляга, защото месецът още не се е случил. Точно този плосък участък
/// прави силуета разпознаваем и той се повтаря във виджета и на часовника.
public struct MonthCurve: View {
    private let values: [Double]
    private let todayIndex: Int?

    public init(dailySpending: [Money], todayIndex: Int? = nil) {
        let peak = dailySpending.map(\.minorUnits).max() ?? 0
        self.values = peak == 0
            ? Array(repeating: 0, count: dailySpending.count)
            : dailySpending.map { Double($0.minorUnits) / Double(peak) }
        self.todayIndex = todayIndex
    }

    public var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let path = CurvePath.build(values: values, in: size)

            ZStack(alignment: .topLeading) {
                if values.contains(where: { $0 > 0 }) {
                    CurvePath.filled(values: values, in: size)
                        .fill(Palette.violet.opacity(0.22))
                }

                path.stroke(
                    Palette.violet,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )

                if let todayIndex, values.indices.contains(todayIndex) {
                    let point = CurvePath.point(at: todayIndex, values: values, in: size)

                    Path { line in
                        line.move(to: CGPoint(x: point.x, y: 0))
                        line.addLine(to: CGPoint(x: point.x, y: size.height))
                    }
                    .stroke(
                        Palette.mint.opacity(0.5),
                        style: StrokeStyle(lineWidth: 1, dash: [2, 3])
                    )

                    Circle()
                        .fill(Palette.mint)
                        .frame(width: 7, height: 7)
                        .position(point)
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Дневните разходи за месеца")
    }
}

enum CurvePath {
    static func point(at index: Int, values: [Double], in size: CGSize) -> CGPoint {
        let padding = size.height * 0.12
        let span = size.height - padding * 2
        let step = values.count > 1 ? size.width / CGFloat(values.count - 1) : 0
        return CGPoint(
            x: step * CGFloat(index),
            y: size.height - padding - span * CGFloat(values[index])
        )
    }

    private static func points(_ values: [Double], in size: CGSize) -> [CGPoint] {
        values.indices.map { point(at: $0, values: values, in: size) }
    }

    /// Катмул-Ром през контролни точки на Безие. Дава гладка крива, която не
    /// превишава стойностите — важно е, защото превишението би нарисувало
    /// разход, какъвто не е имало.
    static func build(values: [Double], in size: CGSize) -> Path {
        var path = Path()
        let pts = points(values, in: size)
        guard pts.count > 1 else { return path }

        path.move(to: pts[0])
        for index in 0..<(pts.count - 1) {
            let p0 = index > 0 ? pts[index - 1] : pts[index]
            let p1 = pts[index]
            let p2 = pts[index + 1]
            let p3 = index + 2 < pts.count ? pts[index + 2] : p2

            path.addCurve(
                to: p2,
                control1: CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6),
                control2: CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            )
        }
        return path
    }

    static func filled(values: [Double], in size: CGSize) -> Path {
        var path = build(values: values, in: size)
        guard !path.isEmpty else { return path }
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        path.closeSubpath()
        return path
    }
}
