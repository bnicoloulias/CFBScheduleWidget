import Foundation

/// Decides when the widget should next ask for fresh data.
///
/// Lives outside the widget extension so it can be unit tested.
enum WidgetRefreshPolicy {
    /// No usable schedule — retry soon, but not so often that the widget burns
    /// through its refresh budget.
    static let retryInterval: TimeInterval = 20 * 60
    /// While a game is being played.
    static let liveInterval: TimeInterval = 5 * 60
    /// Normal cadence between game days.
    static let idleInterval: TimeInterval = 3 * 60 * 60
    /// Inside this window before kickoff, check more often.
    static let kickoffWindow: TimeInterval = 2 * 60 * 60
    static let kickoffInterval: TimeInterval = 15 * 60

    static func nextRefresh(for snapshot: ScheduleSnapshot?, now: Date) -> Date {
        guard let snapshot else {
            return now.addingTimeInterval(retryInterval)
        }

        if snapshot.isFeaturedLive {
            return now.addingTimeInterval(liveInterval)
        }

        let idle = now.addingTimeInterval(idleInterval)

        // Only a confirmed kickoff is worth waking up for; a TBD placeholder
        // date says nothing about when the game actually starts.
        guard let featured = snapshot.featured,
            featured.hasConfirmedTime,
            featured.date > now
        else { return idle }

        if featured.date.timeIntervalSince(now) < kickoffWindow {
            return min(featured.date, now.addingTimeInterval(kickoffInterval))
        }
        return min(idle, featured.date)
    }
}
