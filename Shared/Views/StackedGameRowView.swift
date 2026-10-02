import SwiftUI

/// A list row with the date and result beneath the opponent rather than
/// beside it, for a column too narrow to split in two.
struct StackedGameRowView: View {
    let game: Game
    let logo: Image?

    var body: some View {
        HStack {
            TeamLogoView(image: logo, teamName: game.opponent.fullName, size: AppTheme.smallLogoSize)

            VStack(alignment: .leading, spacing: 0) {
                Text(game.matchupLine)
                    .lineLimit(1)
                // The time or result matches the date's size, so the line
                // reads as one caption beneath the opponent.
                GameRowTimingView(game: game, isInline: true)
                    .font(.caption)
            }
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
