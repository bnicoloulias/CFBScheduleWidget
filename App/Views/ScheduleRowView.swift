import SwiftUI

/// One game in the season list.
struct ScheduleRowView: View {
    let game: Game

    var body: some View {
        HStack(spacing: DrawingConstants.spacing) {
            AsyncTeamLogoView(teamID: game.opponent.id, size: DrawingConstants.logoSize)

            VStack(alignment: .leading, spacing: 0) {
                Text(game.matchupLine)
                Text(game.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: DrawingConstants.minimumGap)

            VStack(alignment: .trailing, spacing: 0) {
                Text(game.resultOrKickoffLine)
                    .monospacedDigit()
                    .foregroundStyle(game.result.map(AppTheme.resultColor) ?? .primary)
                if let network = game.network {
                    Text(network)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private enum DrawingConstants {
        static let spacing: Double = 12
        static let logoSize: Double = 28
        static let minimumGap: Double = 8
    }
}
