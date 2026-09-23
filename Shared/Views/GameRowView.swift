import SwiftUI

/// One compact line in an upcoming-games or recent-results list. A `GridRow`,
/// so it must sit inside a two-column `Grid`.
struct GameRowView: View {
    let game: Game
    let logo: Image?

    var body: some View {
        GridRow {
            HStack {
                TeamLogoView(image: logo, teamName: game.opponent.fullName, size: AppTheme.smallLogoSize)

                Text(game.matchupLine)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading) {
                Text(game.date, format: .dateTime.month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(game.resultOrKickoffLine)
                    .monospacedDigit()
                    .foregroundStyle(game.result.map(AppTheme.resultColor) ?? .secondary)
            }
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }
}
