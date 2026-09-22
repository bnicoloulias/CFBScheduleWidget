import Foundation
import OSLog

/// The list of teams the configuration picker offers.
///
/// Fetched once and cached on disk. The payload is small enough to hold in
/// memory, but the picker asks on every keystroke, so it must not be a request
/// each time.
actor TeamDirectory {
    static let shared = TeamDirectory()

    struct Entry: Codable, Sendable, Hashable {
        let id: String
        let name: String
        let abbreviation: String
    }

    private let logger = Logger(subsystem: "com.bobbynicoloulias.CollegeFootballSchedule", category: "TeamDirectory")

    private static let endpoint = URL(
        string:
            "https://site.api.espn.com/apis/site/v2/sports/football/college-football/teams?limit=1000")!

    private var entries: [Entry]?

    func all() async -> [Entry] {
        if let entries { return entries }
        if let disk = loadFromDisk() {
            entries = disk
            return disk
        }

        guard let (data, _) = try? await URLSession.shared.data(from: Self.endpoint),
            let decoded = try? JSONDecoder().decode(Response.self, from: data)
        else {
            // An empty picker is better than a failed one; the default team
            // still draws.
            logger.error("Could not load the team directory.")
            return []
        }

        let fetched = decoded.sports
            .flatMap(\.leagues)
            .flatMap(\.teams)
            .map(\.team)
            .map { Entry(id: $0.id, name: $0.displayName, abbreviation: $0.abbreviation ?? "") }
            .sorted { $0.name < $1.name }

        entries = fetched
        saveToDisk(fetched)
        return fetched
    }

    func search(_ text: String) async -> [Entry] {
        let all = await all()
        guard !text.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(text) }
    }

    func entries(ids: [String]) async -> [Entry] {
        let wanted = Set(ids)
        return await all().filter { wanted.contains($0.id) }
    }

    // MARK: - Disk cache

    // Same caches-directory pattern as ScheduleCache.
    private var fileURL: URL? {
        try? FileManager.default
            .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(path: "team-directory.json")
    }

    private func loadFromDisk() -> [Entry]? {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode([Entry].self, from: data)
    }

    private func saveToDisk(_ entries: [Entry]) {
        guard let fileURL else { return }
        do {
            try JSONEncoder().encode(entries).write(to: fileURL, options: .atomic)
        } catch {
            logger.warning("Could not cache the team directory: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Matches sports[0].leagues[0].teams[].team
    private struct Response: Decodable {
        struct Sport: Decodable { let leagues: [League] }
        struct League: Decodable { let teams: [Wrapper] }
        struct Wrapper: Decodable { let team: Payload }
        struct Payload: Decodable {
            let id: String
            let displayName: String
            let abbreviation: String?
        }
        let sports: [Sport]
    }
}
