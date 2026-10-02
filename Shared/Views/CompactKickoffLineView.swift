import SwiftUI

/// One short kickoff line ("Tue 9:31 AM", or "10/13 TBD"), with the network
/// only if it fits beside it. For a column too narrow and short for
/// `KickoffLineView`.
struct CompactKickoffLineView: View {
    let game: Game

    var body: some View {
        ViewThatFits(in: .horizontal) {
            if let network = game.network {
                HStack(spacing: 4) {
                    CompactKickoffTimeView(game: game)
                    MiddleDotSeparator()
                    Text(network)
                        .foregroundStyle(.secondary)
                }
            }
            CompactKickoffTimeView(game: game)
        }
        .font(.subheadline)
        .bold()
        .lineLimit(1)
    }
}
