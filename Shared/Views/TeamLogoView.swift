import SwiftUI

/// Draws a team logo, falling back to a glyph when one could not be loaded.
struct TeamLogoView: View {
    let image: Image?
    let teamName: String
    let size: Double

    var body: some View {
        Group {
            if let image {
                image
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "football.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
                    .padding(size * 0.1)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
