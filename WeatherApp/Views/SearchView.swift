import SwiftUI

/// The first screen (W-01): coordinate input on top, then whatever `state` says.
/// Only reads the ViewModel and forwards taps; no networking or parsing here.
struct SearchView: View {
    @Bindable var viewModel: SearchViewModel

    var body: some View {
        NavigationStack {
            List {
                inputSection
                content
            }
            .navigationTitle("Weather")
            .refreshable { await viewModel.refresh() }
        }
    }

    private var inputSection: some View {
        Section {
            // Numbers-and-punctuation keyboard: the plain number pad has no minus sign.
            TextField("Latitude, e.g. 59.33", text: $viewModel.latitudeText)
                .keyboardType(.numbersAndPunctuation)
                .submitLabel(.search)
                .onSubmit { viewModel.search() }
            TextField("Longitude, e.g. 18.07", text: $viewModel.longitudeText)
                .keyboardType(.numbersAndPunctuation)
                .submitLabel(.search)
                .onSubmit { viewModel.search() }
            Button("Show forecast") { viewModel.search() }
                .disabled(viewModel.state == .loading)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            Section {
                Text("Enter coordinates to see the forecast. Stockholm is 59.33, 18.07.")
                    .foregroundStyle(.secondary)
            }
        case .loading:
            Section {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Loading forecast…")
                        .foregroundStyle(.secondary)
                }
            }
        case .failed(let message):
            Section {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Button("Try again") { viewModel.search() }
            }
        case .loaded(let display):
            forecastSections(display)
        }
    }

    @ViewBuilder
    private func forecastSections(_ display: ForecastDisplay) -> some View {
        if let staleMessage = display.staleMessage {
            Section {
                Label(staleMessage, systemImage: "wifi.slash")
                    .foregroundStyle(.orange)
            }
        }

        Section("Now") {
            if let current = display.grouped.current {
                CurrentConditionsView(step: current)
            } else {
                Text("No current data. Pull down to refresh.")
                    .foregroundStyle(.secondary)
            }
        }

        Section("Today") {
            if display.grouped.today.isEmpty {
                Text("No more hours today.")
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(display.grouped.today, id: \.time) { step in
                            HourlyItemView(step: step)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }

        Section("Next 7 days") {
            ForEach(display.grouped.days) { day in
                DailyRowView(day: day)
            }
        }
    }
}
