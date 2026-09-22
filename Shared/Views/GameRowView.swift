import SwiftUI

/// One compact line in an upcoming-games or recent-results list.
struct GameRowView: View {
    let game: Game
    let logo: Image?

    var body: some View {
        HStack(spacing: 8) {
            TeamLogoView(image: logo, teamName: game.opponent.fullName, size: AppTheme.smallLogoSize)

            VStack(alignment: .leading, spacing: 0) {
                Text(game.matchupLine)
                    .lineLimit(1)
                Text(game.date, format: .dateTime.month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(game.resultOrKickoffLine)
                .monospacedDigit()
                .foregroundStyle(game.result.map(AppTheme.resultColor) ?? .secondary)
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }
}
