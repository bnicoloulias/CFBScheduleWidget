import SwiftUI

/// Score and clock while a game is being played.
struct LiveGameLineView: View {
    let game: Game
    let teamAbbreviation: String

    var body: some View {
        if let scoreLine = game.liveScoreLine(teamAbbreviation: teamAbbreviation) {
            Text(scoreLine)
                .font(.headline)
                .monospacedDigit()
        }

        if let detail = game.statusDetail {
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
