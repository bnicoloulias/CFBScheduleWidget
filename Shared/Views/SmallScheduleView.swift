import SwiftUI

/// Small family: just the game that matters next.
struct SmallScheduleView: View {
    let snapshot: ScheduleSnapshot
    let logos: [String: Image]

    #if os(iOS)
    /// iPhone's larger type leaves no room for the full date, the venue,
    /// or a network badge on its own line.
    private static let isCompact = true
    #else
    private static let isCompact = false
    #endif

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FeaturedSectionView(snapshot: snapshot, logos: logos, isCompact: Self.isCompact)
        }
    }
}
