# Make the widget open the ESPN team page in the default browser

Goal: clicking the Buckeyes Schedule widget opens
<https://www.espn.com/college-football/team/_/id/194/ohio-state-buckeyes>
in the user's default browser.

Current state: no link handling exists anywhere in the project — `widgetURL`,
`onOpenURL`, `NSWorkspace`, and `AppIntent` all have zero hits in the Swift
sources. The widget is a `StaticConfiguration` (`Widget/CollegeFootballScheduleWidget.swift`)
whose content is `ScheduleWidgetEntryView` (`Widget/Views/ScheduleWidgetEntryView.swift`).

---

## Recommended: interactive button + `OpenURLIntent`

Deployment target is macOS 26, so `OpenURLIntent` (macOS 15+) is available. The
system performs the open, so the URL lands in the default browser and the
containing app never launches.

### 1. New file: `Widget/OpenTeamPageIntent.swift`

```swift
import AppIntents
import Foundation

/// Hands a URL to the system so it opens in the default browser.
/// `openAppWhenRun = false` keeps the containing app out of it.
struct OpenTeamPageIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Team Page"
    static let openAppWhenRun = false

    @Parameter(title: "URL") var url: URL

    init() {}

    init(url: URL) {
        self.url = url
    }

    func perform() async throws -> some IntentResult {
        .result(opensIntent: OpenURLIntent(url))
    }
}
```

### 2. Wrap the content in `Widget/Views/ScheduleWidgetEntryView.swift`

Make the whole widget face the tap target by wrapping the existing `Group` in a
`Button` and letting it fill the container:

```swift
import AppIntents
import SwiftUI
import WidgetKit

struct ScheduleWidgetEntryView: View {
    static let teamURL = URL(
        string: "https://www.espn.com/college-football/team/_/id/194/ohio-state-buckeyes"
    )!

    @Environment(\.widgetFamily) private var family
    let entry: ScheduleEntry

    var body: some View {
        let logos = LogoImages.decode(entry.logos)

        Button(intent: OpenTeamPageIntent(url: Self.teamURL)) {
            Group {
                // ...existing switch on `family`, unchanged...
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .containerBackground(for: .widget) {
            ZStack {
                Rectangle().fill(.fill.tertiary)
                BuckeyeTheme.backgroundTint
            }
        }
    }
}
```

Notes:

- `.buttonStyle(.plain)` is what stops the button chrome from repainting the
  layout; without it the widget picks up a bordered look.
- `.frame(maxWidth: .infinity, maxHeight: .infinity)` is what makes the entire
  widget clickable rather than just the text bounds.
- Keep `.containerBackground` on the outside — it belongs to the widget
  container, not the button label.

### 3. Project / build changes

None. `AppIntents` links implicitly from the `import`, `Widget/` is already
listed under the `CollegeFootballScheduleWidget` target's `sources` in `project.yml`, and no
new entitlement is needed — the system opens the URL, not the sandboxed
extension. Just re-run `xcodegen` if you regenerate the project.

---

## Alternative A — the one-line try

```swift
.widgetURL(URL(string: "https://www.espn.com/college-football/team/_/id/194/ohio-state-buckeyes")!)
```

on the entry view. Whole widget clickable, nothing else to change.

Caveat: `widgetURL` is documented as "open the URL **in the containing app**."
The app claims no URL types, so whether macOS falls through to the default
browser is not guaranteed behavior. Worth a two-minute test; don't ship on it
without confirming.

## Alternative B — guaranteed fallback (app relays the open)

Use this if the button route misbehaves. The app window flashes open first,
which is the cost.

1. Widget: `.widgetURL(URL(string: "osusched://team")!)`
2. `App/Info.plist` — register the scheme:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.bobbynicoloulias.CollegeFootballSchedule</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>osusched</string>
        </array>
    </dict>
</array>
```

3. `App/CollegeFootballScheduleApp.swift` — relay to the browser:

```swift
import AppKit

// inside WindowGroup's content modifiers
.onOpenURL { incoming in
    guard incoming.scheme == "osusched" else { return }
    NSWorkspace.shared.open(URL(
        string: "https://www.espn.com/college-football/team/_/id/194/ohio-state-buckeyes"
    )!)
}
```

---

## How to verify

1. Build and run the app once so the widget extension registers.
2. Add the widget from Notification Center / desktop.
3. Click it — the ESPN team page should open in the default browser with no
   app window appearing (recommended approach) or after a brief app launch
   (Alternative B).

Widget extensions cache aggressively; if the click does nothing after a code
change, remove and re-add the widget, or `killall WidgetKit-Simulator chronod`
and re-add.

## Possible follow-up

The same intent takes any URL, so individual rows could deep-link to their own
ESPN game pages later — pass a per-game URL into `OpenTeamPageIntent` instead of
the fixed team URL.
