import Foundation

enum ISO8601DurationParser {
    /// Parses a subset of ISO 8601 durations like "PT20M", "PT1H30M", "P1DT2H".
    static func parseSeconds(_ value: String) -> TimeInterval? {
        let s = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard s.hasPrefix("P") else { return nil }

        var total: TimeInterval = 0
        var numberBuffer = ""
        var inTime = false

        for ch in s.dropFirst() {
            if ch == "T" {
                inTime = true
                continue
            }
            if ch.isNumber || ch == "." {
                numberBuffer.append(ch)
                continue
            }

            guard !numberBuffer.isEmpty, let n = Double(numberBuffer) else { return nil }
            numberBuffer = ""

            switch ch {
            case "D":
                total += n * 24 * 60 * 60
            case "H":
                total += n * 60 * 60
            case "M":
                // Month vs minute: after "T" it's minutes, otherwise months (we ignore months).
                if inTime {
                    total += n * 60
                } else {
                    return nil
                }
            case "S":
                total += n
            default:
                return nil
            }
        }

        if !numberBuffer.isEmpty {
            // Trailing number without unit is invalid.
            return nil
        }
        return total > 0 ? total : nil
    }
}
