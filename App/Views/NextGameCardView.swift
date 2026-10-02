import SwiftUI

/// The prominent card at the top of the window.
struct NextGameCardView: View {
    @Environment(\.teamTheme) private var theme

    let game: Game
    let isLive: Bool
    let teamAbbreviation: String

    var body: some View {
        HStack(spacing: DrawingConstants.spacing) {
            AsyncTeamLogoView(teamID: game.opponent.id, size: DrawingConstants.logoSize)

            VStack(alignment: .leading, spacing: DrawingConstants.textSpacing) {
                GameStatusRowView(game: game, isLive: isLive)

                Text(game.matchupLine)
                    .font(.title2)
                    .bold()

                GameTimingView(
                    game: game,
                    isLive: isLive,
                    teamAbbreviation: teamAbbreviation,
                    showsVenue: false
                )

                if let venue = game.venueName {
                    Label(venue, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
        .background {
            ZStack {
                Rectangle().fill(.fill.tertiary)
                theme.backgroundTint
            }
            .clipShape(.rect(cornerRadius: AppTheme.cornerRadius))
        }
    }

    private enum DrawingConstants {
        static let spacing: Double = 16
        static let logoSize: Double = 56
        static let textSpacing: Double = 4
    }
}
