import WidgetKit
import SwiftUI

/// Входната точка на усложненията за циферблата.
///
/// Самият `MonthWidget` е споделен с телефона; тук е само `@main`, защото
/// всяка цел има нужда от собствена. Кои семейства се поддържат се решава в
/// `MonthWidget.families` според платформата.
@main
struct InvexaWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        MonthWidget()
    }
}
