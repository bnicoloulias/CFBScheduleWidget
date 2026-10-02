import Foundation
import Testing

@testable import CollegeFootballSchedule

struct GameDisplayTests {
    private func illinois() throws -> Game {
        try #require(try Fixture.schedule().games.first { $0.opponent.abbreviation == "ILL" })
    }

    @Test func namesTheDayForAGameThisWeek() throws {
        let game = try illinois()
        let threeDaysBefore = game.date.addingTimeInterval(-3 * 86_400)

        #expect(game.compactDay(now: threeDaysBefore) == game.date.formatted(.dateTime.weekday(.abbreviated)))
    }

    @Test func datesAGameMoreThanAWeekOut() throws {
        let game = try illinois()
        let tenDaysBefore = game.date.addingTimeInterval(-10 * 86_400)

        #expect(game.compactDay(now: tenDaysBefore) == game.date.formatted(.dateTime.month(.defaultDigits).day()))
    }

    @Test func putsTheOpponentFirstInTheLiveScore() throws {
        let game = try #require(try Fixture.schedule().games.first { $0.teamScore != nil })

        let line = try #require(game.liveScoreLine(teamAbbreviation: "OSU"))

        #expect(line.hasPrefix(game.opponent.abbreviation))
        #expect(line.hasSuffix("OSU"))
    }

    @Test func keepsTheScoreboardOrderInTheNarrowForms() throws {
        let game = try #require(try Fixture.schedule().games.first { $0.teamScore != nil })
        let teamScore = try #require(game.teamScore)
        let opponentScore = try #require(game.opponentScore)

        let compact = try #require(game.liveScoreLine(teamAbbreviation: "OSU", isCompact: true))
        let rows = try #require(game.liveScoreRows(teamAbbreviation: "OSU"))

        #expect(compact == "\(game.opponent.abbreviation) \(opponentScore)–\(teamScore) OSU")
        #expect(rows.opponent == "\(game.opponent.abbreviation) \(opponentScore)")
        #expect(rows.team == "OSU \(teamScore)")
    }
}
