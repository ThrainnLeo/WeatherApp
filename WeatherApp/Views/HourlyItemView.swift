import SwiftUI

/// One hour in the "Today" row: time, symbol, temperature.
struct HourlyItemView: View {
    let step: ForecastStep

    var body: some View {
        VStack(spacing: 6) {
            Text(step.time.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
            Image(systemName: step.condition.symbolName)
                .symbolRenderingMode(.multicolor)
                .font(.title2)
                .accessibilityLabel(step.condition.text)
            Text(TemperatureText.format(step.temperature))
                .font(.callout.weight(.semibold))
        }
        .frame(minWidth: 48)
        .accessibilityElement(children: .combine)
    }
}
