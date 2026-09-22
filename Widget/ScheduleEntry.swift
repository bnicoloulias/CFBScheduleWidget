import Foundation
import WidgetKit

/// One rendering of the widget. Everything the views draw is resolved here so
/// no view has to touch the network or the disk.
struct ScheduleEntry: TimelineEntry {
    let date: Date
    /// Which team was drawn, so the tap target can deep-link to it.
    let teamID: String
    let snapshot: ScheduleSnapshot?
    /// Downsampled PNG data keyed by ESPN team id.
    let logos: [String: Data]
    /// Shown when there is nothing cached to fall back on.
    let message: String?

    init(
        date: Date = .now,
        teamID: String,
        snapshot: ScheduleSnapshot?,
        logos: [String: Data] = [:],
        message: String? = nil
    ) {
        self.date = date
        self.teamID = teamID
        self.snapshot = snapshot
        self.logos = logos
        self.message = message
    }

    static var placeholder: ScheduleEntry {
        ScheduleEntry(teamID: Team.defaultID, snapshot: ScheduleSnapshot(schedule: .sample))
    }
}
