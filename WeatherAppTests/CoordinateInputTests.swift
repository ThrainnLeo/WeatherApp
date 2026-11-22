import Foundation
import Testing
@testable import WeatherApp

struct CoordinateInputTests {
    // MARK: - C1, C2: valid input

    @Test func decimalPointIsValid() {
        let result = CoordinateInput.validate(latitude: "59.33", longitude: "18.07")

        #expect(result == .success(Coordinate(latitude: 59.33, longitude: 18.07)))
    }

    @Test func decimalCommaIsValid() {
        // What a Swedish keyboard types.
        let result = CoordinateInput.validate(latitude: "59,33", longitude: "18,07")

        #expect(result == .success(Coordinate(latitude: 59.33, longitude: 18.07)))
    }

    // MARK: - C3, C4, C5: not a number

    @Test func lettersAreNotANumber() {
        #expect(CoordinateInput.validate(latitude: "abc", longitude: "18.07") == .failure(.notANumber(.latitude)))
    }

    @Test func emptyTextIsNotANumber() {
        #expect(CoordinateInput.validate(latitude: "", longitude: "18.07") == .failure(.notANumber(.latitude)))
    }

    @Test func nanIsNotANumber() {
        // Double("nan") succeeds in Swift, so this checks the extra isFinite rule.
        #expect(CoordinateInput.validate(latitude: "nan", longitude: "18.07") == .failure(.notANumber(.latitude)))
    }

    // MARK: - C6, C7: out of range

    @Test func latitudeAbove90IsOutOfRange() {
        #expect(CoordinateInput.validate(latitude: "91", longitude: "18.07") == .failure(.outOfRange(.latitude)))
    }

    @Test func longitudeBelowMinus180IsOutOfRange() {
        #expect(CoordinateInput.validate(latitude: "59.33", longitude: "-181") == .failure(.outOfRange(.longitude)))
    }
}
