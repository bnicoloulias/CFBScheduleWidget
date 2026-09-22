import SwiftUI

/// One game in the season list.
struct ScheduleRowView: View {
    let game: Game

    var body: some View {
        HStack(spacing: 12) {
            AsyncTeamLogoView(teamID: game.opponent.id, size: 28)

            VStack(alignment: .leading, spacing: 0) {
                Text(game.matchupLine)
                Text(game.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

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
}
