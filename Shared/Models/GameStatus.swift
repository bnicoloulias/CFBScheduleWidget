import Foundation

/// Where a game sits in its lifecycle, normalized from ESPN's `STATUS_*` strings.
enum GameStatus: String, Codable, Sendable {
    case scheduled
    case inProgress
    case final
    case postponed
    case canceled

    init(espnName: String) {
        self =
            switch espnName {
            case "STATUS_IN_PROGRESS", "STATUS_HALFTIME", "STATUS_END_PERIOD": .inProgress
            case "STATUS_FINAL", "STATUS_FINAL_OVERTIME": .final
            case "STATUS_POSTPONED", "STATUS_DELAYED", "STATUS_RAIN_DELAY": .postponed
            case "STATUS_CANCELED": .canceled
            default: .scheduled
            }
    }

    /// True once the game has a final score worth showing.
    var isComplete: Bool { self == .final }
}
