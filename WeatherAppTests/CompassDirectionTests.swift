import Foundation
import Testing
@testable import WeatherApp

struct CompassDirectionTests {
    // MARK: - Main directions

    @Test(arguments: zip([0.0, 90, 225], ["N", "E", "SW"]))
    func mapsDegreesToCompassPoint(degrees: Double, expected: String) {
        #expect(CompassDirection.abbreviation(forDegrees: degrees) == expected)
    }

    // MARK: - Wrap-around at north

    @Test func justBelow360IsNorth() {
        // Without the half-sector shift this would be "NW".
        #expect(CompassDirection.abbreviation(forDegrees: 359) == "N")
    }

    // MARK: - Boundary between two points

    @Test func justBeforeBoundaryIsStillNorth() {
        #expect(CompassDirection.abbreviation(forDegrees: 22.4) == "N")
    }

    @Test func atBoundaryItBecomesNortheast() {
        // N covers 337.5°–22.5°; 22.5° itself is the first value of NE.
        #expect(CompassDirection.abbreviation(forDegrees: 22.5) == "NE")
    }
}
