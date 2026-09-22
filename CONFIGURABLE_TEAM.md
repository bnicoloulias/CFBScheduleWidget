# Making the team user-editable

Goal: let the team be changed without recompiling, so the widget can follow
someone other than Ohio State.

## Pick what "editable" means first

| | Who edits it | Cost |
|---|---|---|
| **1. Per-widget config** (recommended) | Right-click widget → Edit Widget → pick a team | Converts the widget to `AppIntentConfiguration`; no entitlement or signing change |
| **2. One app-wide setting** | A picker in the app window, widget follows it | Needs an **App Group**, which needs a real `DEVELOPMENT_TEAM` — see the caveat in Part 3 |
| **3. Developer-only** | Edit `Team.id`, rebuild | Already how it works; zero code |

Option 1 also gives you *two widgets side by side following two teams*, which
option 2 cannot do. The rest of this doc assumes option 1, with option 2
sketched at the end.

**Part 1 is required for either option.** Part 2 is the configuration UI.

---

## Part 1 — De-hardcode the team

`Team.id` is a compile-time constant referenced in 10 places. Each one has to
start reading the team from data that flows in at runtime instead.

### 1.1 `Shared/Models/Team.swift`

`shortName` is the problem child: it is a *display* value hardcoded next to the
id, but the schedule feed already returns the real name. Keep only what stays
true for any team:

```swift
enum Team {
    /// Used until a widget has been configured, and by previews and tests.
    static let defaultID = "194"
    static let defaultName = "Ohio State Buckeyes"

    static func logoURL(teamID: String) -> URL? {
        URL(string: "https://a.espncdn.com/i/teamlogos/ncaa/500/\(teamID).png")
    }
}
```

Delete `Team.id` and `Team.shortName`. The compiler will now walk you through
every remaining site in this list.

### 1.2 `ScheduleSnapshot` has to carry the id

`Shared/Models/ScheduleSnapshot.swift` exposes `teamName` and
`teamAbbreviation` but **not** `teamID`, which is why views reach for the
global. Add it:

```swift
struct ScheduleSnapshot: Sendable, Hashable {
    let teamID: String          // new
    let teamName: String
    ...

    init(schedule: Schedule, ...) {
        teamID = schedule.teamID     // new
        teamName = schedule.teamName
        ...
    }
}
```

Then `referencedTeamIDs` (line ~54) becomes:

```swift
var ids = [teamID]
```

### 1.3 The remaining sites

| File | Current | Change to |
|---|---|---|
| `Shared/Views/LargeScheduleView.swift:13` | `logos[Team.id]` | `logos[snapshot.teamID]` |
| `Shared/Views/FeaturedGameView.swift:12` | `"\(Team.shortName) \(game.matchupLine)"` | add a `let teamName: String` property, pass `snapshot.teamAbbreviation` from `FeaturedSectionView.swift:17` |
| `Shared/Views/LiveGameLineView.swift:9` | `"... \(teamScore) \(Team.shortName)"` | add `let teamName: String`; thread it through `GameTimingView` (both call sites: `FeaturedGameView.swift:46` and `App/Views/NextGameCardView.swift:19`) |
| `Shared/Networking/ESPNScheduleService.swift:14` | `teamID: String = Team.id` | drop the default — make every caller state the team |
| `Shared/Networking/ScheduleCache.swift:19` | `schedule-\(Team.id).json` | see 1.4 |
| `Shared/Models/Schedule+Sample.swift:39` | `teamID: Team.id` | `Team.defaultID` |
| `App/Previews/PreviewLogos.swift:15` | `[Team.id: ...]` | `[Team.defaultID: ...]` |
| `Tests/ScheduleSnapshotTests.swift:51`, `Tests/Fixture.swift:21` | `Team.id` | `Team.defaultID` |

`Shared/Networking/LogoLoader.swift:45` and `Shared/Models/Opponent.swift:15`
already go through `Team.logoURL(teamID:)` and need no change.

### 1.4 The cache becomes per-team

`ScheduleCache` currently hardcodes one filename, so two teams would overwrite
each other. Key everything by team:

```swift
actor ScheduleCache {
    static let shared = ScheduleCache()

    private var inMemory: [String: Schedule] = [:]

    private func fileURL(teamID: String) -> URL? {
        try? FileManager.default
            .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(path: "schedule-\(teamID).json")
    }

    func load(teamID: String) -> Schedule? {
        if let cached = inMemory[teamID] { return cached }
        guard let url = fileURL(teamID: teamID),
              let data = try? Data(contentsOf: url),
              let schedule = try? JSONDecoder().decode(Schedule.self, from: data)
        else { return nil }
        inMemory[teamID] = schedule
        return schedule
    }

    func save(_ schedule: Schedule) {
        inMemory[schedule.teamID] = schedule      // the id rides along on the model
        guard let url = fileURL(teamID: schedule.teamID) else { return }
        do {
            try JSONEncoder().encode(schedule).write(to: url, options: .atomic)
        } catch {
            logger.warning("Could not cache schedule: \(error.localizedDescription, privacy: .public)")
        }
    }
}
```

