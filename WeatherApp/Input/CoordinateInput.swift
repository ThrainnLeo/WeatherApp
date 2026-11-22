import Foundation

/// Turns the two coordinate text fields into a `Coordinate` (W-14).
///
/// Only checks that the numbers are possible positions on Earth. Whether SMHI covers the point
/// is SMHI's decision; it answers "out of bounds", which becomes `.outsideForecastArea`.
nonisolated enum CoordinateInput {
    static let latitudeRange: ClosedRange<Double> = -90...90
    static let longitudeRange: ClosedRange<Double> = -180...180

    static func validate(latitude: String, longitude: String) -> Result<Coordinate, CoordinateInputError> {
        guard let latitudeValue = number(from: latitude) else { return .failure(.notANumber(.latitude)) }
        guard latitudeRange.contains(latitudeValue) else { return .failure(.outOfRange(.latitude)) }

        guard let longitudeValue = number(from: longitude) else { return .failure(.notANumber(.longitude)) }
        guard longitudeRange.contains(longitudeValue) else { return .failure(.outOfRange(.longitude)) }

        return .success(Coordinate(latitude: latitudeValue, longitude: longitudeValue))
    }

    /// Accepts both "59.33" and "59,33", because a Swedish keyboard types a decimal comma.
    /// `Double("nan")` and `Double("inf")` succeed in Swift, so non-finite values are rejected here.
    static func number(from text: String) -> Double? {
        let normalized = text
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value.isFinite else { return nil }
        return value
    }
}
