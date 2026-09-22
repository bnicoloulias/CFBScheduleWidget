import SwiftUI

/// The part of the look that follows whichever team is being shown.
///
/// ESPN ships a primary colour on the schedule payload itself, so it arrives
/// with the data and survives in the cache — no second request, and it still
/// works offline.
struct TeamTheme: Equatable, Sendable {
    let tint: Color

    /// For the 72 of 762 teams ESPN publishes no colour for.
    static let fallback = TeamTheme(tint: AppTheme.neutral)

    init(tint: Color) {
        self.tint = tint
    }

    /// `hex` is ESPN's form: six digits, no leading `#`.
    init?(hex: String?) {
        guard let tint = Color(espnHex: hex) else { return nil }
        self.tint = tint
    }

    /// A wash laid *over* the system surface rather than a fixed gradient.
    /// Forcing a solid colour meant the light-appearance widget rendered dark
    /// text on a mid-tone background; keeping it translucent lets the surface
    /// underneath carry light and dark.
    var backgroundTint: LinearGradient {
        LinearGradient(
            colors: [tint.opacity(0.22), tint.opacity(0.04)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension Color {
    /// Decodes ESPN's `"ba0c2f"`. Returns nil for anything else so the caller
    /// can fall back rather than render black.
    init?(espnHex hex: String?) {
        guard var hex else { return nil }
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 6, let value = UInt32(hex, radix: 16) else { return nil }

        self.init(
            red: Double((value & 0xFF0000) >> 16) / 255,
            green: Double((value & 0x00FF00) >> 8) / 255,
            blue: Double(value & 0x0000FF) / 255
        )
    }
}

// MARK: - Environment

private struct TeamThemeKey: EnvironmentKey {
    static let defaultValue = TeamTheme.fallback
}

extension EnvironmentValues {
    /// Set once per entry point; every view below reads it rather than
    /// threading a colour through initialisers.
    var teamTheme: TeamTheme {
        get { self[TeamThemeKey.self] }
        set { self[TeamThemeKey.self] = newValue }
    }
}
