import Foundation

/// One game on the schedule, flattened out of ESPN's deeply nested event payload.
struct Game: Identifiable, Codable, Hashable, Sendable {
    let id: String
    /// Kickoff. When `hasConfirmedTime` is false this is a midnight placeholder
    /// ESPN uses before a time is announced, so only the day is meaningful.
    let date: Date
    let hasConfirmedTime: Bool
    let isHome: Bool
    let isNeutralSite: Bool
    let opponent: Opponent
    let venueName: String?
    let venueCity: String?
    /// Broadcast network shorthand, e.g. "FOX". Empty until ESPN assigns a window.
    let network: String?
    let week: Int?
    let status: GameStatus
    /// ESPN's live status line, e.g. "2nd 5:32" or "Final/OT".
    let statusDetail: String?
    let teamScore: Int?
    let opponentScore: Int?
}
