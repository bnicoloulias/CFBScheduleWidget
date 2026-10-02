import SwiftUI

/// Large family: record, the featured game, the rest of the slate, and results.
struct LargeScheduleView: View {
    let snapshot: ScheduleSnapshot
    let logos: [String: Image]

    #if os(iOS)
    /// iPhone's larger type fits one result, and only on one line per row.
    private static let resultLimit = 1
    private static let showsDateInline = true
    #else
    private static let resultLimit = 2
    private static let showsDateInline = false
    #endif

    private var queue: [Game] { Array(snapshot.upcoming.prefix(3)) }
    private var results: [Game] { Array(snapshot.recent.prefix(Self.resultLimit)) }

    var body: some View {
        // Results are the first thing to go: clipping would cut the header
        // off the top as well, since the widget centers what overflows.
        ViewThatFits(in: .vertical) {
            content(results: results)
            content(results: [])
        }
    }

    private func content(results: [Game]) -> some View {
        // The spacers carry the gaps, so leftover height spreads between the
        // sections without the stack's spacing adding to what has to fit.
        VStack(alignment: .leading, spacing: 0) {
            ScheduleHeaderView(snapshot: snapshot, logo: logos[snapshot.teamID])

            Spacer(minLength: 8)

            FeaturedSectionView(snapshot: snapshot, logos: logos)

            Spacer(minLength: 8)

            Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 8) {
                if !queue.isEmpty {
                    GridRow {
                        SectionLabel(text: "Upcoming")
                            .gridCellColumns(2)
                    }
                    ForEach(queue) { game in
                        GameRowView(game: game, logo: logos[game.opponent.id], showsDateInline: Self.showsDateInline)
                    }
                }

                if !results.isEmpty {
                    GridRow {
                        SectionLabel(text: "Recent")
                            .gridCellColumns(2)
                    }
                    ForEach(results) { game in
                        GameRowView(game: game, logo: logos[game.opponent.id], showsDateInline: Self.showsDateInline)
                    }
                }
            }
        }
    }
}
