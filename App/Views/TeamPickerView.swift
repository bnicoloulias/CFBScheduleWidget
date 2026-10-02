import SwiftUI

/// The window's team chooser. Reads the same directory the widget's
/// configuration picker uses, so both search the same list.
struct TeamPickerView: View {
    @Binding var teamID: String

    @Environment(\.dismiss) private var dismiss
    @State private var entries: [TeamDirectory.Entry] = []
    @State private var search = ""
    @State private var isLoading = true

    private var results: [TeamDirectory.Entry] {
        guard !search.isEmpty else { return entries }
        return entries.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading teams…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if entries.isEmpty {
                    ContentUnavailableView(
                        "No Teams",
                        systemImage: "wifi.slash",
                        description: Text("The team list could not be loaded. Check your connection and try again.")
                    )
                } else if results.isEmpty {
                    ContentUnavailableView.search(text: search)
                } else {
                    List(results, id: \.id) { entry in
                        Button {
                            teamID = entry.id
                            dismiss()
                        } label: {
                            HStack {
                                Text(entry.name)
                                Spacer(minLength: DrawingConstants.minimumGap)
                                if entry.id == teamID {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                } else {
                                    Text(entry.abbreviation)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Choose a Team")
            .searchable(text: $search, prompt: "Search teams")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .frame(minWidth: DrawingConstants.minimumWidth, minHeight: DrawingConstants.minimumHeight)
        .task {
            entries = await TeamDirectory.shared.all()
            isLoading = false
        }
    }

    private enum DrawingConstants {
        static let minimumGap: Double = 8
        static let minimumWidth: Double = 340
        static let minimumHeight: Double = 440
    }
}

#Preview {
    @Previewable @State var teamID = Team.defaultID
    TeamPickerView(teamID: $teamID)
}
