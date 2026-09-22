import SwiftUI

/// The date/time line for a game: a live clock, a final score, a kickoff time,
/// or "TBD" when ESPN has not announced one yet.
struct GameTimingView: View {
    let game: Game
    let isLive: Bool
    /// Only the live line needs this, but it is the one line that names the
    /// followed team alongside the opponent.
    let teamAbbreviation: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isLive {
                LiveGameLineView(game: game, teamAbbreviation: teamAbbreviation)
            } else if game.status.isComplete {
                FinalScoreLineView(game: game)
            } else {
                KickoffLineView(game: game)
            }
        }
    }
}
