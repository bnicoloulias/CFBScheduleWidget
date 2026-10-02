import SwiftUI

/// Kickoff day and time, the venue, plus the broadcast network once one is
/// assigned. `CompactKickoffLineView` is the one-line form.
struct KickoffLineView: View {
    let game: Game
    /// Off when the surrounding view already shows the venue.
    var showsVenue = true

    var body: some View {
        VStack(alignment: .leading) {
            if AppTheme.prefersCompactWidgets {
                // The Large widget is short of height on iPhone, so the
                // network joins the kickoff line wherever it fits.
                ViewThatFits(in: .horizontal) {
                    KickoffDateTimeView(game: game, includesNetwork: true)
                    KickoffDateTimeView(game: game, includesNetwork: false)
                }
            } else {
                KickoffDateTimeView(game: game, includesNetwork: false)
            }

            if showsVenue, let venueName = game.venueName {
                Text(venueName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
