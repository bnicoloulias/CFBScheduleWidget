import SwiftUI

/// Fallback when there is neither a fresh nor a cached schedule to show.
///
/// Deliberately hand-rolled rather than `ContentUnavailableView`, which is
/// built for full app windows and does not lay out inside a widget.
struct ScheduleUnavailableView: View {
    let message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Schedule unavailable", systemImage: "wifi.exclamationmark")
                .font(.headline)
                .lineLimit(2)

            Text(message ?? "Check your connection and try again.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        // Unlike the schedule layouts, this stack has no trailing Spacer, so
        // the frame is the only thing pinning it top-leading. Without it the
        // content centres in both axes.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
    }
}
