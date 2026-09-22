# Code Guide

What every file does and why it is written the way it is.

If you only read one section, read [The shape of a render](#the-shape-of-a-render)
— the rest of the codebase falls out of that one constraint.

---

## The shape of a render

A widget is not an app. It cannot run a network request while it draws, it
cannot `await` inside a `body`, and it does not get to decide when it appears on
screen. The system asks for a **timeline** — a list of pre-computed renderings,
each stamped with a date — and then draws them later, on its own schedule, with
no chance to fetch anything else.

Everything below follows from that:

```
ESPN JSON  ──►  ESPNScheduleResponse  ──►  Schedule  ──►  ScheduleSnapshot  ──►  ScheduleEntry  ──►  views
  (wire)          (decoding DTO)         (domain model)   (what to draw)      (a frozen render)
```

Each arrow drops something. `ESPNScheduleResponse` throws away the ninety
percent of ESPN's payload nobody needs. `Schedule` flattens nested competitions
into flat games. `ScheduleSnapshot` decides *which* games matter right now.
`ScheduleEntry` adds the pre-fetched logo bytes. By the time a view runs, there
is no decision left to make and no I/O left to do — it reads fields and draws.

The same pipeline feeds the app window, which is why `Shared/` is most of the
code and the two targets are thin.

---

## `Shared/Models/`

Plain values. No SwiftUI, no networking.

### `Team.swift`

The default team, and the logo URL rule.

```swift
enum Team {
    static let defaultID = "194"
    static let defaultName = "Ohio State Buckeyes"
    static func logoURL(teamID: String) -> URL?
}
```

ESPN identifies college teams by numeric id; 194 is Ohio State. Nothing reads
these as *the* team any more — the chosen id travels with the data, from the
widget's `SelectTeamIntent` or the app's `@AppStorage("teamID")` down through
the service, cache, and snapshot. The defaults are only where an unconfigured
widget starts and what previews and tests draw. `logoURL` builds
`a.espncdn.com/i/teamlogos/ncaa/500/<id>.png`, which works for any team id
without a lookup table.

### `GameStatus.swift`

Normalizes ESPN's `STATUS_*` strings into five cases: `scheduled`,
`inProgress`, `final`, `postponed`, `canceled`.

```swift
init(espnName: String) {
    self = switch espnName {
    case "STATUS_IN_PROGRESS", "STATUS_HALFTIME", "STATUS_END_PERIOD": .inProgress
    case "STATUS_FINAL", "STATUS_FINAL_OVERTIME": .final
    ...
    default: .scheduled
    }
}
```

Several ESPN strings collapse into one case — halftime and end-of-quarter are
both "the game is happening". Unknown strings fall through to `.scheduled`
rather than failing to decode, so an ESPN change adds a wrong label instead of
blanking the widget.

`isComplete` is the property the views actually ask, because "show a score"
means `final`, not "not scheduled".

### `GameResult.swift`

`win` / `loss` / `tie`, with a `letter` for the "W 56-3" display.

### `Opponent.swift`

The other team: `id`, `name` ("Michigan"), `fullName` ("Michigan Wolverines"),
`abbreviation` ("MICH"), and `rank`.

`rank` is `Int?` where `nil` means unranked. That is a real translation, not a
pass-through — see the mapper below.

### `Game.swift`

One flat game. The fields that carry non-obvious meaning:

| Field | Why it exists |
| --- | --- |
| `hasConfirmedTime` | When `false`, `date` is a midnight **placeholder** — only the day is real |
| `isNeutralSite` | Neither team is home; the venue gets called out separately |
| `statusDetail` | ESPN's live string, e.g. `"2nd 5:32"` — shown verbatim during a game |
| `teamScore` / `opponentScore` | Already oriented to *our* team, so views never re-derive who is who |

That last point is the reason this type exists at all. ESPN gives you a
`competitors` array and leaves it to you to work out which entry is our team.
Doing that once, at the boundary, means no view ever writes
`competitors.first(where:)`.

### `Game+Display.swift`

Derived strings, kept off the stored model so `Game` stays pure data.

```swift
var locationPrefix: String {
    isNeutralSite ? "vs" : (isHome ? "vs" : "at")
}
```

Neutral-site games read "vs" like home games — "at Michigan" would be wrong for
a bowl game in Dallas — and the neutral venue is surfaced separately by
`FeaturedGameView`.

`matchupLine` produces `"vs #4 Michigan"`, dropping the `#4` when `rank` is nil.
`result` and `resultLine` return nil until the game is `final`, so a view can
write `game.resultLine ?? "TBD"` without also checking status.

`resultOrKickoffLine` is what every schedule row shows at its trailing edge —
the final score, else the kickoff time, else "TBD". It lives here rather than in
a view because both `GameRowView` and `ScheduleRowView` need exactly it.

`isUpcoming` deliberately includes `.postponed`: a postponed game is still
coming, a canceled one is not.

`Game: Comparable` sorts by date, so every list in the app is just `.sorted()`.

### `Schedule.swift`

The season: team identity, `recordSummary` ("2-1"), `standingSummary`
("3rd in Big Ten"), `seasonLabel`, `games`, and `fetchedAt`. `Codable` because
this is exactly what gets written to the disk cache.

### `Schedule+Lookups.swift`

The time-aware queries. The central idea is `gameWindow`:

```swift
static let gameWindow: TimeInterval = 4 * 60 * 60
```

A game does not stop mattering the instant it kicks off. For four hours after
kickoff it is still the game you want on screen. Every lookup here is written
against that window:

- **`nextGame(asOf:)`** — soonest unplayed game, where "unplayed" means
  `date > now - gameWindow`. Without the offset, a widget refreshing at 1pm
  during a noon kickoff would skip to next week.
- **`liveGame(asOf:)`** — a game ESPN marked `inProgress`, *or*
  `inferredLiveGame`: a confirmed kickoff inside the window that ESPN has not
  flipped yet. ESPN is routinely a few minutes late flipping that flag, and
  during those minutes the widget would otherwise show a countdown to a game
  already underway. The inference only applies when `hasConfirmedTime` is true —
  a TBD placeholder date says nothing about whether a game is being played.
- **`recentResults(limit:)`** — completed games, newest first.

### `ScheduleSnapshot.swift`

**The most important type in the codebase.** It answers "what should be on
screen right now" once, so no `body` has to.

```swift
let live = schedule.liveGame(asOf: now)
let queue = schedule.upcomingGames(limit: .max, asOf: now)
let completed = schedule.recentResults(limit: .max)
let featured = live ?? queue.first ?? completed.first
```

That three-step fallback is the whole state machine: a game in progress wins;
otherwise the next one up; otherwise — once the season is over — the last one
played. `isSeasonComplete` records which branch fired, so the views can label a
past game "Season complete" rather than pretending it is upcoming.

The two filters below it matter more than they look:

```swift
upcoming = Array(queue.filter { $0.id != featured?.id }.prefix(upcomingLimit))
recent   = Array(completed.filter { $0.id != featured?.id }.prefix(recentLimit))
```

The featured game is drawn on its own, so excluding it keeps it from appearing
twice — once as the hero, once as the first row underneath. (It did, before
this filter existed.)

`referencedTeamIDs` lists every logo the snapshot will need, which is what lets
the provider fetch exactly those and no more. `summaryLine` joins the record and
standing into `"2-1 · 3rd in Big Ten"`, shared by the widget header and the app
window rather than derived twice.

The `upcomingLimit` / `recentLimit` parameters exist because a small widget
needs one game and the app window needs all of them. Both callers pass what
they can draw.

### `WidgetRefreshPolicy.swift`

When to come back. It lives here, not in `Widget/`, purely so it can be unit
tested — the extension's own types are not reachable from an app-hosted test
bundle.

| Situation | Next refresh |
| --- | --- |
| No schedule at all | 20 min |
| Game in progress | 5 min |
| Confirmed kickoff < 2h away | 15 min, or kickoff, whichever is sooner |
| Otherwise | 3h, or kickoff, whichever is sooner |

```swift
guard let featured = snapshot.featured,
      featured.hasConfirmedTime,
      featured.date > now
else { return idle }
```

The `hasConfirmedTime` check is the subtle one. Waking up for a TBD
placeholder date would schedule a refresh for midnight on a day the game might
start at noon — worse than useless, since WidgetKit budgets refreshes.

### `Schedule+Sample.swift`

A fabricated season used by widget placeholders and `#Preview`. It covers the
cases that are awkward to hit live: finished games with scores, a ranked
opponent, a confirmed kickoff, and TBD games. Nothing in the shipping path
touches the network to render a placeholder.

---

## `Shared/Networking/`

### `ESPNDate.swift`

ESPN stamps games as `"2026-09-05T16:30Z"` — ISO-8601 **without seconds**, which
`Date.ISO8601FormatStyle` and `JSONDecoder.dateDecodingStrategy = .iso8601`
both reject. So three formats are tried in order:

```swift
"yyyy-MM-dd'T'HH:mmZ"
"yyyy-MM-dd'T'HH:mm:ssZ"
"yyyy-MM-dd'T'HH:mm:ss.SSSZ"
```

These are hand-written format strings, which is normally worth avoiding — but
the rule against them is about *display* (where they break localization). This
is wire parsing, pinned to `en_US_POSIX` and UTC, which is exactly what fixed
formats are for.

### `ESPNScheduleResponse.swift`

The decoding DTO, mirroring ESPN's JSON shape and nothing more. Everything is
nested inside the one top-level type (`Event`, `Competition`, `Competitor`,
`Venue`, `Broadcast`, `Status`) so the wire format stays visibly separate from
the domain model.

Nearly every field is optional, because ESPN omits most of them until they
exist: no `broadcasts` until a TV window is assigned, no `score` until the game
is played, no `record` on a future opponent.

### `ESPNScore.swift`

A score arrives as `{"value": 56.0, "displayValue": "56"}` on this endpoint and
as a bare string on others. `Score` implements `init(from:)` to accept either —
single-value container first (double, then string), then the keyed form —
landing on one `points: Int?`.

Without this the decoder would be one ESPN schema tweak away from throwing and
blanking the widget.

### `ESPNScheduleResponse+Mapping.swift`

Wire → domain. The interesting part is what it refuses to accept:

```swift
guard let competition = event.competitions.first,
      let date = ESPNDate.parse(competition.date ?? event.date),
      let us   = competition.competitors.first(where: { $0.team.id == teamID }),
      let them = competition.competitors.first(where: { $0.team.id != teamID })
else { return nil }
```

`compactMap` over that guard means a malformed event is **dropped**, not
rendered half-empty. Eleven good games beat twelve with one blank row.

The other translation worth knowing:

```swift
private static let unrankedSentinel = 99
rank: (rank.map { $0 > 0 && $0 < Self.unrankedSentinel } ?? false) ? rank : nil
```

ESPN reports unranked teams as `curatedRank.current == 99` rather than omitting
the field. Passed through naively, every widget row would read "#99". Here 99
and 0 both become `nil`, and `matchupLine` then omits the rank entirely.

### `ESPNScheduleService.swift`

The fetch. One method, `schedule(teamID:)`, hitting ESPN's unofficial,
undocumented endpoint (it can change without notice):

```
https://site.api.espn.com/apis/site/v2/sports/football/college-football/teams/<id>/schedule
```

No key, no quota, no auth. 15-second timeout, `reloadRevalidatingCacheData`
so an unchanged payload can come back as a cheap 304, non-2xx mapped to
`ScheduleError.badResponse`, decode failures to `.decodingFailed`.

Each error is wrapped rather than rethrown so callers can tell a dead network
from an ESPN schema change.

### `ScheduleError.swift`

Four cases with `LocalizedError` descriptions written for a human — the widget
shows `errorDescription` verbatim when it has nothing cached to fall back on.

### `ScheduleCache.swift`

An `actor` holding the last good `Schedule` per team, in memory and as
`schedule-<teamID>.json` in the caches directory. Keyed by team because two
widgets can follow two teams. `load(teamID:)` prefers memory, falls back to
disk. `save()` writes
atomically and logs — but does not propagate — a write failure, since a failed
cache write only costs freshness on the next cold launch.

An actor rather than a lock because two callers can race: the app's refresh
button and the widget's timeline request.

**Design note.** The app and the extension have separate sandbox containers, so
each keeps its own copy. That costs one extra request per target and avoids an
App Group — which on macOS needs a real team identifier and provisioning, for a
schedule that refetches in under a second anyway.

### `LogoLoader.swift`

This file exists entirely because of the constraint at the top of this document:
**a widget cannot load an image while it renders.** No `AsyncImage`, no
`URLSession` inside a `body`. Logos have to be bytes in the timeline entry
before the system ever draws.

That creates a size problem. ESPN's logos are 500×500 PNGs, and a dozen of them
in one entry is far more than a timeline entry should carry. So each one is
re-encoded through ImageIO:

```swift
kCGImageSourceCreateThumbnailFromImageAlways: true,
kCGImageSourceThumbnailMaxPixelSize: 128
```

`CGImageSourceCreateThumbnailAtIndex` decodes only what it needs for the
thumbnail rather than materializing the full bitmap first. Measured against the
live feed: **ten logos, 73 KB total**, about 7 KB each — comfortable to carry,
and 128px is still retina-sharp at the 20–34pt sizes actually drawn.

Results are cached in memory and on disk, keyed by team id, so a refresh three
hours later downloads nothing. A logo that fails to load returns `nil` and
degrades to the football glyph in `TeamLogoView` — never an error state.

---

## `Shared/Theme/`

### `AppTheme.swift`

What holds for every team: the neutral grey, corner radius, the two logo sizes,
and `resultColor(_:)` mapping win/loss/tie to green/red/orange. One place to
change the look, and the reason the app window and the widget are visually
identical.

### `TeamTheme.swift`

What follows the team being shown: a single `tint`, decoded from the primary
colour ESPN ships on the schedule payload (`"ba0c2f"`, no `#`). Because it
arrives with the data it survives in the cache and works offline — no second
request. The 72 of 762 teams ESPN gives no colour fall back to
`AppTheme.neutral`. The theme reaches views through `@Environment(\.teamTheme)`,
so `GameStatusPill` and friends tint themselves without every initializer
taking a theme.

`backgroundTint` is a translucent wash of the team colour, not a background in
its own right. It is layered *over* `.fill.tertiary` so the system surface underneath
carries light and dark appearance. An earlier version was a fixed
scarlet-to-black gradient, which looked right in Dark Mode and rendered dark
text on a mid-grey field in Light Mode — macOS desktop widgets follow the system
appearance, so half the users would have seen the broken one.

---

## `Shared/Intents/`

### `TeamDirectory.swift`

An `actor` holding every team ESPN lists (`id`, `name`, `abbreviation`), from
`.../college-football/teams?limit=1000`. Fetched once, then cached in memory and
on disk, because the widget's configuration picker asks for options on every
keystroke. A failed fetch returns an empty list rather than throwing — an empty
picker beats a broken one, and the default team still draws. Both the widget's
picker and the app's `TeamPickerView` read it, so they search the same list.

Spacing values come from a 4/8/12/16 grid throughout; there are no arbitrary
in-between values to drift out of rhythm.

---

## `Shared/Views/`

Drawn by both targets. Each is small on purpose: SwiftUI re-evaluates bodies
constantly, and small structs mean small invalidations.

### `LogoImages.swift`

Turns the entry's `[String: Data]` into `[String: Image]`. It runs once, where
`ScheduleWidgetEntryView` unpacks the entry, rather than inside `TeamLogoView` —
decoding there meant re-decoding every PNG on every body evaluation.

### `TeamLogoView.swift`

`Image?` → sized logo, with the football-glyph fallback. Marked
`accessibilityHidden(true)` because the surrounding row already reads the team
name — VoiceOver announcing "Michigan logo, vs #4 Michigan" is noise.

### `GameStatusPill.swift`

The small-caps header: **LIVE** (red, with a broadcast glyph), **NEXT UP**
(team tint, calendar glyph), **FINAL**, **POSTPONED**, **CANCELED**.

The glyph is not decoration. Color alone distinguishing live from upcoming
would fail for a colorblind user; the icon carries the same distinction
independently.

### `GameTimingView.swift`

A three-way switch that picks one of the next three views:

```swift
if isLive              { LiveGameLineView(game:) }
else if game.status.isComplete { FinalScoreLineView(game:) }
else                   { KickoffLineView(game:) }
```

### `LiveGameLineView.swift`

`"MICH 17 — 24 Ohio State"` plus ESPN's clock string. Monospaced digits so the
score does not jitter as it changes.

### `FinalScoreLineView.swift`

`"W 56-3"` tinted by result, with a checkmark or cross — again so the outcome
survives without color.

### `KickoffLineView.swift`

Two lines. The first is the day, then a separator, then either the time or
`TBD` when ESPN has not announced a kickoff. The second is the network chip.

This view once also showed a live countdown, via `Text(game.date, style:
.relative)` — a WidgetKit-aware style the system keeps ticking without a new
timeline entry. That was removed. It is the reason every view from
`ScheduleWidgetEntryView` down used to take a `now: Date`: a countdown has to be
measured against the moment the entry was rendered, not against `Date.now` at
draw time. With the countdown gone, nothing in the view tree needed the clock,
and the parameter was unthreaded from all eight files.

`now` still matters upstream — `ScheduleSnapshot` and `WidgetRefreshPolicy` are
both built against the entry's date. It just no longer reaches the views. If the
countdown ever returns, the parameter comes back with it.

### `FeaturedGameView.swift`

The hero block: status pill, opponent logo, matchup line, timing. Neutral-site
games get a `"Neutral site · Dallas"` subline.

`showsStatus` defaults to true and is switched off when the caller has already
said what state the game is in — otherwise the offseason layout reads "Season
complete" directly above a "FINAL" pill saying the same thing.

The accessibility label is assembled by hand and replaces the children:

```swift
.accessibilityElement(children: .ignore)
.accessibilityLabel(accessibilityDescription)
```

Default traversal would read the logo, then "vs #4 Michigan", then "Sat Nov 28",
then "·", then "12:00 PM", then "5 days, 2 hr", then "FOX" — seven stops for one
fact. This reads it as one sentence.

### `FeaturedSectionView.swift`

Wraps `FeaturedGameView` with the season-complete heading and handles the empty
case. All three widget sizes call this rather than repeating the branch.

### `GameRowView.swift`

One list row: small logo, matchup, date, and a trailing value that is the result
if played, the kickoff time if confirmed, `TBD` otherwise. Tinted by result.
`accessibilityElement(children: .combine)` so it reads as one row.

### `ScheduleHeaderView.swift`

Team logo, name, and `"2-1 · 3rd in Big Ten"` — both halves optional, joined
only if present, so a preseason schedule with no record does not render a
stranded separator.

### `SectionLabel.swift` / `NoGamesView.swift`

The small-caps section heading, and the state where ESPN has published no games
at all.

### `SmallScheduleView.swift`

Featured game, a spacer, and the record pinned to the bottom. One game, nothing
else — at 170×170 anything more is unreadable.

### `MediumScheduleView.swift`

Featured game on the left, a divider, the next three on the right. When there
is nothing upcoming the right column falls back to recent results, so it is
never empty.

That column has no heading: the rows carry themselves at this size, and in the
offseason the left column's "Season complete" supplies the context.

Neither column carries a filling `.frame`, and that is deliberate — they were
removed after measuring what they actually did. `Divider()` is inflexible, so
the `HStack` hands it its fixed width and splits the remainder evenly between
two equally-flexible columns: the 50/50 split is automatic, and the divider
holds position no matter how long the opponent name runs. `Divider()` inside an
`HStack` is also vertically greedy, so it stretches the row to full height by
itself. The frames changed exactly one thing — pinning content to the top
instead of centring it — and centring is what this layout wants.

The same measurement retired the outer frames on `SmallScheduleView` and
`LargeScheduleView`, whose trailing `Spacer(minLength: 0)` already pins their
content top-leading. `ScheduleUnavailableView` keeps its frame: it has no
`Spacer`, so nothing else holds it in place.

### `LargeScheduleView.swift`

Header, featured game, up to three upcoming, up to two recent.

Those numbers are measured, not guessed. The first version used four upcoming
and two recent with a divider and an enlarged hero logo, and it overflowed
364×382 — clipped at both ends. Rendering the view at true widget dimensions
showed the overflow; dropping the divider, restoring the standard logo size, and
trimming to three rows brought it inside with room to spare.

### `ScheduleUnavailableView.swift`

Offline fallback. Deliberately **not** `ContentUnavailableView`, which is built
for full app windows and renders as an empty box inside a widget — verified by
rendering it. This is a plain `Label` and message.

---

### A note on where these live

The four layouts above sit in `Shared/` rather than `Widget/` for one reason:
**Xcode hosts a SwiftUI preview in the process that owns the file**, and macOS
cannot launch an app extension as a preview host. A preview on a file in the
widget target fails with "No plugin is registered to launch the process type
widgetExtension", no matter what the preview body contains.

Keeping the layouts in `Shared/` lets the app target own a preview file for
them, so the canvas works. `Widget/` is left holding only the WidgetKit
integration, which is not previewable on macOS either way.

---

## `Widget/`

### `ScheduleEntry.swift`

One frozen render: `date`, the `teamID` it was built for, an optional
`ScheduleSnapshot`, the logo bytes, and an optional error message. `placeholder` builds one from `Schedule.sample` so
the gallery preview needs no network.

### `ScheduleTimelineProvider.swift`

Where the pipeline runs. An `AppIntentTimelineProvider`: each call receives the
widget's `SelectTeamIntent` and fetches `configuration.teamID`.

```swift
do {
    let fetched = try await service.schedule(teamID: teamID)
    await ScheduleCache.shared.save(fetched)
    schedule = fetched
} catch {
    schedule = await ScheduleCache.shared.load(teamID: teamID)
    if schedule == nil { message = ... }
}
```

Fetch, cache on success, fall back to cache on failure, and only surface an
error when the cache is cold too. A network blip never blanks the widget.

Two details worth pointing out:

**Sendable boundaries.** The protocol's completion is declared
`@escaping @Sendable`, so the implementations match that signature — and
`context` is read *before* the `Task`:

```swift
// `context` is not Sendable, so read what is needed before the hop.
let family = context.family
Task { completion(await makeEntry(family: family)) }
```

Capturing `context` directly is a Swift 6 concurrency error, not a style
preference.

**Family-aware fetching.** `listLimits(for:)` returns how many rows each size
can draw — `(0, 1)` small, `(3, 2)` large, `(3, 3)` medium — and that feeds the
snapshot's limits, which feeds `referencedTeamIDs`, which feeds the logo fetch.
A small widget downloads two logos instead of ten.

### `Views/ScheduleWidgetEntryView.swift`

Switches on `@Environment(\.widgetFamily)` to pick a layout, falling through to
`ScheduleUnavailableView` when there is no snapshot, and applies
`.containerBackground(_:for: .widget)` once for all of them — required on
macOS 14+ for the widget to fill its container correctly.

The whole layout is wrapped in `Button(intent: OpenTeamPageIntent(url:))`, so a
click opens `espn.com/college-football/team/_/id/<teamID>` in the browser. ESPN
accepts the id-only form, so no slug has to be synthesized.

### `CollegeFootballScheduleWidget.swift` / `CollegeFootballScheduleWidgetBundle.swift`

The `AppIntentConfiguration` binding kind, `SelectTeamIntent`, provider, and
view together, its display name and description for the widget gallery, and the
three supported families. The bundle is the `@main` entry point.

A placed widget does not migrate across a change of configuration type, and
`chronod` caches the descriptor by bundle version — see the README's
troubleshooting sections before changing either.

### `SelectTeamIntent.swift` / `TeamEntity.swift`

The per-widget configuration. The parameter is a plain `String` like
`"Ohio State Buckeyes · OSU [194]"`, not an `AppEntity`; `teamID` pulls the id
back out of the brackets and falls back to `Team.defaultID`. A primitive
round-trips reliably through the configuration sheet where the entity version
did not. `parameterSummary` is required: without it the picker updates its row
but the choice never reaches the intent.

`TeamEntity.swift` (named for what it replaced) holds `TeamIDOptionsProvider`,
which formats `TeamDirectory` entries into those strings.

### `OpenTeamPageIntent.swift`

Hands a URL to the system with `OpenURLIntent`. `openAppWhenRun = false` keeps
the host app out of it — a widget click goes straight to the browser.

There are deliberately no previews here — see the note at the end of
`Shared/Views` and `App/Previews/` below.

Note that `Widget` and `WidgetBundle` are declared in **SwiftUI**, not WidgetKit
— both imports are required, and omitting SwiftUI produces a confusing
"cannot find type 'Widget'" error.

---

## `App/`

The host window. It exists partly to show the full season and partly because
**macOS will not register a widget until its containing app has launched once**.

### `CollegeFootballScheduleApp.swift`

`@main`. Owns the `ScheduleStore` as `@State`, injects it through
`.environment`, sets a default window size, and adds a ⌘R refresh command.

### `LoadState.swift`

`idle` / `loading` / `loaded(Schedule)` / `failed(String)`. An enum rather than
parallel `isLoading` + `schedule` + `error` properties, so "loading and failed
at once" cannot be represented.

### `ScheduleStore.swift`

`@MainActor @Observable` — the modern Observation pattern, not
`ObservableObject`. Fetches, caches, and on success calls:

```swift
WidgetCenter.shared.reloadAllTimelines()
```

so hitting refresh in the app updates the desktop widget immediately instead of
waiting out the timeline.

The failure path is a deliberate choice, flagged in a comment: a cached schedule
wins over reporting the error, and only a cold cache reaches `.failed`. Stale
games beat an error screen.

### `ContentView.swift`

Switches on `store.state`, and drives loading from `.task(id: teamID)` — which
cancels automatically if the window closes mid-flight, unlike `onAppear`, and
re-runs when the team changes. The window's team is `@AppStorage("teamID")`,
independent of any widget's choice, and is picked in `TeamPickerView`. The
refresh button's action is a named method rather than an inline closure, keeping
the logic out of `body`.

### `SeasonScheduleView.swift`

The featured card over the full season list. Both the snapshot and the sorted
games are computed **in `init`**, not in `body` — a `body` runs on every
invalidation and sorting there would repeat the work for nothing.

It passes `upcomingLimit: .max, recentLimit: .max`, since a scrolling window,
unlike a widget, can show the whole season.

### `NextGameCardView.swift`

The prominent card: large logo, status pill, matchup, timing, venue, over the
shared gradient.

### `ScheduleRowView.swift`

One season row — like `GameRowView` but wider, with the network under the
trailing value.

### `AsyncTeamLogoView.swift`

The app's logo view, and the one place the two targets legitimately differ: an
app **can** load images while rendering, so this is a plain `AsyncImage` against
the ESPN URL. No pre-fetching, no downsampling, no entry-size budget.

### `SeasonSummaryView.swift` / `ScheduleErrorView.swift`

Record and standing as a section footer; and the full-window error state —
which *does* use `ContentUnavailableView`, because in a window it works and
comes with a retry button.

### `Previews/`

Preview-only scaffolding, all `#if DEBUG` so none of it reaches a Release
build. It lives in the app target **specifically** so that Xcode hosts these
previews in `CollegeFootballSchedule.app` rather than the extension.

- **`WidgetLayoutPreviews.swift`** — `#Preview` blocks for all three widget
  sizes plus the offline state, each at true widget dimensions.
- **`WidgetPreviewFrame.swift`** — applies the padding, gradient, fixed size and
  corner radius WidgetKit would, so the canvas shows the real thing rather than
  a loose view.
- **`PreviewLogos.swift`** — draws grey lettered badges to stand in for team
  logos. The real ones are fetched over the network into a timeline entry, which
  a preview cannot do synchronously; without these every preview would be
  fallback football glyphs.

---

## `Tests/`

Hosted by the app target, which is what makes `@testable import CollegeFootballSchedule`
reach the `Shared/` types.

### `Fixture.swift` / `FixtureBundleToken.swift`

Loads `Tests/Fixtures/osu-schedule.json` and runs it through the real decoder
and the real mapper. `FixtureBundleToken` is an empty class whose only job is to
anchor `Bundle(for:)` — structs cannot.

### `Fixtures/osu-schedule.json`

A **real** ESPN response, trimmed to three games chosen to cover the awkward
cases: one completed with scores, one scheduled with a confirmed kickoff, one
scheduled still TBD. Trimmed from the live payload rather than hand-written, so
it carries ESPN's actual quirks — including the `curatedRank: 99` sentinel.

### `ESPNScheduleDecodingTests.swift`

Team summary, orientation of a completed game (Ohio State's score in
`teamScore`, not the opponent's), the minute-precision date format, the TBD
flag, and the 99-means-unranked translation.

### `ScheduleSnapshotTests.swift`

The selection logic: which game gets featured, that lists exclude it, that a
game stays featured 45 minutes after kickoff, that it drops once the four-hour
window passes, that the season-complete fallback fires, and that it does *not*
fire mid-season.

### `WidgetRefreshPolicyTests.swift`

Each branch of the cadence table, including that a pre-kickoff refresh lands at
or before kickoff rather than after it.

### `TeamThemeTests.swift`

ESPN hex parsing, the fallback for missing or malformed colours, and decoding
the colour from a real payload shape.

---

## `project.yml`

The project file is **generated** — `project.yml` is the source of truth and
`CollegeFootballSchedule.xcodeproj` is gitignored. Run `xcodegen generate` after adding files.

It defines the three targets, embeds the extension into the app's `PlugIns`,
declares the sandbox and `network.client` entitlements for both, and sets the
widget's `NSExtensionPointIdentifier` to `com.apple.widgetkit-extension`.

Signing is ad-hoc (`CODE_SIGN_IDENTITY: "-"`) so it builds with no provisioning
profile. Swap in your team to run it on another Mac.
