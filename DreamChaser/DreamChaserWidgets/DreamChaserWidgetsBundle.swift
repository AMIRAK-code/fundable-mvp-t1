import SwiftUI
import WidgetKit

@main
struct DreamChaserWidgetsBundle: WidgetBundle {
    var body: some Widget {
        RoutineProgressWidget()
        MomentumWidget()
        QuoteWidget()
        GoalWidget()
        FocusLiveActivity()
    }
}
