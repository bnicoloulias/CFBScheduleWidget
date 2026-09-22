import SwiftUI

/// The lead block of every widget size: the live, next, or final game.
struct FeaturedSectionView: View {
    let snapshot: ScheduleSnapshot
    let logos: [String: Image]

    var body: some View {
        if let featured = snapshot.featured {
            VStack(alignment: .leading, spacing: 8) {
                if snapshot.isSeasonComplete {
                    SectionLabel(text: "Season complete")
                }

                // With the heading above, the game's own "Final" pill would
                // only repeat it.
                FeaturedGameView(
                    game: featured,
                    isLive: snapshot.isFeaturedLive,
                    logo: logos[featured.opponent.id],
                    teamName: snapshot.teamName,
                    teamAbbreviation: snapshot.teamAbbreviation,
                    showsStatus: !snapshot.isSeasonComplete
                )
            }
        } else {
            NoGamesView(seasonLabel: snapshot.seasonLabel)
        }
    }
}
