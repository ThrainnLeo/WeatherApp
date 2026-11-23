import SwiftUI

/// What the screen shows before anything has been searched: a friendly headline and a hint (H-02).
struct StartView: View {
    /// Tells the user what to do with the input fields above, which differ per input mode.
    let hint: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var symbolSize: CGFloat = 64

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.stars.fill")
                .symbolRenderingMode(.multicolor)
                .font(.system(size: symbolSize))
                // Looping motion is exactly what Reduce Motion users have asked not to see.
                .symbolEffect(.pulse, isActive: !reduceMotion)
                .accessibilityHidden(true)

            Text("Where's the weather?")
                .font(.title.weight(.semibold))
                .multilineTextAlignment(.center)

            Text(hint)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .accessibilityElement(children: .combine)
    }
}
