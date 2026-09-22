import SwiftUI

/// Kickoff day and time, plus the broadcast network once one is assigned.
struct KickoffLineView: View {
    let game: Game

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
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
