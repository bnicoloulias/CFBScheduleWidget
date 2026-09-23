import AppIntents
import SwiftUI
import WidgetKit

/// Picks the layout for the family the system asked for.
struct ScheduleWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ScheduleEntry

    /// ESPN accepts the id-only form, so there is no slug to synthesize.
    private var teamURL: URL {
        URL(string: "https://www.espn.com/college-football/team/_/id/\(entry.teamID)")!
    }

    /// Falls back until a snapshot exists, so the placeholder and the
    /// error state still draw something.
    private var theme: TeamTheme { entry.snapshot?.theme ?? .fallback }

    var body: some View {
        #if os(iOS)
        switch family {
        case .accessoryRectangular, .accessoryInline, .accessoryCircular:
            accessoryBody
        default:
            systemBody
        }
        #else
        systemBody
        #endif
    }

    #if os(iOS)
    /// Lock Screen families. No intent button: a Lock Screen tap always opens
    /// the app, and there is no team colour to paint behind them.
    @ViewBuilder private var accessoryBody: some View {
        Group {
            if let snapshot = entry.snapshot {
                switch family {
                case .accessoryInline:
                    InlineScheduleView(snapshot: snapshot)
                case .accessoryCircular:
                    CircularScheduleView(snapshot: snapshot)
                default:
                    RectangularScheduleView(snapshot: snapshot)
                }
            } else if family == .accessoryCircular {
                Image(systemName: "wifi.exclamationmark")
                    .accessibilityLabel("Schedule unavailable")
            } else {
                Text("Schedule unavailable")
            }
        }
        .containerBackground(for: .widget) {
            if family == .accessoryCircular {
                AccessoryWidgetBackground()
            }
        }
    }
    #endif

    @ViewBuilder private var systemBody: some View {
        // Decoded once here, not inside every TeamLogoView body.
        let logos = LogoImages.decode(entry.logos)

        Button(intent: OpenTeamPageIntent(url: teamURL)) {
            Group {
                if let snapshot = entry.snapshot {
                    switch family {
                    case .systemSmall:
                        SmallScheduleView(snapshot: snapshot, logos: logos)
                    case .systemLarge, .systemExtraLarge:
                        LargeScheduleView(snapshot: snapshot, logos: logos)
                    default:
                        MediumScheduleView(snapshot: snapshot, logos: logos)
                    }
                } else {
                    ScheduleUnavailableView(message: entry.message)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .environment(\.teamTheme, theme)
        .containerBackground(for: .widget) {
            ZStack {
                Rectangle().fill(.fill.tertiary)
                theme.backgroundTint
            }
        }
    }
}
