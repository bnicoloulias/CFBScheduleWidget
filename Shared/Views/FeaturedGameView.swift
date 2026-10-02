import SwiftUI

/// The headline block: opponent logo, matchup, and timing for one game.
struct FeaturedGameView: View {
    let game: Game
    let isLive: Bool
    let logo: Image?
    /// The followed team's full name, for the accessibility label.
    let teamName: String
    /// Its short form, for the score line, which sits next to the opponent's.
    let teamAbbreviation: String
    /// Off when the surrounding view already says what state the game is in.
    var showsStatus = true
    /// Uses `CompactKickoffLineView` for the kickoff line.
    var isCompact = false

    private var accessibilityDescription: String {
        var parts = ["\(teamName) \(game.matchupLine)"]
        if let resultLine = game.resultLine {
            parts.append(resultLine)
        } else if game.hasConfirmedTime {
            parts.append(game.date.formatted(date: .abbreviated, time: .shortened))
        } else {
            parts.append("\(game.date.formatted(date: .abbreviated, time: .omitted)), time to be announced")
        }
        if !isLive, !game.status.isComplete, let venue = game.venueName {
            parts.append("at \(venue)")
        }
        if let network = game.network { parts.append("on \(network)") }
        return parts.joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading) {
            if showsStatus {
                GameStatusPill(game: game, isLive: isLive)
            }

            HStack {
                TeamLogoView(image: logo, teamName: game.opponent.fullName, size: AppTheme.logoSize)

                VStack(alignment: .leading) {
                    Text(game.matchupLine)
                        .font(.headline)
                        .lineLimit(2)
                    if game.isNeutralSite, let city = game.venueCity {
                        Text("Neutral site · \(city)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            GameTimingView(game: game, isLive: isLive, teamAbbreviation: teamAbbreviation, isCompact: isCompact)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }
}
