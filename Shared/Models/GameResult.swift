import Foundation

/// The outcome of a completed game, from the followed team's point of view.
enum GameResult: String, Codable, Sendable {
    case win
    case loss
    case tie

    var letter: String {
        switch self {
        case .win: "W"
        case .loss: "L"
        case .tie: "T"
        }
    }
}
