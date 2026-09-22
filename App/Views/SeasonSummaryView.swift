import SwiftUI

/// Record and conference standing line.
struct SeasonSummaryView: View {
    let snapshot: ScheduleSnapshot

    var body: some View {
        if !snapshot.summaryLine.isEmpty {
            Text(snapshot.summaryLine)
                .font(.callout)
        }
    }
}
