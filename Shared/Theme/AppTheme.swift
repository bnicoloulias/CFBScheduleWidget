import SwiftUI

/// Design constants that hold for any team, so the app and the widget stay
/// visually identical. Anything that changes with the team lives in
/// `TeamTheme` instead.
enum AppTheme {
    /// A neutral that does not belong to any school. Used for logo
    /// placeholders and as the fallback tint.
    static let neutral = Color(red: 0.4, green: 0.4, blue: 0.4)

    static let cornerRadius: Double = 10
    static let logoSize: Double = 34
    static let smallLogoSize: Double = 20
    /// Inset around the placeholder glyph, as a fraction of the logo size.
    static let logoGlyphInset: Double = 0.1

    #if os(iOS)
    /// iOS text styles run much larger than macOS's, so on iPhone the widgets
    /// shorten or drop secondary detail to fit.
    static let prefersCompactWidgets = true
    #else
    static let prefersCompactWidgets = false
    #endif

    static func resultColor(_ result: GameResult) -> Color {
        switch result {
        case .win: .green
        case .loss: .red
        case .tie: .orange
        }
    }
}
