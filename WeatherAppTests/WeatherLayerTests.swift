import Foundation
import Testing
@testable import WeatherApp

/// `WeatherTheme` lives on the main actor (the module's default), so these tests do too.
@MainActor
struct WeatherLayerTests {
    // MARK: - L1: which theme gets which layers

    @Test(arguments: [WeatherTheme.rain, .storm])
    func rainThemesHaveRain(theme: WeatherTheme) {
        #expect(theme.layers.contains { $0.isRain })
    }

    @Test func nightHasStarsAndNothingElse() {
        #expect(WeatherTheme.night.layers.allSatisfy { $0.isStars })
        #expect(!WeatherTheme.night.layers.isEmpty)
    }

    @Test func onlyNightHasStars() {
        for theme in WeatherTheme.allCases where theme != .night {
            #expect(!theme.layers.contains { $0.isStars }, "\(theme) should not have stars")
        }
    }

    @Test func snowHasSnowAndCloudyHasClouds() {
        #expect(WeatherTheme.snow.layers.contains { $0.isSnow })
        #expect(WeatherTheme.cloudy.layers.contains { $0.isClouds })
    }

    @Test(arguments: [WeatherTheme.day, .sunny])
    func dayAndSunnyHaveTheSunGlow(theme: WeatherTheme) {
        #expect(theme.layers.contains { $0.isSunGlow })
    }

    @Test func stormRainsHarderThanRain() {
        #expect(rainCount(of: .storm) > rainCount(of: .rain))
    }

    // MARK: - L2: the battery budget

    @Test(arguments: WeatherTheme.allCases)
    func noThemeHasMoreThan80Elements(theme: WeatherTheme) {
        let total = theme.layers.reduce(0) { $0 + $1.elementCount }
        #expect(total <= 80)
    }

    @Test(arguments: WeatherTheme.allCases)
    func noThemeRunsFasterThan30FramesPerSecond(theme: WeatherTheme) {
        #expect(theme.frameInterval >= 1.0 / 30)
    }

    @Test func frameIntervalIsTheShortestOfTheLayers() {
        #expect(WeatherTheme.night.frameInterval == 1.0 / 10)
        #expect(WeatherTheme.cloudy.frameInterval == 1.0 / 20)
        #expect(WeatherTheme.rain.frameInterval == 1.0 / 30)
    }

    // MARK: - L3: the pools are big enough

    @Test(arguments: WeatherTheme.allCases)
    func everyLayerGetsAsManyParticlesAsItAsksFor(theme: WeatherTheme) {
        // The glow is one shape without particles; every other layer takes its elements from a pool.
        // If a theme asked for more than its pool holds, `prefix` would quietly give fewer.
        for layer in theme.layers where !layer.isSunGlow {
            #expect(layer.particles.count == layer.elementCount, "\(theme): \(layer)")
        }
    }

    // MARK: - Helpers

    private func rainCount(of theme: WeatherTheme) -> Int {
        theme.layers.reduce(0) { total, layer in
            if case .rain(let count) = layer { total + count } else { total }
        }
    }
}

private extension WeatherLayer {
    var isSunGlow: Bool { if case .sunGlow = self { true } else { false } }
    var isClouds: Bool { if case .clouds = self { true } else { false } }
    var isRain: Bool { if case .rain = self { true } else { false } }
    var isSnow: Bool { if case .snow = self { true } else { false } }
    var isStars: Bool { if case .stars = self { true } else { false } }
}
