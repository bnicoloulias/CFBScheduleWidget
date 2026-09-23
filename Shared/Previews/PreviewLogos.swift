#if DEBUG
import SwiftUI

/// Stand-in team logos for previews.
///
/// The real logos are fetched over the network and resolved into a timeline
/// entry, which a preview has no way to do synchronously. These are drawn on
/// the spot so previews render instantly and offline.
@MainActor
enum PreviewLogos {
    /// A badge for every team the snapshot will ask about.
    static func make(for snapshot: ScheduleSnapshot) -> [String: Data] {
        let games = [snapshot.featured].compactMap(\.self) + snapshot.upcoming + snapshot.recent

        var abbreviations = [snapshot.teamID: snapshot.teamAbbreviation]
        for game in games {
            abbreviations[game.opponent.id] = game.opponent.abbreviation
        }

        return abbreviations.compactMapValues(badge)
    }

    private static func badge(_ text: String) -> Data? {
        let badge = ZStack {
            Circle()
                .fill(AppTheme.neutral.gradient)
            Text(text.prefix(4))
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .padding(8)
        }
        .frame(width: 128, height: 128)

        let renderer = ImageRenderer(content: badge)
        #if canImport(UIKit)
        return renderer.uiImage?.pngData()
        #else
        guard let image = renderer.nsImage,
            let tiff = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff)
        else { return nil }

        return bitmap.representation(using: .png, properties: [:])
        #endif
    }
}
#endif
