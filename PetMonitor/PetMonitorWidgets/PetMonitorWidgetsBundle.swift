import WidgetKit
import SwiftUI

@main
struct PetMonitorWidgetsBundle: WidgetBundle {
    var body: some Widget {
        DailyTipWidget()
        PetStatusWidget()
    }
}
