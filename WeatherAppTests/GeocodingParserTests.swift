import Foundation
import Testing
@testable import WeatherApp

struct GeocodingParserTests {
    let parser = GeocodingParser()

    // MARK: - P1: real data

    @Test func parsesRealStockholmResponse() throws {
        let places = try parser.parse(loadFixture("geocode_stockholm_sample"))

        #expect(places.count == 5)
        let first = try #require(places.first)
        #expect(first.name == "Stockholm")
        #expect(first.detail == "Stockholms kommun, Stockholms län, 111 29, Sverige")
        // geocode.maps.co sends coordinates as strings; this checks they became numbers.
        #expect(first.coordinate == Coordinate(latitude: 59.3251172, longitude: 18.0710935))
    }

    // MARK: - P2: nothing found

    @Test func emptyArrayGivesNoPlaces() throws {
        #expect(try parser.parse(Data("[]".utf8)).isEmpty)
    }

    // MARK: - P3: unusable item

    @Test func itemWithInvalidLatitudeIsSkipped() throws {
        let json = placesJSON([
            item(lat: "abc", lon: "18.07", displayName: "Broken, Nowhere"),
            item(lat: "55.6052931", lon: "13.0001566", displayName: "Malmö, Malmö kommun, Skåne län, Sverige"),
        ])

        let places = try parser.parse(json)

        #expect(places.map(\.name) == ["Malmö"])
    }

    // MARK: - P4: not JSON

    @Test func htmlErrorPageThrowsInvalidJSON() {
        let html = Data("<html><body><h1>503 Service Unavailable</h1></body></html>".utf8)

        #expect(throws: GeocodingParserError.invalidJSON) {
            try parser.parse(html)
        }
    }

    // MARK: - P5: duplicates

    @Test func entriesWithIdenticalTextAreShownOnce() throws {
        // Taken from the real "Paris" answer: same text, coordinates about 2 km apart.
        let json = placesJSON([
            item(lat: "48.8588897", lon: "2.3200410", displayName: "Paris, Île-de-France, France métropolitaine, France"),
            item(lat: "48.8534951", lon: "2.3483915", displayName: "Paris, Île-de-France, France métropolitaine, France"),
        ])

        let places = try parser.parse(json)

        #expect(places.count == 1)
        // The first entry wins, so the API's order is respected.
        #expect(places.first?.coordinate == Coordinate(latitude: 48.8588897, longitude: 2.3200410))
    }
}

// MARK: - Helpers

private final class TestBundleToken {}

private func loadFixture(_ name: String) throws -> Data {
    let bundle = Bundle(for: TestBundleToken.self)
    let url = try #require(bundle.url(forResource: name, withExtension: "json"))
    return try Data(contentsOf: url)
}

private func placesJSON(_ items: [String]) -> Data {
    Data("[\(items.joined(separator: ","))]".utf8)
}

/// One item with only the fields the parser reads, plus `osm_id` as a number like the real API.
private func item(lat: String, lon: String, displayName: String) -> String {
    #"{ "osm_id": 1, "lat": "\#(lat)", "lon": "\#(lon)", "display_name": "\#(displayName)" }"#
}
