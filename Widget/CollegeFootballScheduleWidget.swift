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
        .configurationDisplayName("CFB Schedule Widget")
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

// Previews: WidgetPreviews.swift for iPhone, where WidgetKit can host them;
// App/Previews/WidgetLayoutPreviews.swift for the Mac, where it cannot.
