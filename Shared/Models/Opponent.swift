import Foundation

/// The other team in a matchup.
struct Opponent: Identifiable, Codable, Hashable, Sendable {
    let id: String
    /// Short school name, e.g. "Michigan".
    let name: String
    /// Full name including nickname, e.g. "Michigan Wolverines".
    let fullName: String
    /// Three-to-five letter code, e.g. "MICH".
    let abbreviation: String
    /// Current AP/CFP ranking, or `nil` when unranked.
    let rank: Int?

    var logoURL: URL? { Team.logoURL(teamID: id) }
}
