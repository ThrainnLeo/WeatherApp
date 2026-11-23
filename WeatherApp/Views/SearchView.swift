import SwiftUI

/// The search screen (W-01, W-08): place or coordinate input on top, then the forecast.
/// Only reads the ViewModel and forwards taps; no networking or parsing here.
struct SearchView: View {
    @Bindable var viewModel: SearchViewModel
    let favoritesViewModel: FavoritesViewModel

    /// Whether the favourites sheet is open. Pure screen state, so it lives in the View.
    @State private var showingFavorites = false

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
            .navigationDestination(for: DailyForecast.self) { day in
                DayDetailView(day: day)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingFavorites = true
                    } label: {
                        Image(systemName: "list.star")
                    }
                    .accessibilityLabel("Favourites")
                }
            }
            .sheet(isPresented: $showingFavorites) {
                FavoritesView(viewModel: favoritesViewModel) { place in
                    viewModel.open(place)
                }
            }
            .refreshable { await viewModel.refresh() }
            // The gradient only shows through if the list's own grey background is hidden.
            .scrollContentBackground(.hidden)
            .background {
                // `.id` + `.transition` make a theme change a cross-fade instead of a hard cut.
                theme.gradient
                    .ignoresSafeArea()
                    .id(theme)
                    .transition(.opacity)
            }
            .animation(.smooth, value: theme)
        }
        // Every gradient is dark, so the whole app uses the dark colour scheme: then `.primary` /
        // `.secondary` text and the materials are light-on-dark without hard-coded colours.
        // Change this one line to hand the choice back to the user's own light/dark setting.
        .preferredColorScheme(.dark)
    }

    /// The background for what is on screen: the forecast's weather, or the night sky when
    /// there is no forecast (start, loading, error).
    private var theme: WeatherTheme {
        guard case .loaded(let display) = viewModel.state else { return .night }
        let condition = display.grouped.current?.condition ?? display.grouped.days.first?.condition
        return condition?.theme ?? .night
    }

    /// High and low over the hours left today (what `today` holds), or `nil` when none are left.
    private func temperatureRange(of grouped: GroupedForecast) -> (high: Double, low: Double)? {
        let temperatures = grouped.today.map(\.temperature)
        guard let high = temperatures.max(), let low = temperatures.min() else { return nil }
        return (high, low)
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
        .frostedRows()
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
            .frostedRows()
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
            .frostedRows()
        case .noResults(let message):
            Section {
                Text(message)
                    .foregroundStyle(.secondary)
            }
            .frostedRows()
        case .failed(let message):
            Section {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
            .frostedRows()
        }
    }

    // MARK: - Forecast

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            // Sits directly on the gradient, like the forecast's hero block: no card, no separator.
            Section {
                StartView(
                    hint: viewModel.inputMode == .place
                        ? "Search for a place above to see its forecast."
                        : "Enter coordinates above to see the forecast. Stockholm is 59.33, 18.07."
                )
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        case .loading:
            ForecastSkeletonView()
        case .failed(let message):
            Section {
                ContentUnavailableView {
                    Label("Couldn't show the forecast", systemImage: "exclamationmark.triangle.fill")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try again") { viewModel.retry() }
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
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
            .frostedRows()
        }

        // The hero sits directly on the gradient: no card, no separator.
        Section {
            if let current = display.grouped.current {
                let range = temperatureRange(of: display.grouped)
                CurrentConditionsView(
                    title: display.title,
                    step: current,
                    high: range?.high,
                    low: range?.low,
                    isFavorite: viewModel.currentPlace.map(favoritesViewModel.isFavorite) ?? false,
                    // Only shown when a forecast is loaded, so a place SMHI can't cover (Paris)
                    // never gets a star.
                    onToggleFavorite: viewModel.currentPlace.map { place in
                        { favoritesViewModel.toggle(place) }
                    }
                )
            } else {
                VStack(spacing: 4) {
                    Text(display.title)
                        .font(.headline)
                    Text("No current data. Pull down to refresh.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)

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
        .frostedRows()

        Section("Next 7 days") {
            ForEach(display.grouped.days) { day in
                // The row only says *which* day was tapped; `navigationDestination` below decides
                // what to show. Navigation stays in the View layer, the ViewModel never navigates.
                NavigationLink(value: day) {
                    DailyRowView(day: day)
                }
            }
        }
        .frostedRows()
    }
}
