import Foundation

/// A place on Earth, in decimal degrees.
nonisolated struct Coordinate: Codable, Hashable, Sendable {
    let latitude: Double
    let longitude: Double
}
