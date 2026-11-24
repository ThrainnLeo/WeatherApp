import Foundation

/// One layer of the animated weather background (W-06, H-02). Plain data: how a layer looks (colours,
/// sizes) is decided where it is drawn, so a theme can be described and tested without any drawing.
nonisolated enum WeatherLayer: Equatable, Sendable {
    case sunGlow
    case clouds(count: Int)
    case rain(count: Int)
    case snow(count: Int)
    case stars(count: Int)

    /// Seconds between frames for this layer. Slow things don't need 60 fps: a cloud moves a fraction of
    /// a point per frame at 20 fps, and every frame we skip is battery we keep.
    var minimumInterval: Double {
        switch self {
        case .rain, .snow: 1.0 / 30
        case .sunGlow, .clouds: 1.0 / 20
        case .stars: 1.0 / 10
        }
    }

    /// How many things are drawn; the glow counts as one. Used for the budget of at most 80 per theme.
    var elementCount: Int {
        switch self {
        case .sunGlow: 1
        case .clouds(let count), .rain(let count), .snow(let count), .stars(let count): count
        }
    }

    /// The elements of this layer: the first `count` of the fixed pool for its kind (empty for the glow,
    /// which is one shape without start values). A slice, so no array is built every frame.
    var particles: ArraySlice<WeatherParticle> {
        switch self {
        case .sunGlow: []
        case .clouds(let count): WeatherParticle.clouds.prefix(count)
        case .rain(let count): WeatherParticle.rain.prefix(count)
        case .snow(let count): WeatherParticle.snow.prefix(count)
        case .stars(let count): WeatherParticle.stars.prefix(count)
        }
    }
}