`save` needs no new argument — `Schedule.teamID` is already on the model.

### 1.5 The entry carries the id

`Widget/ScheduleEntry.swift` — the deep link needs to know which team was
drawn:

```swift
struct ScheduleEntry: TimelineEntry {
    let date: Date
    let teamID: String        // new
    let snapshot: ScheduleSnapshot?
    let logos: [String: Data]
    let message: String?
}
```

and `ScheduleWidgetEntryView` builds the URL from it instead of the constant:

```swift
private var teamURL: URL {
    URL(string: "https://www.espn.com/college-football/team/_/id/\(entry.teamID)")!
}
```

then `Button(intent: OpenTeamPageIntent(url: teamURL))`.

*Verified:* ESPN accepts the id-only form — `…/team/_/id/194` returns 200 with
no redirect, so you never have to synthesize the `ohio-state-buckeyes` slug.

---

## Part 2 — The configuration UI

### 2.1 Team list source

ESPN publishes every team at:

```
https://site.api.espn.com/apis/site/v2/sports/football/college-football/teams?limit=1000
```

*Verified:* returns **762** teams, each with `id`, `displayName`,
`abbreviation`, `slug`. Shape is
`sports[0].leagues[0].teams[].team`.

New file `Shared/Intents/TeamDirectory.swift`:

```swift
import Foundation

/// The list of teams the picker offers. Fetched once and cached on disk —
/// 762 entries is small, but it is not worth a request per keystroke.
actor TeamDirectory {
    static let shared = TeamDirectory()

    struct Entry: Codable, Sendable, Hashable {
        let id: String
        let name: String
        let abbreviation: String
    }

    private static let url = URL(string:
        "https://site.api.espn.com/apis/site/v2/sports/football/college-football/teams?limit=1000")!

    private var entries: [Entry]?

    func all() async -> [Entry] {
        if let entries { return entries }
        if let disk = loadFromDisk() { entries = disk; return disk }

        guard let (data, _) = try? await URLSession.shared.data(from: Self.url),
              let decoded = try? JSONDecoder().decode(Response.self, from: data)
        else { return [] }

        let fetched = decoded.sports
            .flatMap(\.leagues).flatMap(\.teams).map(\.team)
            .map { Entry(id: $0.id, name: $0.displayName, abbreviation: $0.abbreviation ?? "") }
            .sorted { $0.name < $1.name }

        entries = fetched
        saveToDisk(fetched)
        return fetched
    }

    func search(_ text: String) async -> [Entry] {
        let all = await all()
        guard !text.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(text) }
    }

    // Matches sports[0].leagues[0].teams[].team
    private struct Response: Decodable {
        struct Sport: Decodable { let leagues: [League] }
        struct League: Decodable { let teams: [Wrapper] }
        struct Wrapper: Decodable { let team: Payload }
        struct Payload: Decodable {
            let id: String
            let displayName: String
            let abbreviation: String?
        }
        let sports: [Sport]
    }

    // loadFromDisk / saveToDisk: same caches-directory pattern as ScheduleCache.
}
```

Note the 762 includes D2/D3 programs that have no usable schedule feed. If that
bothers you, hardcode an FBS allowlist or just let search handle it — the
payload carries no division field.

### 2.2 The entity and query

New file `Shared/Intents/TeamEntity.swift`:

```swift
import AppIntents

struct TeamEntity: AppEntity {
    let id: String              // ESPN team id
    let name: String
    let abbreviation: String

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Team"
    static let defaultQuery = TeamQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(abbreviation)")
    }
}

/// `EntityStringQuery` is what gives the config sheet a search field.
struct TeamQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [TeamEntity] {
        let all = await TeamDirectory.shared.all()
        return all.filter { identifiers.contains($0.id) }.map(Self.entity)
    }

    func entities(matching string: String) async throws -> [TeamEntity] {
        await TeamDirectory.shared.search(string).prefix(50).map(Self.entity)
    }

    func suggestedEntities() async throws -> [TeamEntity] {
        // Shown before the user types anything.
        try await entities(for: ["194", "333", "130", "61", "2390"])
    }

    func defaultResult() -> TeamEntity? {
        TeamEntity(id: Team.defaultID, name: Team.defaultName, abbreviation: "OSU")
    }

    private static func entity(_ e: TeamDirectory.Entry) -> TeamEntity {
        TeamEntity(id: e.id, name: e.name, abbreviation: e.abbreviation)
    }
}
```

### 2.3 The configuration intent

New file `Shared/Intents/SelectTeamIntent.swift`:

```swift
import AppIntents

struct SelectTeamIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Select Team"
    static let description = IntentDescription("Choose which team's schedule the widget shows.")

    @Parameter(title: "Team") var team: TeamEntity?

    /// Falls back so an unconfigured widget still draws something.
    var teamID: String { team?.id ?? Team.defaultID }
}
```

### 2.4 Swap the widget's configuration type

