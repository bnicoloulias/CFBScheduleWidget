import Foundation
import Testing

@testable import CollegeFootballSchedule

struct ScheduleSnapshotTests {
    /// 2026-09-22, between the Kent State and Illinois games in the fixture.
    private let midSeason = Date(timeIntervalSince1970: 1_790_000_000)

    @Test func featuresTheNextUnplayedGame() throws {
        let schedule = try Fixture.schedule()
        let snapshot = ScheduleSnapshot(schedule: schedule, now: midSeason)

        #expect(snapshot.featured?.opponent.abbreviation == "ILL")
        #expect(!snapshot.isFeaturedLive)
    }

    @Test func listsRemainingGamesAfterTheFeaturedOne() throws {
        let schedule = try Fixture.schedule()
        let snapshot = ScheduleSnapshot(schedule: schedule, now: midSeason)

        #expect(snapshot.upcoming.map(\.opponent.abbreviation) == ["IOWA"])
        #expect(snapshot.recent.map(\.opponent.abbreviation) == ["BALL"])
    }

    @Test func keepsShowingAGameWhileItIsBeingPlayed() throws {
        let schedule = try Fixture.schedule()
        let illinois = try #require(schedule.games.first { $0.opponent.abbreviation == "ILL" })
        let duringKickoff = illinois.date.addingTimeInterval(45 * 60)

        let snapshot = ScheduleSnapshot(schedule: schedule, now: duringKickoff)

        #expect(snapshot.featured?.id == illinois.id)
        #expect(snapshot.isFeaturedLive)
    }

    @Test func dropsAGameOnceItsWindowHasPassed() throws {
        let schedule = try Fixture.schedule()
        let illinois = try #require(schedule.games.first { $0.opponent.abbreviation == "ILL" })
        let afterward = illinois.date.addingTimeInterval(Schedule.gameWindow + 60)

        let snapshot = ScheduleSnapshot(schedule: schedule, now: afterward)

        #expect(snapshot.featured?.opponent.abbreviation == "IOWA")
        #expect(!snapshot.isFeaturedLive)
    }

    @Test func gathersEveryLogoItWillNeed() throws {
        let schedule = try Fixture.schedule()
        let snapshot = ScheduleSnapshot(schedule: schedule, now: midSeason)

        #expect(Set(snapshot.referencedTeamIDs).contains(Team.defaultID))
        #expect(Set(snapshot.referencedTeamIDs).count == 4)
    }

    @Test func fallsBackToTheLastResultOnceTheSeasonIsOver() throws {
        let schedule = try Fixture.schedule()
        let afterTheSeason = Date(timeIntervalSince1970: 1_800_000_000)  // Jan 2027

        let snapshot = ScheduleSnapshot(schedule: schedule, now: afterTheSeason)

        #expect(snapshot.isSeasonComplete)
        #expect(snapshot.featured?.opponent.abbreviation == "BALL")
        #expect(snapshot.upcoming.isEmpty)
        // The featured game must not also appear in the list below it.
        #expect(!snapshot.recent.contains { $0.id == snapshot.featured?.id })
    }

    @Test func doesNotClaimTheSeasonIsOverMidSeason() throws {
        let schedule = try Fixture.schedule()
        let snapshot = ScheduleSnapshot(schedule: schedule, now: midSeason)

        #expect(!snapshot.isSeasonComplete)
    }
}
