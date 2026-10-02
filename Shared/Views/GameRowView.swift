import SwiftUI

/// One compact line in an upcoming-games or recent-results list. A `GridRow`,
/// so it must sit inside a two-column `Grid`.
struct GameRowView: View {
    let game: Game
    let logo: Image?
    /// Date and result on one line instead of stacked, for lists that are
    /// short of height rather than width.
    var showsDateInline = false

    var body: some View {
        GridRow {
            HStack {
                TeamLogoView(image: logo, teamName: game.opponent.fullName, size: AppTheme.smallLogoSize)

                Text(game.matchupLine)
                    .lineLimit(DrawingConstants.matchupLineLimit)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            GameRowTimingView(game: game, isInline: showsDateInline)
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }

    private enum DrawingConstants {
        static let matchupLineLimit: Int = 2
    }
}
