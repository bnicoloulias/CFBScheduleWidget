import SwiftUI

/// "Tue 9:31 AM" within the week, "10/13 TBD" beyond it or before a time is
/// announced.
struct CompactKickoffTimeView: View {
    let game: Game

    var body: some View {
        HStack(spacing: DrawingConstants.spacing) {
            Text(game.compactDay())
            // Dimmed like KickoffLineView's, so an unannounced time does not
            // read as a confirmed one.
            Text(game.hasConfirmedTime ? game.date.formatted(.dateTime.hour().minute()) : "TBD")
                .foregroundStyle(game.hasConfirmedTime ? .primary : .secondary)
        }
    }

    private enum DrawingConstants {
        static let spacing: Double = 4
    }
}
