import Foundation
import Testing

@testable import CollegeFootballSchedule

struct ESPNScheduleDecodingTests {
    @Test func decodesTeamSummary() throws {
        let schedule = try Fixture.schedule()

        #expect(schedule.teamID == "194")
        #expect(schedule.teamName == "Ohio State Buckeyes")
        #expect(schedule.teamAbbreviation == "OSU")
        #expect(schedule.recordSummary == "2-1")
        #expect(schedule.standingSummary == "3rd in Big Ten")
        #expect(schedule.games.count == 3)
    }

    @Test func readsCompletedGameFromOhioStatesPerspective() throws {
        let schedule = try Fixture.schedule()
        let game = try #require(schedule.games.first { $0.opponent.abbreviation == "BALL" })

        #expect(game.isHome)
        #expect(game.status == .final)
        #expect(game.teamScore == 56)
        #expect(game.opponentScore == 3)
        #expect(game.result == .win)
        #expect(game.resultLine == "W 56-3")
        #expect(game.network == "BTN")
        #expect(game.venueName == "Ohio Stadium")
    }

    @Test func parsesMinutePrecisionKickoffTimes() throws {
        let schedule = try Fixture.schedule()
        let game = try #require(schedule.games.first { $0.opponent.abbreviation == "ILL" })

        // 2026-09-26T16:00Z
        var components = DateComponents()
        components.year = 2026
        components.month = 9
        components.day = 26
        components.hour = 16
        components.timeZone = TimeZone(identifier: "UTC")
        let expected = try #require(Calendar(identifier: .gregorian).date(from: components))

        #expect(game.date == expected)
        #expect(game.hasConfirmedTime)
        #expect(game.status == .scheduled)
        #expect(game.teamScore == nil)
    }

    @Test func flagsGamesWithoutAnAnnouncedKickoff() throws {
        let schedule = try Fixture.schedule()
        let game = try #require(schedule.games.first { $0.opponent.abbreviation == "IOWA" })

        #expect(!game.hasConfirmedTime)
        #expect(!game.isHome)
        #expect(game.network == nil)
        #expect(game.matchupLine == "at #17 Iowa")
    }

    @Test func treatsEspnsSentinelRankAsUnranked() throws {
        let schedule = try Fixture.schedule()
        let game = try #require(schedule.games.first { $0.opponent.abbreviation == "BALL" })

        // ESPN reports curatedRank 99 for unranked teams rather than omitting it.
        #expect(game.opponent.rank == nil)
        #expect(game.matchupLine == "vs Ball State")
    }
}
