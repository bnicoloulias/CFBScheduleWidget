import SwiftUI

/// Team name with record and conference standing.
struct ScheduleHeaderView: View {
    let snapshot: ScheduleSnapshot
    let logo: Image?

    var body: some View {
        HStack(spacing: 8) {
            TeamLogoView(image: logo, teamName: snapshot.teamName, size: AppTheme.logoSize)

            VStack(alignment: .leading, spacing: 0) {
                Text(snapshot.teamName)
                    .font(.headline)
                    .lineLimit(1)
                if !snapshot.summaryLine.isEmpty {
                    Text(snapshot.summaryLine)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
