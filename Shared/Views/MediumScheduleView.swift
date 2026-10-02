import SwiftUI

/// Medium family: the featured game beside the next few on the calendar.
struct MediumScheduleView: View {
    let snapshot: ScheduleSnapshot
    let logos: [String: Image]

    private var queue: [Game] { Array(snapshot.upcoming.prefix(DrawingConstants.listRows)) }

    // Falls back to results in the offseason; the left column's
    // "Season complete" heading supplies the context.
    private var listedGames: [Game] { queue.isEmpty ? snapshot.recent : queue }

    var body: some View {
        HStack(alignment: .center, spacing: DrawingConstants.columnSpacing) {
            VStack(alignment: .leading, spacing: DrawingConstants.rowSpacing) {
                FeaturedSectionView(
                    snapshot: snapshot, logos: logos, isCompact: AppTheme.prefersCompactWidgets)
            }

            if AppTheme.prefersCompactWidgets {
                // iPhone's half-width column is too narrow to split, so each
                // game's date goes under its name instead of beside it.
                VStack(alignment: .leading, spacing: DrawingConstants.rowSpacing) {
                    ForEach(listedGames) { game in
                        StackedGameRowView(game: game, logo: logos[game.opponent.id])
                    }
                }
            } else {
                Grid(
                    alignment: .leading,
                    horizontalSpacing: DrawingConstants.rowSpacing,
                    verticalSpacing: DrawingConstants.rowSpacing
                ) {
                    ForEach(listedGames) { game in
                        GameRowView(game: game, logo: logos[game.opponent.id])
                    }
                }
            }
        }
    }

    private enum DrawingConstants {
        static let listRows: Int = 3
        static let columnSpacing: Double = 12
        static let rowSpacing: Double = 8
    }
}