`Widget/CollegeFootballScheduleWidget.swift`:

```swift
var body: some WidgetConfiguration {
    AppIntentConfiguration(
        kind: kind,
        intent: SelectTeamIntent.self,
        provider: ScheduleTimelineProvider()
    ) { entry in
        ScheduleWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Team Schedule")
    .description("The next game for the team you pick, with scores and what's coming up.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
}
```

### 2.5 Provider becomes `AppIntentTimelineProvider`

`Widget/ScheduleTimelineProvider.swift`. The async form drops the completion
handlers and the `Sendable` dance around `context`, so this is a net
simplification:

```swift
struct ScheduleTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ScheduleEntry { .placeholder }

    func snapshot(for configuration: SelectTeamIntent, in context: Context) async -> ScheduleEntry {
        guard !context.isPreview else { return .placeholder }
        return await makeEntry(teamID: configuration.teamID, family: context.family)
    }

    func timeline(for configuration: SelectTeamIntent, in context: Context) async -> Timeline<ScheduleEntry> {
        let entry = await makeEntry(teamID: configuration.teamID, family: context.family)
        let refresh = WidgetRefreshPolicy.nextRefresh(for: entry.snapshot, now: entry.date)
        return Timeline(entries: [entry], policy: .after(refresh))
    }

    private func makeEntry(teamID: String, family: WidgetFamily, now: Date = .now) async -> ScheduleEntry {
        var schedule: Schedule?
        var message: String?

        do {
            let fetched = try await service.schedule(teamID: teamID)
            await ScheduleCache.shared.save(fetched)
            schedule = fetched
        } catch {
            logger.error("Schedule fetch failed: \(error.localizedDescription, privacy: .public)")
            schedule = await ScheduleCache.shared.load(teamID: teamID)
            if schedule == nil { message = ScheduleError.transport(error).errorDescription }
        }

        guard let schedule else {
            return ScheduleEntry(date: now, teamID: teamID, snapshot: nil, message: message)
        }
        // ...unchanged from here: limits, snapshot, logos...
    }
}
```

### 2.6 Project / build

Nothing in `project.yml`. `Shared/` is already in both targets' `sources`, so
putting the intent files there compiles them into the app *and* the extension —
which is what you want, since the app supplies the picker's entity query while
the extension runs the timeline. `AppIntents` links implicitly from the
`import`.

One consequence: the app target will now also emit AppIntents metadata, so the
`no AppIntents.framework dependency found` warning you saw on the app target
goes away on its own.

---

## Part 3 — Alternative: one app-wide setting (App Group)

If you would rather have a picker in the app window that all widgets follow:

1. Add `com.apple.security.application-groups` with
   `group.com.bobbynicoloulias.CollegeFootballSchedule` to **both**
   `App/CollegeFootballSchedule.entitlements` and `Widget/CollegeFootballScheduleWidget.entitlements`
   (these are generated from `project.yml`, so edit it there).
2. App writes the chosen id to `UserDefaults(suiteName:)`, then calls
   `WidgetCenter.shared.reloadAllTimelines()`.
3. Provider reads the same suite in `makeEntry`.

**The caveat that matters:** the project signs ad-hoc
(`CODE_SIGN_IDENTITY: "-"`, `DEVELOPMENT_TEAM: ""`) specifically so it builds
with no provisioning profile. Sandboxed App Groups on macOS are validated
against a team-id-prefixed group and generally require a real team and profile.
You would be trading "clone and build" for "set up signing first." The comment
at the top of `ScheduleCache` says this was a deliberate call — Part 2 stays
inside that decision, Part 3 reverses it.

---

## Verify

1. Build, run the app once so the extension registers.
2. Remove the existing widget and re-add it. **Required** — changing a widget
   from `StaticConfiguration` to `AppIntentConfiguration` under the same `kind`
   does not reliably migrate an already-placed instance.
3. Right-click the widget → **Edit Widget**. The team picker should appear with
   a search field and Ohio State preselected.
4. Pick another team; the widget should redraw with that team's schedule, logo,
   record, and header name.
5. Click the widget — it should open that team's ESPN page, not Ohio State's.
6. Add a second widget set to a different team and confirm the two do not
   fight over the cache (that is what 1.4 is for).

## Known rough edges

- **The app window still shows the default team.** Per-widget configuration
  does not reach `ScheduleStore`, which calls `service.schedule()` with no
  argument. Give the app its own `@AppStorage("teamID")` picker if you want the
  window to follow too — the two settings stay independent by design.
- **`suggestedEntities` ids are guesses.** `194` is Ohio State (confirmed);
  verify the rest against the teams endpoint before shipping them as defaults.
- **Not every one of the 762 teams has a usable schedule feed.** A D3 program
  may return an empty `games` array, which surfaces as the "no games" view
  rather than an error. Worth a nicer message if you expose the whole list.
- **Tests** in `Tests/` still assert against the Ohio State fixture; they only
  need `Team.id` → `Team.defaultID` renames, not new coverage, unless you want
  a case for the per-team cache keying.
