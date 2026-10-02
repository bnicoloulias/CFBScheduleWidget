import SwiftUI

/// Score and clock while a game is being played.
struct LiveGameLineView: View {
    let game: Game
    let teamAbbreviation: String

    var body: some View {
        if let scoreLine = game.liveScoreLine(teamAbbreviation: teamAbbreviation) {
            // Shrink rather than truncate: the truncated end is the followed
            // team's own score, and iPhone's larger type overflows the Medium
            // widget's half-width column with a four-letter abbreviation.
            Text(scoreLine)
                .font(.headline)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                // Only width may shrink it; a layout short of height would
                // otherwise take it out of the score first.
                .fixedSize(horizontal: false, vertical: true)
        }

        if let detail = game.statusDetail {
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
