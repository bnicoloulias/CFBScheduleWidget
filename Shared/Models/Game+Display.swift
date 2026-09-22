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
