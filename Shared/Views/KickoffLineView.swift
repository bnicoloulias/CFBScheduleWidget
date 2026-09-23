import SwiftUI

/// Kickoff day and time, the venue, plus the broadcast network once one is
/// assigned.
struct KickoffLineView: View {
    let game: Game
    /// Off when the surrounding view already shows the venue.
    var showsVenue = true

    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 4) {
                Text(game.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                Text(verbatim: "·")
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
                if game.hasConfirmedTime {
                    Text(game.date, format: .dateTime.hour().minute())
                } else {
                    Text("TBD")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)
            .bold()

            if showsVenue, let venueName = game.venueName {
                Text(venueName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let network = game.network {
                Text(network)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: .rect(cornerRadius: 4))
            }
        }
    }
}
