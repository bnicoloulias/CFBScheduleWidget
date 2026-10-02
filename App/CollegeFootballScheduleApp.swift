import SwiftUI

@main
struct CollegeFootballScheduleApp: App {
    @State private var store = ScheduleStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
        .defaultSize(width: DrawingConstants.defaultWidth, height: DrawingConstants.defaultHeight)
        .commands {
            CommandGroup(after: .toolbar) {
                Button("Refresh Schedule", action: refresh)
                    .keyboardShortcut("r")
            }
        }
    }

    private func refresh() {
        // No team argument: the store already knows which one the window is on.
        Task { await store.load() }
    }

    private enum DrawingConstants {
        static let defaultWidth: Double = 420
        static let defaultHeight: Double = 620
    }
}
