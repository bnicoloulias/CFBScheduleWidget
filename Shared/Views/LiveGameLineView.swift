import SwiftUI

/// The score while a game is being played. The clock sits beside the LIVE
/// pill, in `GameStatusRowView`.
struct LiveGameLineView: View {
    let game: Game
    let teamAbbreviation: String

    var body: some View {
        // Narrower forms rather than shrinking text: the full line is wider
        // than Small's column, and wider than Medium's on smaller iPhones.
        ViewThatFits(in: .horizontal) {
            if let line = game.liveScoreLine(teamAbbreviation: teamAbbreviation) {
                Text(line)
                    .font(.headline)
            }
            if let line = game.liveScoreLine(teamAbbreviation: teamAbbreviation, isCompact: true) {
                Text(line)
                    .font(.subheadline)
                    .bold()
            }
            if let rows = game.liveScoreRows(teamAbbreviation: teamAbbreviation) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(rows.opponent)
                    Text(rows.team)
                }
                .font(.subheadline)
                .bold()
            }
        }
        .lineLimit(1)
        .monospacedDigit()
        // Rolls the digits when a new timeline entry brings a new score.
        .contentTransition(.numericText())
    }
}
