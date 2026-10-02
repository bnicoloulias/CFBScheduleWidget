import SwiftUI

/// The "·" between items on one line; VoiceOver skips it.
struct MiddleDotSeparator: View {
    var body: some View {
        Text(verbatim: "·")
            .foregroundStyle(.tertiary)
            .accessibilityHidden(true)
    }
}
