import Foundation

/// Formats a temperature the same way everywhere: rounded, with a degree sign ("-3°").
enum TemperatureText {
    static func format(_ celsius: Double) -> String {
        // -0.3 rounds to -0, which would be shown as "-0°"; adding 0 turns -0 into plain 0.
        let rounded = celsius.rounded() + 0
        return "\(rounded.formatted(.number.precision(.fractionLength(0))))°"
    }
}
