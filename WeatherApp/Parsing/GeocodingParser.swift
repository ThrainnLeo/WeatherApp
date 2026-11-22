import Foundation

/// Turns geocode.maps.co's JSON array into `[Place]` (W-08).
/// The only type that knows how geocode.maps.co formats its answer.
nonisolated struct GeocodingParser {
    func parse(_ data: Data) throws(GeocodingParserError) -> [Place] {
        let items: [MapsCoPlaceDTO]
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            items = try decoder.decode([MapsCoPlaceDTO].self, from: data)
        } catch {
            throw .invalidJSON
        }

        // An empty array is a valid answer ("nothing found"), not an error.
        var seen = Set<String>()
        return items.compactMap { makePlace(from: $0) }.filter { place in
            // The geocoder can list the same town twice with slightly different coordinates
            // (the real "Paris" answer does). Rows with identical text can't be told apart,
            // so only the first is kept. `insert` returns false for a key we already have.
            seen.insert(Self.duplicateKey(for: place)).inserted
        }
    }

    /// Returns `nil` for an item whose coordinates aren't usable, so it is skipped.
    private func makePlace(from dto: MapsCoPlaceDTO) -> Place? {
        // `Double(String)` always expects a decimal point, whatever the phone's language is.
        guard let latitude = Double(dto.lat), let longitude = Double(dto.lon),
              CoordinateInput.latitudeRange.contains(latitude),
              CoordinateInput.longitudeRange.contains(longitude)
        else {
            return nil
        }

        let (name, detail) = Self.split(dto.displayName)
        return Place(name: name, detail: detail, coordinate: Coordinate(latitude: latitude, longitude: longitude))
    }

    /// "Stockholm, Stockholms kommun, Sverige" → ("Stockholm", "Stockholms kommun, Sverige").
    static func split(_ displayName: String) -> (name: String, detail: String) {
        guard let comma = displayName.firstIndex(of: ",") else {
            return (displayName.trimmingCharacters(in: .whitespaces), "")
        }
        let name = displayName[..<comma].trimmingCharacters(in: .whitespaces)
        let detail = displayName[displayName.index(after: comma)...].trimmingCharacters(in: .whitespaces)
        return (name, detail)
    }

    /// The full text the user sees. Coordinates are deliberately not part of the key.
    private static func duplicateKey(for place: Place) -> String {
        "\(place.name)|\(place.detail)"
    }
}
