import Foundation
import OSLog

/// Keeps the last successfully fetched schedule on disk so the widget can show
/// real games instead of a placeholder when ESPN is unreachable.
///
/// The app and the widget extension each have their own container, so each
/// keeps its own copy. That costs one extra request per target and avoids
/// needing an App Group (and the provisioning that comes with it).
///
/// Everything is keyed by team, so two widgets following different teams do
/// not overwrite each other.
actor ScheduleCache {
    static let shared = ScheduleCache()

    private let logger = Logger(subsystem: "com.bobbynicoloulias.CollegeFootballSchedule", category: "ScheduleCache")
    private var inMemory: [String: Schedule] = [:]

    private func fileURL(teamID: String) -> URL? {
        try? FileManager.default
            .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(path: "schedule-\(teamID).json")
    }

    func load(teamID: String) -> Schedule? {
        if let cached = inMemory[teamID] { return cached }
        guard let url = fileURL(teamID: teamID),
            let data = try? Data(contentsOf: url),
            let schedule = try? JSONDecoder().decode(Schedule.self, from: data)
        else { return nil }

        inMemory[teamID] = schedule
        return schedule
    }

    /// No team argument needed: the id rides along on the model.
    func save(_ schedule: Schedule) {
        inMemory[schedule.teamID] = schedule
        guard let url = fileURL(teamID: schedule.teamID) else { return }

        do {
            try JSONEncoder().encode(schedule).write(to: url, options: .atomic)
        } catch {
            // A failed cache write only costs freshness on the next launch.
            logger.warning("Could not cache schedule: \(error.localizedDescription, privacy: .public)")
        }
    }
}
