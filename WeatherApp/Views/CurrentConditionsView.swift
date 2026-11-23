import SwiftUI

/// The "Now" hero block: place, symbol, large temperature, condition, high/low and wind (W-01).
struct CurrentConditionsView: View {
    let title: String
    let step: ForecastStep
    /// Range over the hours left today; `nil` when there are none (late evening).
    let high: Double?
    let low: Double?

    // @ScaledMetric makes these sizes follow the user's Dynamic Type setting; a plain number
    // in `.system(size:)` would stay the same however large the user has set their text.
    @ScaledMetric(relativeTo: .largeTitle) private var temperatureSize: CGFloat = 88
    @ScaledMetric(relativeTo: .largeTitle) private var symbolSize: CGFloat = 44

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.title2.weight(.semibold))

            Image(systemName: step.condition.symbolName)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: symbolSize))
                .accessibilityHidden(true)

            // System fonts adjust their letter spacing to the size automatically, so no manual tracking.
            Text(TemperatureText.format(step.temperature))
                .font(.system(size: temperatureSize, weight: .light, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(step.condition.text)
                .font(.title3)

            if let high, let low {
                Text("High \(TemperatureText.format(high)) · Low \(TemperatureText.format(low))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let windSpeed = step.windSpeed {
                Text("Wind \(windSpeed.formatted(.number.precision(.fractionLength(0)))) m/s")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}
