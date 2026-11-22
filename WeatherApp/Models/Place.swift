import Foundation

/// A named place found by the geocoder, e.g. "Stockholm" in "Stockholms kommun, Sverige".
nonisolated struct Place: Codable, Hashable, Sendable, Identifiable {
    /// The first part of the geocoder's name, shown in bold.
    let name: String
    /// The rest (municipality, region, country), to tell places with the same name apart.
    let detail: String
    let coordinate: Coordinate

    var id: String { "\(name)|\(coordinate.latitude)|\(coordinate.longitude)" }
}
