import SwiftUI

/// The status pill, with the game clock beside it while a game is live.
struct GameStatusRowView: View {
    let game: Game
    let isLive: Bool

    var body: some View {
        HStack(spacing: DrawingConstants.spacing) {
            GameStatusPill(game: game, isLive: isLive)

            if isLive, let detail = game.statusDetail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private enum DrawingConstants {
        static let spacing: Double = 8
    }
}
