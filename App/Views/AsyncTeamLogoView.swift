import SwiftUI

/// Team logo loaded straight from ESPN. The app, unlike the widget, can load
/// images while rendering.
struct AsyncTeamLogoView: View {
    let teamID: String
    let size: Double

    var body: some View {
        AsyncImage(url: Team.logoURL(teamID: teamID)) { image in
            image
                .resizable()
                .scaledToFit()
        } placeholder: {
            Image(systemName: "football.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.tertiary)
                .padding(size * 0.1)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
