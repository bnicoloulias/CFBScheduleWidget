import Foundation

extension Schedule {
    /// How long a game is assumed to last. College football games run long, so
    /// this is deliberately generous.
    static let gameWindow: TimeInterval = 4 * 60 * 60

    /// The game currently being played, if any.
    func liveGame(asOf now: Date = .now) -> Game? {
        games.first { $0.status == .inProgress } ?? inferredLiveGame(asOf: now)
    }

    /// The soonest game that has not been played yet.
    ///
    /// A game stays "next" for a few hours past kickoff so the widget keeps
    /// showing it while it is being played, even if ESPN is slow to flip the
    /// status to in-progress.
    func nextGame(asOf now: Date = .now) -> Game? {
        upcomingGames(limit: 1, asOf: now).first
    }

    /// Upcoming games, soonest first.
    func upcomingGames(limit: Int, asOf now: Date = .now) -> [Game] {
        let cutoff = now.addingTimeInterval(-Self.gameWindow)
        let upcoming = games.filter { $0.isUpcoming && $0.date > cutoff }.sorted()
        return Array(upcoming.prefix(limit))
    }

    /// Most recently completed games, newest first.
    func recentResults(limit: Int) -> [Game] {
        let completed = games.filter(\.status.isComplete).sorted(by: >)
        return Array(completed.prefix(limit))
    }

    /// The next moment the widget's content could change: kickoff of the next
    /// game, or the end of the window for a game already underway.
    func nextContentChange(asOf now: Date = .now) -> Date? {
        if let live = liveGame(asOf: now) {
            live.date.addingTimeInterval(Self.gameWindow)
        } else {
            nextGame(asOf: now)?.date
        }
    }

    /// ESPN sometimes leaves a game marked scheduled while it is being played.
    /// Treat a confirmed kickoff that is in the recent past as live.
    private func inferredLiveGame(asOf now: Date) -> Game? {
        games.first { game in
            game.status == .scheduled
                && game.hasConfirmedTime
                && game.date <= now
                && now < game.date.addingTimeInterval(Self.gameWindow)
        }
    }
}
