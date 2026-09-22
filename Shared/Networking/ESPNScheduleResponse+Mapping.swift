import Foundation

extension ESPNScheduleResponse {
    /// ESPN uses 99 as a sentinel for "unranked" rather than omitting the field.
    private static let unrankedSentinel = 99

    /// Flattens the ESPN payload into the app's own model, from the point of
    /// view of `teamID`. Events missing that team, an opponent, or a usable
    /// date are dropped rather than rendered half-empty.
    func makeSchedule(teamID: String, fetchedAt: Date = .now) -> Schedule {
        Schedule(
            teamID: team.id,
            teamName: team.displayName,
            teamAbbreviation: team.abbreviation ?? team.displayName,
            recordSummary: team.recordSummary,
            standingSummary: team.standingSummary,
            teamColor: team.color,
            seasonLabel: season?.displayName ?? season?.year.map(String.init) ?? "",
            games: events.compactMap { makeGame(event: $0, teamID: teamID) },
            fetchedAt: fetchedAt
        )
    }

    private func makeGame(event: Event, teamID: String) -> Game? {
        guard let competition = event.competitions.first,
            let date = ESPNDate.parse(competition.date ?? event.date),
            let us = competition.competitors.first(where: { $0.team.id == teamID }),
            let them = competition.competitors.first(where: { $0.team.id != teamID })
        else { return nil }

        let statusType = competition.status?.type
        let status = GameStatus(espnName: statusType?.name ?? "")

        return Game(
            id: event.id,
            date: date,
            hasConfirmedTime: event.timeValid ?? false,
            isHome: us.homeAway == "home",
            isNeutralSite: competition.neutralSite ?? false,
            opponent: makeOpponent(them),
            venueName: competition.venue?.fullName,
            venueCity: competition.venue?.address?.city,
            network: competition.broadcasts?.compactMap(\.media?.shortName).first,
            week: event.week?.number,
            status: status,
            statusDetail: statusType?.shortDetail ?? statusType?.detail,
            teamScore: us.score?.points,
            opponentScore: them.score?.points
        )
    }

    private func makeOpponent(_ competitor: Competitor) -> Opponent {
        let team = competitor.team
        let shortName = team.shortDisplayName ?? team.location ?? team.displayName ?? "TBD"
        let rank = competitor.curatedRank?.current

        return Opponent(
            id: team.id,
            name: shortName,
            fullName: team.displayName ?? shortName,
            abbreviation: team.abbreviation ?? shortName,
            rank: (rank.map { $0 > 0 && $0 < Self.unrankedSentinel } ?? false) ? rank : nil
        )
    }
}
