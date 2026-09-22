import Foundation

/// The team a widget follows before it has been configured.
///
/// ESPN identifies college football teams by a numeric id; Ohio State is 194.
/// Nothing in the app reads these as *the* team any more — the id travels with
/// the data instead. They are the starting point for an unconfigured widget,
/// and the fixed team previews and tests draw.
enum Team {
    static let defaultID = "194"
    static let defaultName = "Ohio State Buckeyes"

    /// ESPN serves square PNG logos for every team from a predictable path.
    static func logoURL(teamID: String) -> URL? {
        URL(string: "https://a.espncdn.com/i/teamlogos/ncaa/500/\(teamID).png")
    }
}
