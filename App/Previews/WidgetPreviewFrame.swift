#if DEBUG
import SwiftUI

/// Wraps a widget layout in the chrome WidgetKit would give it, so a plain
/// SwiftUI preview shows the real thing at the real size.
///
/// Widget previews (`#Preview(as: .systemSmall)`) do not render on macOS
/// destinations — Xcode reports "This platform does not support previewing
/// widgets" — so the size views are previewed directly instead.
struct WidgetPreviewFrame<Content: View>: View {
    let width: Double
    let height: Double
    var theme: TeamTheme = .fallback
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(14)
            .frame(width: width, height: height)
            .background {
                ZStack {
                    Rectangle().fill(.fill.tertiary)
                    theme.backgroundTint
                }
            }
            .background(.background)
            .clipShape(.rect(cornerRadius: 22))
            .padding()
            .environment(\.teamTheme, theme)
    }
}
#endif
