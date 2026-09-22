import Foundation

/// Parses the timestamps ESPN returns.
///
/// ESPN's schedule feed mixes minute-precision stamps ("2026-09-05T16:30Z")
/// with full ISO-8601 ones, and `Date.ISO8601FormatStyle` rejects the former,
/// so the formats are tried in order. These are wire formats, never displayed.
enum ESPNDate {
    private static let formats = [
        "yyyy-MM-dd'T'HH:mmZ",
        "yyyy-MM-dd'T'HH:mm:ssZ",
        "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
    ]

    static func parse(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")

        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: string) { return date }
        }
        return nil
    }
}
