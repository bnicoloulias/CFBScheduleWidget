import AppIntents
import OSLog
import WidgetKit

/// Fetches the configured team's schedule and decides how often the widget
/// should come back.
struct ScheduleTimelineProvider: AppIntentTimelineProvider {
    private let service = ESPNScheduleService()
    private let logger = Logger(subsystem: "com.bobbynicoloulias.CollegeFootballSchedule", category: "Timeline")

    func placeholder(in context: Context) -> ScheduleEntry {
        .placeholder
    }

    /// The Edit Widget sheet renders through here with `isPreview` set, so
    /// short-circuiting to `.placeholder` on that flag showed the Ohio State
    /// sample no matter which team was picked. Always honour the configuration;
    /// `makeEntry` already falls back to the cache, so this stays responsive.
    func snapshot(for configuration: SelectTeamIntent, in context: Context) async -> ScheduleEntry {
        print("snapshot teamID=\(configuration.teamID) isPreview=\(context.isPreview)")
        return await makeEntry(teamID: configuration.teamID, family: context.family)
    }

    func timeline(for configuration: SelectTeamIntent, in context: Context) async -> Timeline<ScheduleEntry> {
        print("timeline teamID=\(configuration.teamID)")
        let entry = await makeEntry(teamID: configuration.teamID, family: context.family)
        let refresh = WidgetRefreshPolicy.nextRefresh(for: entry.snapshot, now: entry.date)
        return Timeline(entries: [entry], policy: .after(refresh))
    }

    /// Loads live data, falling back to the last cached schedule so a network
    /// blip never blanks the widget.
    private func makeEntry(teamID: String, family: WidgetFamily, now: Date = .now) async -> ScheduleEntry {
        var schedule: Schedule?
        var message: String?

        do {
            let fetched = try await service.schedule(teamID: teamID)
            await ScheduleCache.shared.save(fetched)
            schedule = fetched
        } catch {
            logger.error("Schedule fetch failed: \(error.localizedDescription, privacy: .public)")
            schedule = await ScheduleCache.shared.load(teamID: teamID)
            if schedule == nil {
                message = ScheduleError.transport(error).errorDescription
            }
        }

        print("makeEntry asked=\(teamID) got=\(schedule?.teamID ?? "nil") name=\(schedule?.teamName ?? "nil")")

        guard let schedule else {
            return ScheduleEntry(date: now, teamID: teamID, snapshot: nil, message: message)
        }

        let limits = Self.listLimits(for: family)
        let snapshot = ScheduleSnapshot(
            schedule: schedule,
            now: now,
            upcomingLimit: limits.upcoming,
            recentLimit: limits.recent
        )
        let logos = await LogoLoader.shared.logos(teamIDs: snapshot.referencedTeamIDs)
        return ScheduleEntry(date: now, teamID: teamID, snapshot: snapshot, logos: logos)
    }

    /// How many rows each family has room for. Fetching logos only for games
    /// that will actually be drawn keeps the timeline entry small.
    private static func listLimits(for family: WidgetFamily) -> (upcoming: Int, recent: Int) {
        switch family {
        case .systemSmall: (0, 1)
        case .systemLarge, .systemExtraLarge: (3, 2)
        default: (3, 3)
        }
    }
}
