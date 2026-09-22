import SwiftUI

/// Score and clock while a game is being played.
struct LiveGameLineView: View {
    let game: Game
    let teamAbbreviation: String

    private var scoreLine: String? {
        guard let teamScore = game.teamScore, let opponentScore = game.opponentScore else { return nil }
        return "\(game.opponent.abbreviation) \(opponentScore) — \(teamScore) \(teamAbbreviation)"
    }

    var body: some View {
        if let scoreLine {
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
