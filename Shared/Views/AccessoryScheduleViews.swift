import SwiftUI

// Lock Screen layouts. The system draws these monochrome or tinted over the
// wallpaper, so they carry no logos or team colour — only text, with the
// headline marked accentable so it picks up the user's tint.

/// Rectangular: the matchup, then when it kicks off and where to watch —
/// or the score while it is on, or the result once the season is over.
struct RectangularScheduleView: View {
    let snapshot: ScheduleSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let game = snapshot.featured {
                Text(game.matchupLine)
                    .font(.headline)
                    .widgetAccentable()

                if snapshot.isFeaturedLive {
                    if let score = game.liveScoreLine(teamAbbreviation: snapshot.teamAbbreviation) {
                        Text(score)
                            .monospacedDigit()
                    }
                    if let detail = game.statusDetail {
                        Text(detail)
                            .foregroundStyle(.secondary)
                    }
                } else if let result = game.resultLine {
                    Text(result)
                    if let record = snapshot.recordSummary, !record.isEmpty {
                        Text("Final record \(record)")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text(game.compactKickoffLine())
                    if let network = game.network {
                        Text(network)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text(snapshot.teamName)
                    .font(.headline)
                    .widgetAccentable()
                Text("No games scheduled")
                    .foregroundStyle(.secondary)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// Inline: one line of text above the clock, e.g. "at MICH · Sat 3:30 PM".
/// The system ignores fonts and styling here, so this is only the string.
struct InlineScheduleView: View {
    let snapshot: ScheduleSnapshot

    private var line: String {
        guard let game = snapshot.featured else { return "\(snapshot.teamAbbreviation) · No games" }
        if snapshot.isFeaturedLive, let score = game.liveScoreLine(teamAbbreviation: snapshot.teamAbbreviation) {
            return score
        }
        if let result = game.resultLine {
            return "\(result) \(game.locationPrefix) \(game.opponent.abbreviation)"
        }
        return "\(game.locationPrefix) \(game.opponent.abbreviation) · \(game.compactKickoffLine())"
    }

    var body: some View {
        Text(line)
    }
}

/// Circular: the opponent over the kickoff day, the score while it is on, or
/// the result once it is final.
struct CircularScheduleView: View {
    let snapshot: ScheduleSnapshot

    var body: some View {
        VStack(spacing: 0) {
            if let game = snapshot.featured {
                Text(game.opponent.abbreviation)
                    .font(.headline)
                    .widgetAccentable()

                Group {
                    if snapshot.isFeaturedLive, let teamScore = game.teamScore,
                        let opponentScore = game.opponentScore
                    {
                        Text(verbatim: "\(teamScore)-\(opponentScore)")
                            .monospacedDigit()
                    } else if let result = game.result {
                        Text(result.letter)
                    } else {
                        Text(game.compactDay())
                    }
                }
                .font(.caption)
            } else {
                Text(snapshot.teamAbbreviation)
                    .font(.headline)
                    .widgetAccentable()
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .padding(4)
        .accessibilityElement(children: .combine)
    }
}
