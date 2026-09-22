import Foundation

/// Mirrors the shape of ESPN's public team-schedule endpoint.
///
/// Only the fields the widget renders are modelled; everything is optional
/// where ESPN omits it before a game is scheduled or scored.
struct ESPNScheduleResponse: Decodable, Sendable {
    let season: Season?
    let team: TeamInfo
    let events: [Event]

    struct Season: Decodable, Sendable {
        let displayName: String?
        let year: Int?
    }

    struct TeamInfo: Decodable, Sendable {
        let id: String
        let abbreviation: String?
        let displayName: String
        let recordSummary: String?
        let standingSummary: String?
        /// Six hex digits, no leading `#`. ESPN omits it for a minority of
        /// teams, and never sends `alternateColor` on this endpoint.
        let color: String?
    }

    struct Event: Decodable, Sendable {
        let id: String
        let date: String
        /// False while ESPN is still showing the kickoff as TBD.
        let timeValid: Bool?
        let week: Week?
        let competitions: [Competition]

        struct Week: Decodable, Sendable {
            let number: Int?
        }
    }

    struct Competition: Decodable, Sendable {
        let date: String?
        let neutralSite: Bool?
        let venue: Venue?
        let competitors: [Competitor]
        let broadcasts: [Broadcast]?
        let status: Status?
    }

    struct Venue: Decodable, Sendable {
        let fullName: String?
        let address: Address?

        struct Address: Decodable, Sendable {
            let city: String?
            let state: String?
        }
    }

    struct Competitor: Decodable, Sendable {
        let id: String
        let homeAway: String?
        let team: CompetitorTeam
        let score: Score?
        let curatedRank: CuratedRank?

        struct CompetitorTeam: Decodable, Sendable {
            let id: String
            let location: String?
            let displayName: String?
            let shortDisplayName: String?
            let abbreviation: String?
        }

        struct CuratedRank: Decodable, Sendable {
            let current: Int?
        }
    }

    struct Broadcast: Decodable, Sendable {
        let media: Media?

        struct Media: Decodable, Sendable {
            let shortName: String?
        }
    }

    struct Status: Decodable, Sendable {
        let type: StatusType?

        struct StatusType: Decodable, Sendable {
            let name: String?
            let shortDetail: String?
            let detail: String?
        }
    }
}
