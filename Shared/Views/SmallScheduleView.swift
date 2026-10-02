import SwiftUI

/// Small family: just the game that matters next.
struct SmallScheduleView: View {
    let snapshot: ScheduleSnapshot
    let logos: [String: Image]

    var body: some View {
        FeaturedSectionView(snapshot: snapshot, logos: logos, isCompact: AppTheme.prefersCompactWidgets)
    }
}
