import Foundation

/// Why the typed coordinates can't be used. The ViewModel turns this into a message.
nonisolated enum CoordinateInputError: Error, Equatable, Sendable {
    enum Field: Sendable {
        case latitude
        case longitude
    }

    /// The text is empty or not a finite number (e.g. "abc", "nan").
    case notANumber(Field)
    /// A number, but not a possible position on Earth.
    case outOfRange(Field)
}
