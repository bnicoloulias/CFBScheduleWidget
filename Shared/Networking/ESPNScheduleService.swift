import Foundation

/// Fetches a team's schedule from ESPN's public (unauthenticated) JSON feed.
struct ESPNScheduleService: Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// The feed serves whichever season is current; there is no key or quota.
    private static let endpoint = "https://site.api.espn.com/apis/site/v2/sports/football/college-football/teams"

    func schedule(teamID: String) async throws -> Schedule {
        guard let url = URL(string: "\(Self.endpoint)/\(teamID)/schedule") else {
            throw ScheduleError.badURL
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadRevalidatingCacheData
        request.timeoutInterval = 15

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ScheduleError.transport(error)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ScheduleError.badResponse(status: http.statusCode)
        }

        do {
            let decoded = try JSONDecoder().decode(ESPNScheduleResponse.self, from: data)
            return decoded.makeSchedule(teamID: teamID)
        } catch {
            throw ScheduleError.decodingFailed(error)
        }
    }
}
