import SwiftUI

/// The search screen (W-01, W-08): place or coordinate input on top, then the forecast.
/// Only reads the ViewModel and forwards taps; no networking or parsing here.
struct SearchView: View {
    @Bindable var viewModel: SearchViewModel
    let favoritesViewModel: FavoritesViewModel

    /// The two sheets this screen can open. One `.sheet(item:)` for both: two separate sheet modifiers
    /// on the same view can interfere with each other.
    private enum PresentedSheet: Identifiable {
        case favorites
        case settings

        var id: Self { self }
    }

    /// Which sheet is open, if any. Pure screen state, so it lives in the View.
    @State private var presentedSheet: PresentedSheet?

    /// The "Animated background" setting (W-04). Off draws the gradient only.
    @AppStorage(WeatherBackground.animatedKey) private var animatedBackground = true

    /// The sky (day or night) for the screens that have no forecast: start, loading, error.
    /// Kept in step with the clock by the `.task` below.
    @State private var sky = WeatherTheme.sky(at: .now)

    /// The day details pushed on top of this screen. The screen owns the path (instead of leaving it to
    /// `NavigationStack`) so it can tell that it is covered and pause the background behind a detail.
    @State private var path: [DailyForecast] = []

    /// Low Power Mode, kept up to date by the second `.task` below. Read here, once, for the whole app,
    /// instead of in every background.
    @State private var lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack(path: $path) {
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
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        presentedSheet = .favorites
                    } label: {
                        Image(systemName: "list.star")
                    }
                    .accessibilityLabel("Favourites")

                    Button {
                        presentedSheet = .settings
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(item: $presentedSheet) { sheet in
                switch sheet {
                case .favorites:
                    FavoritesView(viewModel: favoritesViewModel, sky: sky) { place in
                        viewModel.open(place)
                    }
                case .settings:
                    SettingsView(sky: sky)
                }
            }
            .refreshable { await viewModel.refresh() }
            // The gradient only shows through if the list's own grey background is hidden.
            .scrollContentBackground(.hidden)
            .background {
                // `.id` + `.transition` make a theme change a cross-fade instead of a hard cut,
                // for the gradient and the animated layers together.
                WeatherBackground(theme: theme, isAnimated: animatedBackground, isPaused: isBackgroundPaused)
                    .id(theme)
                    .transition(.opacity)
            }
            .animation(.smooth, value: theme)
        }
        // The theme says which scheme it needs: light for the day sky, dark for everything else.
        // Then `.primary` / `.secondary` text and the materials fit the gradient without
        // hard-coded colours.
        .preferredColorScheme(theme.colorScheme)
        // Runs while the app is active and stops (is cancelled) in the background. Coming back
        // to the app starts it again, which corrects the sky at once; an app left open changes
        // within a minute of 06:00 / 18:00.
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            while !Task.isCancelled {
                let current = WeatherTheme.sky(at: .now)
                // SwiftUI doesn't compare values, so only write when it changed.
                if sky != current { sky = current }
                // `try?` is fine: cancellation ends the loop through `Task.isCancelled`.
                try? await Task.sleep(for: .seconds(60))
            }
        }
        .task {
            // Low Power Mode can be switched on or off while the screen is open.
            for await _ in NotificationCenter.default.notifications(named: .NSProcessInfoPowerStateDidChange) {
                let enabled = ProcessInfo.processInfo.isLowPowerModeEnabled
                // SwiftUI doesn't compare values, so only write when it changed.
                if lowPowerMode != enabled { lowPowerMode = enabled }
            }
        }
    }

    /// The moving background stands still when nobody is looking or when motion isn't wanted: the user
    /// asked for less motion (Reduce Motion), saves power (Low Power Mode), the app isn't active, or
    /// something covers this screen (the favourites sheet, a day detail). It keeps its last frame.
    private var isBackgroundPaused: Bool {
        reduceMotion || lowPowerMode || scenePhase != .active || presentedSheet != nil || !path.isEmpty
    }

    /// The background for what is on screen: the forecast's weather, or the day/night sky
    /// when there is no forecast (start, loading, error).
    private var theme: WeatherTheme {
        guard case .loaded(let display) = viewModel.state else { return sky }
        let condition = display.grouped.current?.condition ?? display.grouped.days.first?.condition
        return condition?.theme ?? sky
    }

    /// High and low over the hours left today (what `today` holds), or `nil` when none are left.
    private func temperatureRange(of grouped: GroupedForecast) -> (high: Double, low: Double)? {
        let temperatures = grouped.today.map(\.temperature)
        guard let high = temperatures.max(), let low = temperatures.min() else { return nil }
        return (high, low)
    }

    // MARK: - Input

    /// One definition for "a request is already running", used by both the buttons and Return.
    private var isSearchingPlaces: Bool { viewModel.placeSearch == .searching }
    private var isLoadingForecast: Bool { viewModel.state == .loading }

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
                    // Return on the keyboard follows the same rule as the button below: nothing while a
                    // search is running. Otherwise a double Return cancels the first request and sends a
                    // second one, and the geocoder limits how many requests a key may send.
                    .onSubmit { if !isSearchingPlaces { viewModel.searchPlaces() } }
                Button("Search") { viewModel.searchPlaces() }
                    .disabled(isSearchingPlaces)
            case .coordinates:
                // Numbers-and-punctuation keyboard: the plain number pad has no minus sign.
                TextField("Latitude, e.g. 59.33", text: $viewModel.latitudeText)
                    .keyboardType(.numbersAndPunctuation)
                    .submitLabel(.search)
                    .onSubmit { if !isLoadingForecast { viewModel.search() } }
                TextField("Longitude, e.g. 18.07", text: $viewModel.longitudeText)
                    .keyboardType(.numbersAndPunctuation)
                    .submitLabel(.search)
                    .onSubmit { if !isLoadingForecast { viewModel.search() } }
                Button("Show forecast") { viewModel.search() }
                    .disabled(isLoadingForecast)
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
                    sky: sky,
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
