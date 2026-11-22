import SwiftUI

/// The search screen (W-01, W-08): place or coordinate input on top, then the forecast.
/// Only reads the ViewModel and forwards taps; no networking or parsing here.
struct SearchView: View {
    @Bindable var viewModel: SearchViewModel

    var body: some View {
        NavigationStack {
            List {
                inputSection
                if viewModel.inputMode == .place {
                    placeResultsSection
                }
                content
            }
            .navigationTitle("Weather")
            .refreshable { await viewModel.refresh() }
        }
    }

    // MARK: - Input

    private var inputSection: some View {
        Section {
            Picker("Search by", selection: $viewModel.inputMode) {
                ForEach(InputMode.allCases, id: \.self) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            switch viewModel.inputMode {
            case .place:
                TextField("Place, e.g. Stockholm", text: $viewModel.placeQuery)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit { viewModel.searchPlaces() }
                Button("Search") { viewModel.searchPlaces() }
                    .disabled(viewModel.placeSearch == .searching)
            case .coordinates:
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
    }

    @ViewBuilder
    private var placeResultsSection: some View {
        switch viewModel.placeSearch {
        case .idle:
            EmptyView()
        case .searching:
            Section {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Searching…")
                        .foregroundStyle(.secondary)
                }
            }
        case .results(let places):
            Section("Choose a place") {
                ForEach(places) { place in
                    Button {
                        viewModel.select(place)
                    } label: {
                        PlaceRowView(place: place)
                    }
                    .tint(.primary)
                }
            }
        case .noResults(let message):
            Section {
                Text(message)
                    .foregroundStyle(.secondary)
            }
        case .failed(let message):
            Section {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Forecast

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            Section {
                Text(viewModel.inputMode == .place
                     ? "Search for a place to see its forecast."
                     : "Enter coordinates to see the forecast. Stockholm is 59.33, 18.07.")
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
                Button("Try again") { viewModel.retry() }
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

        Section {
            if let current = display.grouped.current {
                CurrentConditionsView(step: current)
            } else {
                Text("No current data. Pull down to refresh.")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text(display.title)
                .font(.headline)
                .textCase(nil)
                .foregroundStyle(.primary)
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
