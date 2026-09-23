#if DEBUG && os(iOS)
import SwiftUI
import WidgetKit

// Real WidgetKit previews: the system's own frame, margins and Lock Screen
// rendering, with a timeline to scrub through. They only render with an iPhone
// destination selected in the canvas — macOS cannot host a widget preview, so
// the Mac layouts stay in App/Previews/WidgetLayoutPreviews.swift.

/// One timeline across a game's life: days out, kickoff, the day after, and
/// the offline fallback.
@MainActor
private enum PreviewTimeline {
    static var entries: [ScheduleEntry] {
        let sample = Schedule.sample
        guard let next = sample.nextGame() else { return [] }

        let live = sample.replacing(next, status: .inProgress, detail: "3rd 8:14", score: (21, 17))
        let played = sample.replacing(next, status: .final, detail: "Final", score: (35, 17))
        let dayAfter = next.date.addingTimeInterval(86_400)

        return [
            entry(sample, at: .now),
            entry(live, at: next.date.addingTimeInterval(90 * 60)),
            entry(played, at: dayAfter),
            ScheduleEntry(
                date: dayAfter, teamID: Team.defaultID, snapshot: nil,
                message: "The Internet connection appears to be offline."),
        ]
    }

    private static func entry(_ schedule: Schedule, at date: Date) -> ScheduleEntry {
        let snapshot = ScheduleSnapshot(schedule: schedule, now: date)
        return ScheduleEntry(
            date: date, teamID: schedule.teamID, snapshot: snapshot, logos: PreviewLogos.make(for: snapshot))
    }
}

extension Schedule {
    /// The same schedule with one game moved along, e.g. from scheduled to live.
    fileprivate func replacing(
        _ game: Game, status: GameStatus, detail: String, score: (team: Int, opponent: Int)
    ) -> Schedule {
        let updated = Game(
            id: game.id, date: game.date, hasConfirmedTime: game.hasConfirmedTime, isHome: game.isHome,
            isNeutralSite: game.isNeutralSite, opponent: game.opponent, venueName: game.venueName,
            venueCity: game.venueCity, network: game.network, week: game.week, status: status,
            statusDetail: detail, teamScore: score.team, opponentScore: score.opponent)

        return Schedule(
            teamID: teamID, teamName: teamName, teamAbbreviation: teamAbbreviation,
            recordSummary: recordSummary, standingSummary: standingSummary, teamColor: teamColor,
            seasonLabel: seasonLabel, games: games.map { $0.id == game.id ? updated : $0 },
            fetchedAt: fetchedAt)
    }
}

#Preview("Small", as: .systemSmall) {
    CollegeFootballScheduleWidget()
} timeline: {
    for entry in PreviewTimeline.entries { entry }
}

#Preview("Medium", as: .systemMedium) {
    CollegeFootballScheduleWidget()
} timeline: {
    for entry in PreviewTimeline.entries { entry }
}

#Preview("Large", as: .systemLarge) {
    CollegeFootballScheduleWidget()
} timeline: {
    for entry in PreviewTimeline.entries { entry }
}

#Preview("Lock Screen — Rectangular", as: .accessoryRectangular) {
    CollegeFootballScheduleWidget()
} timeline: {
    for entry in PreviewTimeline.entries { entry }
}

#Preview("Lock Screen — Inline", as: .accessoryInline) {
    CollegeFootballScheduleWidget()
} timeline: {
    for entry in PreviewTimeline.entries { entry }
}

#Preview("Lock Screen — Circular", as: .accessoryCircular) {
    CollegeFootballScheduleWidget()
} timeline: {
    for entry in PreviewTimeline.entries { entry }
}
#endif
