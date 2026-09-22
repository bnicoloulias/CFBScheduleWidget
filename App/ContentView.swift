import SwiftUI

struct ContentView: View {
    @Environment(ScheduleStore.self) private var store
    /// The window's own team. Widgets keep their own configuration.
    @AppStorage("teamID") private var teamID = Team.defaultID
    @State private var isPickingTeam = false

    private var loaded: Schedule? {
        if case .loaded(let schedule) = store.state { return schedule }
        return nil
    }

    var body: some View {
        NavigationStack {
            Group {
                switch store.state {
                case .idle, .loading:
                    ProgressView("Loading schedule…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .loaded(let schedule):
                    SeasonScheduleView(schedule: schedule)
                case .failed(let message):
                    ScheduleErrorView(message: message, retry: reload)
                }
            }
            .navigationTitle(loaded?.teamName ?? "Schedule")
            .toolbar {
                ToolbarItem {
                    Button("Change Team", systemImage: "person.2") {
                        isPickingTeam = true
                    }
                }
                ToolbarItem {
                    Button("Refresh", systemImage: "arrow.clockwise", action: reload)
                }
            }
        }
        .environment(\.teamTheme, TeamTheme(hex: loaded?.teamColor) ?? .fallback)
        .sheet(isPresented: $isPickingTeam) {
            TeamPickerView(teamID: $teamID)
        }
        .task(id: teamID) { await store.load(teamID: teamID) }
    }

    private func reload() {
        Task { await store.load(teamID: teamID) }
    }
}

#Preview {
    ContentView()
        .environment(ScheduleStore())
}
