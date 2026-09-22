import SwiftUI

/// The small caps label above a featured game: LIVE, NEXT UP, or FINAL.
struct GameStatusPill: View {
    @Environment(\.teamTheme) private var theme

    let game: Game
    let isLive: Bool

    private var title: String {
        if isLive {
            "Live"
        } else {
            switch game.status {
            case .final: "Final"
            case .postponed: "Postponed"
            case .canceled: "Canceled"
            case .scheduled, .inProgress: "Next up"
            }
        }
    }

    private var tint: Color {
        if isLive {
            .red
        } else {
            switch game.status {
            case .postponed, .canceled: .orange
            default: theme.tint
            }
        }
    }

    var body: some View {
        Text(title)
            .font(.caption.smallCaps())
            .bold()
            .foregroundStyle(tint)
    }
}
