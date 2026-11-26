import SwiftUI

/// Draws the layers of the animated background into a `Canvas` (W-06, H-02).
///
/// A frame is worked out from the time alone (see `WeatherMotion`), so nothing is kept between frames.
/// `nonisolated` because a `Canvas` drawing closure isn't tied to the main actor, and a main-actor
/// function couldn't be called from it. Everything is deliberately faint: it sits behind the text.
nonisolated enum WeatherLayerRenderer {
    /// The tag of the cloud symbol. `Canvas` resolves a symbol once and reuses it, which is cheaper
    /// than turning an SF Symbol into a drawing again in every frame.
    static let cloudSymbolID = "cloud"

    static func draw(
        _ layers: [WeatherLayer],
        isLight: Bool,
        in context: inout GraphicsContext,
        size: CGSize,
        time: Double
    ) {
        for layer in layers {
            switch layer {
            case .sunGlow:
                drawSunGlow(in: &context, size: size, time: time, isLight: isLight)
            case .clouds:
                drawClouds(layer.particles, in: &context, size: size, time: time, isLight: isLight)
            case .rain:
                drawRain(layer.particles, in: &context, size: size, time: time)
            case .snow:
                drawSnow(layer.particles, in: &context, size: size, time: time)
            case .stars:
                drawStars(layer.particles, in: &context, size: size, time: time)
            }
        }
    }

    // MARK: - Layers

    /// A soft warm light in the top right corner that swells and fades a little, 8 seconds a breath.
    /// A sine is slow at both ends of the swing, which is the ease-in-out a breath should have.
    private static func drawSunGlow(in context: inout GraphicsContext, size: CGSize, time: Double, isLight: Bool) {
        let breath = 0.5 + 0.5 * sin(time * 2 * .pi / 8)
        let strength = (isLight ? 0.40 : 0.22) + 0.08 * breath
        let radius = max(size.width, size.height) * 0.6
        let center = CGPoint(x: size.width * 0.85, y: size.height * 0.08)
        // A warm white, not yellow: yellow over blue mixes to a muddy green.
        let warm = Color(red: 1.0, green: 0.95, blue: 0.82)
        let area = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.fill(
            Path(ellipseIn: area),
            with: .radialGradient(
                Gradient(colors: [warm.opacity(strength), warm.opacity(0)]),
                center: center, startRadius: 0, endRadius: radius
            )
        )
    }

    /// White clouds drifting left to right in the upper half, 6 to 14 points a second, at constant
    /// speed (constant motion has no easing). On the light day sky they need more opacity to show.
    private static func drawClouds(
        _ clouds: ArraySlice<WeatherParticle>,
        in context: inout GraphicsContext, size: CGSize, time: Double, isLight: Bool
    ) {
        guard let symbol = context.resolveSymbol(id: cloudSymbolID) else { return }
        for cloud in clouds {
            // A margin of one cloud width: it is fully off screen before it jumps back.
            let x = WeatherMotion.position(
                startFraction: cloud.start, speed: cloud.speed, at: time,
                extent: size.width, margin: cloud.size
            )
            let y = size.height * (0.06 + 0.5 * cloud.lane)
            // One copy of the context per cloud, so its position and scale don't leak into the next.
            var cloudContext = context
            cloudContext.opacity = isLight ? 0.40 : 0.12
            cloudContext.translateBy(x: x, y: y)
            let scale = cloud.size / symbol.size.width
            cloudContext.scaleBy(x: scale, y: scale)
            cloudContext.draw(symbol, at: .zero, anchor: .center)
        }
    }

    /// Thin slanted streaks, all in one path and one stroke call: the cheapest way to draw many lines.
    private static func drawRain(
        _ drops: ArraySlice<WeatherParticle>,
        in context: inout GraphicsContext, size: CGSize, time: Double
    ) {
        // Sideways shift per point fallen: about 11 degrees of slant.
        let slant = 0.2
        var streaks = Path()
        for drop in drops {
            let y = WeatherMotion.position(
                startFraction: drop.start, speed: drop.speed, at: time,
                extent: size.height, margin: drop.size
            )
            // The lanes span the width plus the slant, so the slanted rain also reaches the right edge.
            let x = drop.lane * (size.width + size.height * slant) - y * slant
            streaks.move(to: CGPoint(x: x + drop.size * slant, y: y - drop.size))
            streaks.addLine(to: CGPoint(x: x, y: y))
        }
        context.stroke(streaks, with: .color(.white.opacity(0.28)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
    }

    /// Small round flakes that float down slowly and sway sideways, one fill for all of them.
    private static func drawSnow(
        _ flakes: ArraySlice<WeatherParticle>,
        in context: inout GraphicsContext, size: CGSize, time: Double
    ) {
        var path = Path()
        for flake in flakes {
            let y = WeatherMotion.position(
                startFraction: flake.start, speed: flake.speed, at: time,
                extent: size.height, margin: flake.size
            )
            let x = flake.lane * size.width + sin(flake.phase + time * 0.6) * 12
            let radius = flake.size / 2
            path.addEllipse(in: CGRect(x: x - radius, y: y - radius, width: flake.size, height: flake.size))
        }
        context.fill(path, with: .color(.white.opacity(0.7)))
    }

    /// Stars stand still and twinkle. Opacity swings between 0.3 and 0.9 and never reaches 0,
    /// so a star never pops in or out of existence.
    private static func drawStars(
        _ stars: ArraySlice<WeatherParticle>,
        in context: inout GraphicsContext, size: CGSize, time: Double
    ) {
        for star in stars {
            let twinkle = 0.5 + 0.5 * sin(star.phase + time * 0.8)
            let x = star.lane * size.width
            // Only in the upper three quarters, where the sky is.
            let y = star.start * size.height * 0.75
            let radius = star.size / 2
            context.fill(
                Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: star.size, height: star.size)),
                with: .color(.white.opacity(0.3 + 0.6 * twinkle))
            )
        }
    }
}
