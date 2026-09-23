import SwiftUI

/// Medium family: the featured game beside the next few on the calendar.
struct MediumScheduleView: View {
    let snapshot: ScheduleSnapshot
    let logos: [String: Image]

    private var queue: [Game] { Array(snapshot.upcoming.prefix(3)) }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                FeaturedSectionView(snapshot: snapshot, logos: logos)
            }

            // Falls back to results in the offseason; the left column's
            // "Season complete" heading supplies the context.
            Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(queue.isEmpty ? snapshot.recent : queue) { game in
                    GameRowView(game: game, logo: logos[game.opponent.id])
                }
            }
        }
    }
}
