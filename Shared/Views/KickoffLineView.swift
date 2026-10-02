import SwiftUI

/// Kickoff day and time, the venue, plus the broadcast network once one is
/// assigned.
struct KickoffLineView: View {
    let game: Game
    /// Off when the surrounding view already shows the venue.
    var showsVenue = true

    var body: some View {
        VStack(alignment: .leading) {
            #if os(iOS)
            // iPhone's larger type leaves the Large widget short of height,
            // so the network joins the kickoff line wherever it fits.
            ViewThatFits(in: .horizontal) {
                kickoffLine(includesNetwork: true)
                kickoffLine(includesNetwork: false)
            }
            #else
            kickoffLine(includesNetwork: false)
            #endif

            if showsVenue, let venueName = game.venueName {
                Text(venueName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Without the network inline, it gets a badge on its own line.
    @ViewBuilder private func kickoffLine(includesNetwork: Bool) -> some View {
        VStack(alignment: .leading) {
            HStack(spacing: 4) {
                Text(game.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                separator
                if game.hasConfirmedTime {
                    Text(game.date, format: .dateTime.hour().minute())
                } else {
                    Text("TBD")
                        .foregroundStyle(.secondary)
                }
                if includesNetwork, let network = game.network {
                    separator
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
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: .rect(cornerRadius: 4))
            }
        }
    }

    private var separator: some View {
        Text(verbatim: "·")
            .foregroundStyle(.tertiary)
            .accessibilityHidden(true)
    }
}
