import SwiftUI

/// Turns the timeline entry's raw logo bytes into drawable images.
///
/// Done once where the entry is unpacked rather than inside `TeamLogoView`,
/// which would re-decode every PNG on every body evaluation.
enum LogoImages {
    static func decode(_ logos: [String: Data]) -> [String: Image] {
        logos.compactMapValues { data in
            NSImage(data: data).map(Image.init(nsImage:))
        }
    }
}
