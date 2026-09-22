import Foundation

/// Failures worth telling the user about.
enum ScheduleError: LocalizedError {
    case badURL
    case badResponse(status: Int)
    case decodingFailed(any Error)
    case transport(any Error)

    var errorDescription: String? {
        switch self {
        case .badURL:
            "Could not build the schedule request."
        case .badResponse(let status):
            "ESPN returned an unexpected response (\(status))."
        case .decodingFailed:
            "The schedule could not be read. ESPN may have changed its format."
        case .transport(let error):
            error.localizedDescription
        }
    }
}
