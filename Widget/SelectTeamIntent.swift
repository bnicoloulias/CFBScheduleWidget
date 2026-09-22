import AppIntents

/// The widget's configuration: which team it follows.
struct SelectTeamIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Select Team"
    static let description = IntentDescription("Choose which team's schedule the widget shows.")

    /// Store a primitive string rather than an AppEntity. The options include
    /// the display name and ESPN id; `teamID` extracts the latter for fetching.
    @Parameter(title: "Team", default: "Ohio State Buckeyes · OSU [194]", optionsProvider: TeamIDOptionsProvider())
    var team: String

    /// A `WidgetConfigurationIntent` needs this for the configuration sheet to
    /// bind the parameter. Without it the picker renders and its row updates,
    /// but the choice is not carried back into the intent.
    static var parameterSummary: some ParameterSummary {
        Summary("Show the schedule for \(\.$team)")
    }

    var teamID: String {
        guard let openingBracket = team.lastIndex(of: "["),
            let closingBracket = team.lastIndex(of: "]"),
            openingBracket < closingBracket
        else {
            return Team.defaultID
        }
        return String(team[team.index(after: openingBracket)..<closingBracket])
    }

    init() {}

    init(team: String = "Ohio State Buckeyes · OSU [194]") {
        self.team = team
    }
}
