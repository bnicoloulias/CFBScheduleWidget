import SwiftUI

/// Large family: record, the featured game, the rest of the slate, and results.
struct LargeScheduleView: View {
    let snapshot: ScheduleSnapshot
    let logos: [String: Image]

    private var queue: [Game] { Array(snapshot.upcoming.prefix(3)) }
    private var results: [Game] { Array(snapshot.recent.prefix(2)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScheduleHeaderView(snapshot: snapshot, logo: logos[snapshot.teamID])

            FeaturedSectionView(snapshot: snapshot, logos: logos)

            if !queue.isEmpty {
                SectionLabel(text: "Upcoming")
                ForEach(queue) { game in
                    GameRowView(game: game, logo: logos[game.opponent.id])
                }
            }

            if !results.isEmpty {
                SectionLabel(text: "Recent")
                ForEach(results) { game in
                    GameRowView(game: game, logo: logos[game.opponent.id])
                }
            }

            Spacer(minLength: 0)
        }
    }
}
