import Observation
import SwiftUI
import WidgetKit

/// Owns the schedule shown in the app window and keeps the widget in step.
///
/// The team is the window's own setting. Widgets carry their own per-instance
/// configuration, so the two are independent by design — a window following
/// one team and two widgets following two others is a valid arrangement.
@MainActor
@Observable
final class ScheduleStore {
    private(set) var state: LoadState = .idle
    private(set) var teamID: String

    private let service = ESPNScheduleService()

    init(teamID: String = Team.defaultID) {
        self.teamID = teamID
    }

    func load() async {
        await load(teamID: teamID)
    }

    func load(teamID: String) async {
        // A team change has to win, or switching mid-load would be ignored.
        if case .loading = state, teamID == self.teamID { return }
        self.teamID = teamID
        state = .loading

        do {
            let schedule = try await service.schedule(teamID: teamID)
            await ScheduleCache.shared.save(schedule)
            // A slow response for a team the user has since moved off would
            // otherwise overwrite the newer one.
            guard teamID == self.teamID else { return }
            state = .loaded(schedule)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            guard teamID == self.teamID else { return }
            // Stale games beat an error screen, so a cached schedule wins over
            // reporting the failure. Only a cold cache surfaces the error.
            if let cached = await ScheduleCache.shared.load(teamID: teamID) {
                state = .loaded(cached)
            } else {
                state = .failed(error.localizedDescription)
            }
        }
    }
}
