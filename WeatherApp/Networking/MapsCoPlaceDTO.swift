import Foundation

/// One item of geocode.maps.co's `/search` response (a JSON array of these).
///
/// Only the three fields we use are declared. Fields we never decode (such as `osm_id`, which the
/// docs show as a string) can't make decoding fail, whatever type they have.
nonisolated struct MapsCoPlaceDTO: Decodable, Sendable {
    /// Latitude as text, e.g. "59.3251172". geocode.maps.co sends numbers as strings.
    let lat: String
    let lon: String
    let displayName: String
}
