import SwiftUI

/// The "Now" header: big temperature, condition and wind (W-01).
struct CurrentConditionsView: View {
    let step: ForecastStep

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: step.condition.symbolName)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(step.condition.symbolColor)
                .font(.system(size: 44))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(TemperatureText.format(step.temperature))
                    .font(.largeTitle.bold())
                Text(step.condition.text)
                    .font(.headline)
                if let windSpeed = step.windSpeed {
                    Text("Wind \(windSpeed.formatted(.number.precision(.fractionLength(0)))) m/s")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
