import SwiftUI

/// "Tue, Oct 6 · 9:31 AM", with the network either on the same line or as a
/// badge beneath it.
struct KickoffDateTimeView: View {
    let game: Game
    let includesNetwork: Bool

    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: DrawingConstants.spacing) {
                Text(game.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                MiddleDotSeparator()
                if game.hasConfirmedTime {
                    Text(game.date, format: .dateTime.hour().minute())
                } else {
                    Text("TBD")
                        .foregroundStyle(.secondary)
                }
                if includesNetwork, let network = game.network {
                    MiddleDotSeparator()
                    Text(network)
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)
            .bold()
            // Wrapping would always "fit" and defeat ViewThatFits.
            .lineLimit(includesNetwork ? 1 : nil)

            if !includesNetwork, let network = game.network {
                Text(network)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(DrawingConstants.badgePadding)
                    .background(.quaternary, in: .rect(cornerRadius: DrawingConstants.badgeCornerRadius))
            }
        }
    }

    private enum DrawingConstants {
        static let spacing: Double = 4
        static let badgePadding: Double = 4
        static let badgeCornerRadius: Double = 4
    }
}
