import Foundation

extension Schedule {
    /// Stand-in data for widget placeholders and SwiftUI previews, so neither
    /// has to hit the network.
    static var sample: Schedule {
        let now = Date.now

        func game(
            id: String,
            days: Double,
            opponent: Opponent,
            isHome: Bool,
            status: GameStatus = .scheduled,
            hasConfirmedTime: Bool = true,
            network: String? = "FOX",
            teamScore: Int? = nil,
            opponentScore: Int? = nil
        ) -> Game {
            Game(
                id: id,
                date: now.addingTimeInterval(days * 86_400),
                hasConfirmedTime: hasConfirmedTime,
                isHome: isHome,
                isNeutralSite: false,
                opponent: opponent,
                venueName: isHome ? "Ohio Stadium" : nil,
                venueCity: isHome ? "Columbus" : nil,
                network: network,
                week: nil,
                status: status,
                statusDetail: status == .final ? "Final" : nil,
                teamScore: teamScore,
                opponentScore: opponentScore
            )
        }

        return Schedule(
            teamID: Team.defaultID,
            teamName: Team.defaultName,
            teamAbbreviation: "OSU",
            recordSummary: "3-0",
            standingSummary: "1st in Big Ten",
            teamColor: "ba0c2f",
            seasonLabel: "2026",
            games: [
                game(
                    id: "1", days: -14,
                    opponent: Opponent(
                        id: "2050", name: "Ball State", fullName: "Ball State Cardinals", abbreviation: "BALL",
                        rank: nil),
                    isHome: true, status: .final, network: "BTN", teamScore: 56, opponentScore: 3
                ),
                game(
                    id: "2", days: -7,
                    opponent: Opponent(
                        id: "251", name: "Texas", fullName: "Texas Longhorns", abbreviation: "TEX", rank: 5),
                    isHome: false, status: .final, network: "ABC", teamScore: 31, opponentScore: 24
                ),
                game(
                    id: "3", days: 4,
                    opponent: Opponent(
                        id: "356", name: "Illinois", fullName: "Illinois Fighting Illini", abbreviation: "ILL",
                        rank: nil),
                    isHome: true
                ),
                game(
                    id: "4", days: 11,
                    opponent: Opponent(
                        id: "2294", name: "Iowa", fullName: "Iowa Hawkeyes", abbreviation: "IOWA", rank: 17),
                    isHome: false, hasConfirmedTime: false, network: nil
                ),
                game(
                    id: "5", days: 18,
                    opponent: Opponent(
                        id: "120", name: "Maryland", fullName: "Maryland Terrapins", abbreviation: "MD", rank: nil),
                    isHome: true, hasConfirmedTime: false, network: nil
                ),
                game(
                    id: "6", days: 25,
                    opponent: Opponent(
                        id: "130", name: "Michigan", fullName: "Michigan Wolverines", abbreviation: "MICH", rank: 4),
                    isHome: true
                ),
            ],
            fetchedAt: now
        )
    }
}
