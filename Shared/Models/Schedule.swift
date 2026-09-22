import Foundation

/// A team's full season schedule plus the summary lines ESPN ships alongside it.
struct Schedule: Codable, Hashable, Sendable {
    let teamID: String
    /// e.g. "Ohio State Buckeyes".
    let teamName: String
    /// e.g. "OSU".
    let teamAbbreviation: String
    /// e.g. "2-1".
    let recordSummary: String?
    /// e.g. "3rd in Big Ten".
    let standingSummary: String?
    /// The team's primary colour as six hex digits, e.g. "ba0c2f". Optional
    /// because ESPN does not publish one for every team, and because a cache
    /// written before this field existed decodes without it.
    let teamColor: String?
    /// e.g. "2026".
    let seasonLabel: String
    let games: [Game]
    let fetchedAt: Date
}
