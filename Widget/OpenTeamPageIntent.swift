//
//  OpenTeamPageIntent.swift
//  CollegeFootballSchedule
//
//  Created by Bobby Nicoloulias on 9/21/26.
//
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
