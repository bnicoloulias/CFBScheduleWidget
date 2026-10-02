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
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsDateInline {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    date
                    Text(verbatim: "·")
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                    resultOrKickoff
                }
            } else {
                VStack(alignment: .leading) {
                    date
                    resultOrKickoff
                }
            }
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }

    private var date: some View {
        Text(game.date, format: .dateTime.month(.abbreviated).day())
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var resultOrKickoff: some View {
        Text(game.resultOrKickoffLine)
            .monospacedDigit()
            .foregroundStyle(game.result.map(AppTheme.resultColor) ?? .secondary)
    }
}
