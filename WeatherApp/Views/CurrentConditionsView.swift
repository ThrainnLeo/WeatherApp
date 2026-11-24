import SwiftUI

/// The "Now" hero block: place, symbol, large temperature, condition, high/low and wind (W-01).
struct CurrentConditionsView: View {
    let title: String
    let step: ForecastStep
    /// Range over the hours left today; `nil` when there are none (late evening).
    let high: Double?
    let low: Double?
    /// Shows a star next to the title when set (W-03). `nil` hides it, e.g. in previews.
    var isFavorite = false
    var onToggleFavorite: (() -> Void)? = nil
    /// When the forecast was downloaded, shown as "Updated 14:15" (W-04). `nil` hides the line, e.g.
    /// when the offline banner already says "showing data from 14:15".
    var updatedAt: Date? = nil

    // @ScaledMetric makes these sizes follow the user's Dynamic Type setting; a plain number
    // in `.system(size:)` would stay the same however large the user has set their text.
    @ScaledMetric(relativeTo: .largeTitle) private var temperatureSize: CGFloat = 88
    @ScaledMetric(relativeTo: .largeTitle) private var symbolSize: CGFloat = 44

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                if let onToggleFavorite {
                    Button(action: onToggleFavorite) {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .foregroundStyle(.yellow)
                            .font(.title3)
                    }
                    // Borderless: only the star reacts to taps, not the whole list row.
                    .buttonStyle(.borderless)
                    .accessibilityLabel(isFavorite ? "Remove from favourites" : "Add to favourites")
                }
            }

            weatherSummary
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    /// Everything below the title, read by VoiceOver as one element. The star stays a separate,
    /// tappable element; combining it in would hide it as a button.
    private var weatherSummary: some View {
        VStack(spacing: 4) {
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

            // A saved forecast that was reused shows its original time, so it is clear why nothing changed.
            if let updatedAt {
                Text("Updated \(updatedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
