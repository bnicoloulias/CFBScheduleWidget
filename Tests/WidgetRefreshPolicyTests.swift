import Foundation
import Testing

@testable import CollegeFootballSchedule

struct WidgetRefreshPolicyTests {
    private let now = Date(timeIntervalSince1970: 1_790_000_000)

    @Test func retriesSoonWhenThereIsNothingToShow() {
        let refresh = WidgetRefreshPolicy.nextRefresh(for: nil, now: now)

        #expect(refresh == now.addingTimeInterval(WidgetRefreshPolicy.retryInterval))
    }

    @Test func pollsQuicklyDuringALiveGame() throws {
        let schedule = try Fixture.schedule()
        let illinois = try #require(schedule.games.first { $0.opponent.abbreviation == "ILL" })
        let kickedOff = illinois.date.addingTimeInterval(30 * 60)
        let snapshot = ScheduleSnapshot(schedule: schedule, now: kickedOff)

        let refresh = WidgetRefreshPolicy.nextRefresh(for: snapshot, now: kickedOff)

        #expect(refresh == kickedOff.addingTimeInterval(WidgetRefreshPolicy.liveInterval))
    }

    @Test func wakesUpAtKickoffRatherThanAfterIt() throws {
        let schedule = try Fixture.schedule()
        let illinois = try #require(schedule.games.first { $0.opponent.abbreviation == "ILL" })
        let anHourBefore = illinois.date.addingTimeInterval(-60 * 60)
        let snapshot = ScheduleSnapshot(schedule: schedule, now: anHourBefore)

        let refresh = WidgetRefreshPolicy.nextRefresh(for: snapshot, now: anHourBefore)

        #expect(refresh <= illinois.date)
        #expect(refresh == anHourBefore.addingTimeInterval(WidgetRefreshPolicy.kickoffInterval))
    }

    @Test func fallsBackToTheIdleCadenceBetweenGames() throws {
        let schedule = try Fixture.schedule()
        let snapshot = ScheduleSnapshot(schedule: schedule, now: now)

        let refresh = WidgetRefreshPolicy.nextRefresh(for: snapshot, now: now)

        #expect(refresh == now.addingTimeInterval(WidgetRefreshPolicy.idleInterval))
    }
}
