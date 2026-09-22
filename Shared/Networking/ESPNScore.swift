import Foundation

/// A competitor's score.
///
/// ESPN returns this as an object (`{"value": 56.0, "displayValue": "56"}`) on
/// the schedule endpoint but as a bare string on some others, so both are
/// accepted.
struct Score: Decodable, Sendable {
    let points: Int?

    init(from decoder: any Decoder) throws {
        if let container = try? decoder.singleValueContainer() {
            if let value = try? container.decode(Double.self) {
                points = Int(value)
                return
            }
            if let text = try? container.decode(String.self) {
                points = Int(text)
                return
            }
        }

        let keyed = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try keyed.decodeIfPresent(Double.self, forKey: .value) {
            points = Int(value)
        } else if let display = try keyed.decodeIfPresent(String.self, forKey: .displayValue) {
            points = Int(display)
        } else {
            points = nil
        }
    }

    private enum CodingKeys: String, CodingKey {
        case value
        case displayValue
    }
}
