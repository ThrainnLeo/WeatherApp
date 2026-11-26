/// A random number generator that gives the same numbers for the same seed (SplitMix64).
///
/// The animated background needs every cloud, raindrop and star to start at the same place every
/// time, and `SystemRandomNumberGenerator` can't be repeated. A repeatable generator also lets a test
/// check the result.
nonisolated struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        // `&+=` and `&*` wrap around on overflow instead of crashing, which the algorithm relies on.
        state &+= 0x9E37_79B9_7F4A_7C15
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        return mixed ^ (mixed >> 31)
    }
}
