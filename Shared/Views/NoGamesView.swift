import SwiftUI

/// Shown when ESPN has published no games at all for the season.
struct NoGamesView: View {
    let seasonLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionLabel(text: "No games yet")
            Text("The \(seasonLabel) schedule hasn't been posted.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}
