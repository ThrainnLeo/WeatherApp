import Foundation
import Testing
@testable import WeatherApp

/// Pure maths and data, no UI, so these tests need no actor.
struct WeatherMotionTests {
    // MARK: - M1: wrapping

    @Test(arguments: [
        (value: -1.0, length: 10.0, expected: 9.0),
        (value: 23.0, length: 10.0, expected: 3.0),
        (value: 10.0, length: 10.0, expected: 0.0),
        (value: 0.0, length: 10.0, expected: 0.0),
    ])
    func wrappedKeepsTheValueInsideTheLength(value: Double, length: Double, expected: Double) {
        #expect(WeatherMotion.wrapped(value, length: length) == expected)
    }

    // MARK: - M2: position

    @Test func positionNeverLeavesTheMargins() {
        let extent = 800.0
        let margin = 20.0
        for time in stride(from: 0.0, through: 300.0, by: 0.37) {
            let position = WeatherMotion.position(
                startFraction: 0.63, speed: 540, at: time, extent: extent, margin: margin
            )
            #expect(position >= -margin && position < extent + margin, "t = \(time)")
        }
    }

    @Test func positionRepeatsAfterOneCycle() {
        // Cycle = 800 + 2 × 20 = 840 points, at 100 points per second = 8.4 seconds.
        let first = WeatherMotion.position(startFraction: 0.3, speed: 100, at: 3, extent: 800, margin: 20)
        let later = WeatherMotion.position(startFraction: 0.3, speed: 100, at: 3 + 8.4, extent: 800, margin: 20)

        #expect(abs(first - later) < 1e-9)
    }

    @Test func elementLeavesBelowAndComesBackInAboveTheTop() {
        // Starts at the top margin (-20) and falls 100 points per second.
        func position(at time: Double) -> Double {
            WeatherMotion.position(startFraction: 0, speed: 100, at: time, extent: 800, margin: 20)
        }

        // Compared with a small tolerance: 8.3 has no exact binary form, so 100 × 8.3 is not exactly 830.
        // 8.3 s: 810, below the bottom edge (800) but inside the margin, so it is not visible yet.
        #expect(abs(position(at: 8.3) - 810) < 1e-9)
        // 8.5 s: past the end of the cycle, so it is back above the top edge (0), outside the screen.
        #expect(abs(position(at: 8.5) - (-10)) < 1e-9)
    }

    // MARK: - M3: repeatable start values

    @Test func sameSeedGivesTheSameParticles() {
        let first = WeatherParticle.field(count: 20, seed: 5, speed: 10...20, size: 1...3)
        let second = WeatherParticle.field(count: 20, seed: 5, speed: 10...20, size: 1...3)

        #expect(first == second)
    }

    @Test func differentSeedsGiveDifferentParticles() {
        let first = WeatherParticle.field(count: 20, seed: 5, speed: 10...20, size: 1...3)
        let second = WeatherParticle.field(count: 20, seed: 6, speed: 10...20, size: 1...3)

        #expect(first != second)
    }

    @Test func fieldHasTheRequestedCountAndValuesInRange() {
        let particles = WeatherParticle.field(count: 50, seed: 9, speed: 10...20, size: 1...3)

        #expect(particles.count == 50)
        for particle in particles {
            #expect((0...1).contains(particle.lane))
            #expect((0...1).contains(particle.start))
            #expect((10...20).contains(particle.speed))
            #expect((1...3).contains(particle.size))
            #expect((0...(2 * Double.pi)).contains(particle.phase))
        }
    }

    @Test func negativeCountGivesAnEmptyField() {
        #expect(WeatherParticle.field(count: -3, seed: 1, speed: 1...2, size: 1...2).isEmpty)
    }
}
