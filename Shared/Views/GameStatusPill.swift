import SwiftUI
import WidgetKit

/// The small caps label above a featured game: LIVE, NEXT UP, or FINAL.
///
/// A filled capsule, because the surface behind it is washed in the same team
/// colour and plain tinted text blended into it.
struct GameStatusPill: View {
    @Environment(\.teamTheme) private var theme
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.self) private var environment

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

    /// Black or white, whichever reads better on `tint`. Uses WCAG relative
    /// luminance; 0.18 is roughly where the two have equal contrast.
    private var labelColor: Color {
        let resolved = tint.resolve(in: environment)
        let luminance =
            0.2126 * resolved.linearRed
            + 0.7152 * resolved.linearGreen
            + 0.0722 * resolved.linearBlue
        return luminance > 0.18 ? .black : .white
    }

    var body: some View {
        let label = Text(title)
            .font(.caption.smallCaps())
            .bold()

        // Accented and vibrant modes drop colour, which would leave a solid
        // capsule with the text lost inside it. The app always reads
        // `.fullColor`.
        if renderingMode == .fullColor {
            label
                .foregroundStyle(labelColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(tint, in: .capsule)
        } else {
            label
                .foregroundStyle(.secondary)
        }
    }
}
