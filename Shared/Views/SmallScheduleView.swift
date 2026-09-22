import SwiftUI

/// Small family: just the game that matters next.
struct SmallScheduleView: View {
    let snapshot: ScheduleSnapshot
    let logos: [String: Image]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FeaturedSectionView(snapshot: snapshot, logos: logos)

            Spacer(minLength: 0)

            if let record = snapshot.recordSummary, !record.isEmpty {
                Text("\(snapshot.teamAbbreviation) \(record)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Record \(record)")
            }
        }
    }
}
