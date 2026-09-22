import Foundation

@testable import CollegeFootballSchedule

enum Fixture {
    struct MissingFixture: Error {
        let name: String
    }

    static func data(_ name: String) throws -> Data {
        let bundle = Bundle(for: FixtureBundleToken.self)
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw MissingFixture(name: name)
        }
        return try Data(contentsOf: url)
    }

    /// The real ESPN payload, trimmed to three games: a completed one, a
    /// scheduled one with a kickoff time, and a scheduled one still TBD.
    static func schedule() throws -> Schedule {
        let decoded = try JSONDecoder().decode(ESPNScheduleResponse.self, from: data("osu-schedule"))
        return decoded.makeSchedule(teamID: Team.defaultID, fetchedAt: .now)
    }
}
