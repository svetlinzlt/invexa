import WidgetKit
import SwiftUI

/// Входната точка на разширението за iPhone.
///
/// Стои отделно от `MonthWidget.swift` нарочно: този файл носи `@main` и е
/// само за iOS, докато самият виджет се споделя и с часовника, който има
/// собствена входна точка.
@main
struct InvexaWidgetBundle: WidgetBundle {
    var body: some Widget {
        MonthWidget()
    }
}
