import SwiftUI

/// The Large layout itself. `LargeScheduleView` tries it with and without
/// results to find one that fits.
struct LargeScheduleContent: View {
    let snapshot: ScheduleSnapshot
    let logos: [String: Image]
    let results: [Game]

    private var queue: [Game] { Array(snapshot.upcoming.prefix(DrawingConstants.upcomingRows)) }

    var body: some View {
        // The spacers carry the gaps, so leftover height spreads between the
        // sections without the stack's spacing adding to what has to fit.
        VStack(alignment: .leading, spacing: 0) {
            ScheduleHeaderView(snapshot: snapshot, logo: logos[snapshot.teamID])

            Spacer(minLength: DrawingConstants.sectionSpacing)

            FeaturedSectionView(snapshot: snapshot, logos: logos)

            Spacer(minLength: DrawingConstants.sectionSpacing)

            Grid(
                alignment: .leading,
                horizontalSpacing: DrawingConstants.gridSpacing,
                verticalSpacing: DrawingConstants.gridSpacing
            ) {
                if !queue.isEmpty {
                    GridRow {
                        SectionLabel(text: "Upcoming")
                            .gridCellColumns(2)
                    }
                    ForEach(queue) { game in
                        GameRowView(
                            game: game, logo: logos[game.opponent.id],
                            showsDateInline: AppTheme.prefersCompactWidgets)
                    }
                }

                if !results.isEmpty {
                    GridRow {
                        SectionLabel(text: "Recent")
                            .gridCellColumns(2)
                    }
                    ForEach(results) { game in
                        GameRowView(
                            game: game, logo: logos[game.opponent.id],
                            showsDateInline: AppTheme.prefersCompactWidgets)
                    }
                }
            }
        }
    }

    private enum DrawingConstants {
        static let upcomingRows: Int = 3
        static let sectionSpacing: Double = 8
        static let gridSpacing: Double = 8
    }
}
