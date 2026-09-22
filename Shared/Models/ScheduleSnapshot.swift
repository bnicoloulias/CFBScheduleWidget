import Foundation

/// The exact set of values a view needs to draw, derived once from a
/// `Schedule` rather than re-filtered every time a body is evaluated.
struct ScheduleSnapshot: Sendable, Hashable {
    let teamID: String
    let teamName: String
    let teamAbbreviation: String
    let recordSummary: String?
    let standingSummary: String?
    let teamColor: String?
    let seasonLabel: String
    /// The game to lead with: the one in progress, otherwise the next one up,
    /// otherwise — once the season is over — the last one played.
    let featured: Game?
    let isFeaturedLive: Bool
    /// True when every game on the published schedule has been played, so the
    /// featured game is a result rather than a fixture.
    let isSeasonComplete: Bool
    /// Upcoming games *after* the featured one, soonest first.
    let upcoming: [Game]
    /// Completed games other than the featured one, newest first.
    let recent: [Game]

    init(schedule: Schedule, now: Date = .now, upcomingLimit: Int = 5, recentLimit: Int = 3) {
        let live = schedule.liveGame(asOf: now)
        let queue = schedule.upcomingGames(limit: .max, asOf: now)
        let completed = schedule.recentResults(limit: .max)
        let featured = live ?? queue.first ?? completed.first

        teamID = schedule.teamID
        teamName = schedule.teamName
        teamAbbreviation = schedule.teamAbbreviation
        recordSummary = schedule.recordSummary
        standingSummary = schedule.standingSummary
        teamColor = schedule.teamColor
        seasonLabel = schedule.seasonLabel
        self.featured = featured
        isFeaturedLive = live != nil
        isSeasonComplete = live == nil && queue.isEmpty && featured != nil

        // The featured game is drawn on its own, so neither list repeats it.
        upcoming = Array(queue.filter { $0.id != featured?.id }.prefix(upcomingLimit))
        recent = Array(completed.filter { $0.id != featured?.id }.prefix(recentLimit))
    }

    /// e.g. "2-1 · 3rd in Big Ten". Empty when ESPN publishes neither, which
    /// happens before a season starts.
    var summaryLine: String {
        [recordSummary, standingSummary]
            .compactMap(\.self)
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    /// The look this team's schedule is drawn in.
    var theme: TeamTheme { TeamTheme(hex: teamColor) ?? .fallback }

    /// Every team whose logo a view might ask for.
    var referencedTeamIDs: [String] {
        var ids = [teamID]
        if let featured { ids.append(featured.opponent.id) }
        ids.append(contentsOf: upcoming.map(\.opponent.id))
        ids.append(contentsOf: recent.map(\.opponent.id))
        return ids
    }
}
