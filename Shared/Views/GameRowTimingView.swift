import SwiftUI

/// A list row's trailing column: the date over the result or kickoff time,
/// or both on one line.
struct GameRowTimingView: View {
    let game: Game
    let isInline: Bool

    var body: some View {
        let date = Text(game.date, format: .dateTime.month(.abbreviated).day())
            .font(.caption)
            .foregroundStyle(.secondary)
        let resultOrKickoff = Text(game.resultOrKickoffLine)
            .monospacedDigit()
            .foregroundStyle(game.result.map(AppTheme.resultColor) ?? .secondary)

        if isInline {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                date
                MiddleDotSeparator()
                resultOrKickoff
            }
        } else {
            VStack(alignment: .leading) {
                date
                resultOrKickoff
            }
        }
    }
}
