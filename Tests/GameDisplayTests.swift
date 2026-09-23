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
}
