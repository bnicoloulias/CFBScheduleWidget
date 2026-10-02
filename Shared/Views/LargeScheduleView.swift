import SwiftUI

/// Large family: record, the featured game, the rest of the slate, and results.
struct LargeScheduleView: View {
    let snapshot: ScheduleSnapshot
    let logos: [String: Image]

    /// iPhone's larger type fits one result, and only on one line per row.
    private var results: [Game] {
        Array(snapshot.recent.prefix(AppTheme.prefersCompactWidgets ? 1 : 2))
    }

    var body: some View {
        // Results are the first thing to go: clipping would cut the header
        // off the top as well, since the widget centers what overflows.
        ViewThatFits(in: .vertical) {
            LargeScheduleContent(snapshot: snapshot, logos: logos, results: results)
            LargeScheduleContent(snapshot: snapshot, logos: logos, results: [])
        }
    }
}
