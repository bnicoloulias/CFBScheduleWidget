import Foundation

extension Game {
    /// "vs" for home games, "at" for road games, "vs" for neutral sites
    /// (which get called out separately).
    var locationPrefix: String {
        isNeutralSite ? "vs" : (isHome ? "vs" : "at")
    }

    /// e.g. "vs #4 Michigan" — rank included only when the opponent is ranked.
    var matchupLine: String {
        if let rank = opponent.rank {
            "\(locationPrefix) #\(rank) \(opponent.name)"
        } else {
            "\(locationPrefix) \(opponent.name)"
        }
    }

    var result: GameResult? {
        guard status.isComplete, let teamScore, let opponentScore else { return nil }
        if teamScore > opponentScore { return .win }
        if teamScore < opponentScore { return .loss }
        return .tie
    }

    /// e.g. "W 56-3". `nil` until the game is final.
    var resultLine: String? {
        guard let result, let teamScore, let opponentScore else { return nil }
        return "\(result.letter) \(teamScore)-\(opponentScore)"
    }

    /// The value a schedule row shows at its trailing edge: the final score if
    /// the game is played, the kickoff time if one is confirmed, else "TBD".
    var resultOrKickoffLine: String {
        if let resultLine { return resultLine }
        if hasConfirmedTime { return date.formatted(.dateTime.hour().minute()) }
        return "TBD"
    }

    /// e.g. "MICH 7 — 14 OSU", opponent first as on a scoreboard; `isCompact`
    /// gives "MICH 7–14 OSU" for a narrow column. `nil` until both scores are
    /// known.
    func liveScoreLine(teamAbbreviation: String, isCompact: Bool = false) -> String? {
        guard let teamScore, let opponentScore else { return nil }
        let separator = isCompact ? "–" : " — "
        return "\(opponent.abbreviation) \(opponentScore)\(separator)\(teamScore) \(teamAbbreviation)"
    }

    /// The live score as two scoreboard rows, e.g. ("MICH 7", "OSU 14"), for
    /// a column too narrow for one line. `nil` until both scores are known.
    func liveScoreRows(teamAbbreviation: String) -> (opponent: String, team: String)? {
        guard let teamScore, let opponentScore else { return nil }
        return ("\(opponent.abbreviation) \(opponentScore)", "\(teamAbbreviation) \(teamScore)")
    }

    /// The kickoff day in as few characters as a Lock Screen widget allows:
    /// "Sat" while the game is within the week, "11/29" beyond it.
    func compactDay(now: Date = .now) -> String {
        let daysAway = Calendar.current.dateComponents([.day], from: now, to: date).day ?? .max
        return daysAway < 6
            ? date.formatted(.dateTime.weekday(.abbreviated))
            : date.formatted(.dateTime.month(.defaultDigits).day())
    }

    /// e.g. "Sat 3:30 PM", or "11/29 TBD" before a time is announced.
    func compactKickoffLine(now: Date = .now) -> String {
        let time = hasConfirmedTime ? date.formatted(.dateTime.hour().minute()) : "TBD"
        return "\(compactDay(now: now)) \(time)"
    }

    /// Games in the past that never finished (postponed, canceled) should not
    /// be offered as "next up", but unplayed future games should.
    var isUpcoming: Bool {
        switch status {
        case .scheduled, .inProgress, .postponed: true
        case .final, .canceled: false
        }
    }
}

extension Game: Comparable {
    static func < (lhs: Game, rhs: Game) -> Bool {
        lhs.date < rhs.date
    }
}
