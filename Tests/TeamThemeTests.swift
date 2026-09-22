import Foundation
import SwiftUI
import Testing

@testable import CollegeFootballSchedule

struct TeamThemeTests {
    @Test func decodesESPNHex() throws {
        // Ohio State's published colour.
        let theme = try #require(TeamTheme(hex: "ba0c2f"))

        let resolved = NSColor(theme.tint).usingColorSpace(.sRGB)
        let components = try #require(resolved)
        #expect(abs(components.redComponent - 0xba / 255.0) < 0.001)
        #expect(abs(components.greenComponent - 0x0c / 255.0) < 0.001)
        #expect(abs(components.blueComponent - 0x2f / 255.0) < 0.001)
    }

    @Test func toleratesALeadingHash() {
        #expect(TeamTheme(hex: "#ba0c2f") != nil)
    }

    /// ESPN publishes no colour for 72 of its 762 teams, and a cache written
    /// before the field existed decodes without it.
    @Test(arguments: [nil, "", "nope", "ba0c2", "ba0c2fff"])
    func fallsBackRatherThanRenderingBlack(hex: String?) {
        #expect(TeamTheme(hex: hex) == nil)
    }

    @Test func snapshotFallsBackWhenTheFeedOmitsAColour() throws {
        // The fixture predates the colour field, so it exercises the path.
        let schedule = try Fixture.schedule()
        let snapshot = ScheduleSnapshot(schedule: schedule)

        #expect(schedule.teamColor == nil)
        #expect(snapshot.theme == .fallback)
    }

    /// The shape ESPN actually sends on the schedule endpoint: the colour sits
    /// on the top-level `team` object, and `alternateColor` is never present.
    @Test func decodesTheColourFromARealPayloadShape() throws {
        let json = Data(
            """
            {
              "season": { "displayName": "2026", "year": 2026 },
              "team": {
                "id": "130",
                "abbreviation": "MICH",
                "displayName": "Michigan Wolverines",
                "recordSummary": "3-0",
                "standingSummary": "1st in Big Ten",
                "color": "00274c"
              },
              "events": []
            }
            """.utf8)

        let decoded = try JSONDecoder().decode(ESPNScheduleResponse.self, from: json)
        let schedule = decoded.makeSchedule(teamID: "130")

        #expect(schedule.teamColor == "00274c")
        #expect(ScheduleSnapshot(schedule: schedule).theme != .fallback)
    }

    @Test func snapshotCarriesTheFeedColour() {
        let snapshot = ScheduleSnapshot(schedule: .sample)

        #expect(snapshot.teamColor == "ba0c2f")
        #expect(snapshot.theme != .fallback)
    }
}
