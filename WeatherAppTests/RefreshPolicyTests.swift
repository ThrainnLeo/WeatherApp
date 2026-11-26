import Foundation
import Testing
@testable import WeatherApp

/// Runs against a throwaway `UserDefaults` suite, so the app's real settings are never touched.
struct RefreshPolicyTests {
    // MARK: - P1: how long each choice allows

    @Test(arguments: zip(RefreshPolicy.allCases, [0.0, 900, 3600, 10800]))
    func maxCacheAgeIsInSeconds(policy: RefreshPolicy, seconds: Double) {
        #expect(policy.maxCacheAge == seconds)
    }

    @Test func aNewInstallUsesOneHour() {
        #expect(RefreshPolicy.defaultValue == .hour1)
    }

    // MARK: - P2: reading the saved choice

    @Test func missingValueGivesTheDefaultNotAlways() throws {
        let (defaults, suiteName) = try makeThrowawayDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        // `integer(forKey:)` would say 0 here, which is "Always"; nothing saved must mean the default.
        #expect(RefreshPolicy.stored(in: defaults) == .hour1)
    }

    @Test(arguments: zip([0, 15, 60, 180], RefreshPolicy.allCases))
    func savedValueIsRead(raw: Int, expected: RefreshPolicy) throws {
        let (defaults, suiteName) = try makeThrowawayDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(raw, forKey: RefreshPolicy.key)

        #expect(RefreshPolicy.stored(in: defaults) == expected)
    }

    @Test func unknownSavedValueGivesTheDefault() throws {
        let (defaults, suiteName) = try makeThrowawayDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(7, forKey: RefreshPolicy.key)

        #expect(RefreshPolicy.stored(in: defaults) == .hour1)
    }

    // MARK: - Helpers

    private func makeThrowawayDefaults() throws -> (UserDefaults, String) {
        let suiteName = "RefreshPolicyTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        return (defaults, suiteName)
    }
}
