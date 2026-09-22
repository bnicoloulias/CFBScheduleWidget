import SwiftUI

/// Small caps heading used above widget lists.
struct SectionLabel: View {
    let text: LocalizedStringKey

    var body: some View {
        Text(text)
            .font(.caption.smallCaps())
            .foregroundStyle(.secondary)
    }
}
