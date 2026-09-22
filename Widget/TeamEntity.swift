import AppIntents

/// Supplies primitive, readable values for WidgetKit configuration. The ESPN
/// id in brackets is the persisted part consumed by `SelectTeamIntent.teamID`.
struct TeamIDOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [String] {
        let teams = await TeamDirectory.shared.all()
        print("TEAM OPTIONS count=\(teams.count)")
        return teams.map { team in
            "\(team.name) · \(team.abbreviation) [\(team.id)]"
        }
    }
}
