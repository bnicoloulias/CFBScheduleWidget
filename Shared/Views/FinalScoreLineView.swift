import SwiftUI

/// Result line for a completed game, e.g. "W 56-3".
struct FinalScoreLineView: View {
    let game: Game

    var body: some View {
        if let resultLine = game.resultLine, let result = game.result {
            Label(resultLine, systemImage: result == .win ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(AppTheme.resultColor(result))
        } else {
            Text("Final")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }
}
