import SwiftUI

/// The full season: the featured game on top, then every game in order.
struct SeasonScheduleView: View {
    private let snapshot: ScheduleSnapshot
    private let games: [Game]

    init(schedule: Schedule) {
        snapshot = ScheduleSnapshot(schedule: schedule, upcomingLimit: .max, recentLimit: .max)
        games = schedule.games.sorted()
    }

    var body: some View {
        List {
            Section {
                if let featured = snapshot.featured {
                    NextGameCardView(
                        game: featured,
                        isLive: snapshot.isFeaturedLive,
                        teamAbbreviation: snapshot.teamAbbreviation
                    )
                    .listRowInsets(EdgeInsets())
                }
            } header: {
                Text("\(snapshot.teamName) · \(snapshot.seasonLabel)")
            } footer: {
                SeasonSummaryView(snapshot: snapshot)
            }

            Section("Schedule") {
                ForEach(games) { game in
                    ScheduleRowView(game: game)
                }
            }
        }
        .scrollContentBackground(.visible)
    }
}
