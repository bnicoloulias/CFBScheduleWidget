#if DEBUG
import SwiftUI

/// Canvas previews for the widget layouts.
///
/// These live in the **app** target on purpose. Xcode picks a preview's host
/// process from the file's target membership, and macOS cannot launch an app
/// extension as a preview host — a preview in the widget target fails with
/// "No plugin is registered to launch the process type widgetExtension".
/// Hosting them in the app sidesteps that entirely; the layouts themselves are
/// in `Shared/Views`, so both targets draw the same code.
enum WidgetLayoutPreviews {
    static func snapshot(upcoming: Int, recent: Int) -> ScheduleSnapshot {
        ScheduleSnapshot(schedule: .sample, upcomingLimit: upcoming, recentLimit: recent)
    }
}

#Preview("Widget — Small") {
    let snapshot = WidgetLayoutPreviews.snapshot(upcoming: 0, recent: 1)

    WidgetPreviewFrame(width: 170, height: 170, theme: snapshot.theme) {
        SmallScheduleView(snapshot: snapshot, logos: LogoImages.decode(PreviewLogos.make(for: snapshot)))
    }
}

#Preview("Widget — Medium") {
    let snapshot = WidgetLayoutPreviews.snapshot(upcoming: 3, recent: 3)

    WidgetPreviewFrame(width: 364, height: 170, theme: snapshot.theme) {
        MediumScheduleView(snapshot: snapshot, logos: LogoImages.decode(PreviewLogos.make(for: snapshot)))
    }
}

#Preview("Widget — Large") {
    let snapshot = WidgetLayoutPreviews.snapshot(upcoming: 3, recent: 2)

    WidgetPreviewFrame(width: 364, height: 382, theme: snapshot.theme) {
        LargeScheduleView(snapshot: snapshot, logos: LogoImages.decode(PreviewLogos.make(for: snapshot)))
    }
}

#Preview("Widget — Offline") {
    // No snapshot means no team colour, which is what the real widget falls
    // back to here.
    WidgetPreviewFrame(width: 364, height: 170) {
        ScheduleUnavailableView(message: "The Internet connection appears to be offline.")
    }
}
#endif
