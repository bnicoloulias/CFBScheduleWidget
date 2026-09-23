import SwiftUI
import WidgetKit

/// The schedule widget. Which team it follows is per-widget configuration.
struct CollegeFootballScheduleWidget: Widget {
    private let kind = "CollegeFootballScheduleWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectTeamIntent.self,
            provider: ScheduleTimelineProvider()
        ) { entry in
            ScheduleWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("College Football Schedule")
        .description("The next game for the team you pick, with scores and what's coming up.")
        .supportedFamilies(Self.families)
    }

    /// The Lock Screen families exist only on iOS.
    private static var families: [WidgetFamily] {
        #if os(iOS)
        [.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryInline, .accessoryCircular]
        #else
        [.systemSmall, .systemMedium, .systemLarge]
        #endif
    }
}

// No previews in this file. Xcode hosts a preview in the process that owns the
// file, and macOS cannot launch an app extension as a preview host, so any
// preview in this target fails with "This platform does not support previewing
// widgets". The layouts are previewed from App/Previews/WidgetLayoutPreviews.swift,
// which the app target owns.
