# WeatherApp

iOS weather app (Swift, SwiftUI) — HI1033 / CM2023 Lab B:2.
Team: Thrainn Leo Thorisson, Hugo Persson

## Overview
WeatherApp shows the weather forecast for any place in the Nordic area. You search by place name
(e.g. "Stockholm") or by coordinates and get the current conditions, an hourly forecast for the rest
of today and a summary for the next 7 days; tapping a day shows its full forecast. Favourite places
are one tap away, the last forecast for each place is saved so the app still shows something offline,
and a settings screen controls how often new data is fetched.

## Architecture
The app is built with MVVM plus a repository layer, so each part has one clear job. The SwiftUI views
only show data and pass on what the user does, like searching for a city or adding a favourite. Three
ViewModels keep the state of what is on screen: `SearchViewModel` (search, loading, forecast or error),
`FavoritesViewModel` (the favourites list) and `SettingsViewModel` (clearing saved data); the detail
screen needs none, because it only shows a day that is already loaded. The ViewModels never fetch or
parse anything themselves; they ask a repository. `WeatherRepository` is the app's single source of
forecasts: it fetches the forecast from SMHI through an API client, turns the JSON into our own models
with a parser, saves the result locally and returns it. If a saved forecast is recent enough (the
refresh setting), it returns that without asking SMHI at all. When there is no network, it returns the
last saved forecast together with a message that explains why. `PlaceRepository` turns place names
into coordinates with geocode.maps.co in the same way (client → parser). Both repositories do their
work off the main thread, so the screen never freezes. Because networking, parsing, storage and UI are
kept apart, each part can be tested on its own, and changing one layer, such as how data is stored,
doesn't affect the others.

```
View (SwiftUI)           SearchView, DayDetailView, FavoritesView, SettingsView
   │  user actions ↓              ↑ @Observable state
ViewModel (@MainActor)   SearchViewModel, FavoritesViewModel, SettingsViewModel
   │  async calls ↓               ↑ ForecastResult / [Place] / WeatherError
Repository (@concurrent) WeatherRepository, PlaceRepository
   │
   ├─ API clients   SMHIAPIClient, MapsCoGeocodingClient   (URLSession, 15 s timeout)
   ├─ Parsers       ForecastParser, GeocodingParser         (JSON DTO → our models)
   └─ Storage       UserDefaultsCacheStore, UserDefaultsFavoritesStore, Secrets.plist

Transformation (pure functions, used by the ViewModel): ForecastGrouper, CompassDirection
```

## Main files and responsibilities
| File | Layer | Responsibility |
|---|---|---|
| `WeatherAppApp.swift` | App | Creates the real dependencies once (one shared `WeatherRepository`) and the three ViewModels |
| `Views/SearchView.swift` | View | Main screen: Place/Coordinates input, match list, forecast, toolbar for favourites and settings, navigation to the detail screen |
| `Views/CurrentConditionsView.swift` | View | Hero block: place, symbol, temperature, high/low, wind, "Updated", favourite star |
| `Views/HourlyItemView.swift`, `DailyRowView.swift` | View | One hour in "Today", one day in "Next 7 days" |
| `Views/DayDetailView.swift`, `DetailStepRowView.swift` | View | Detail screen for one day, one row per forecast step |
| `Views/FavoritesView.swift`, `PlaceRowView.swift` | View | Favourites sheet; a place row |
| `Views/SettingsView.swift`, `RefreshPolicy+Display.swift` | View | Settings sheet (refresh choice, animated background, clear saved forecasts) |
| `Views/StartView.swift`, `ForecastSkeletonView.swift` | View | Start screen and loading placeholder |
| `Views/WeatherTheme.swift`, `WeatherBackground.swift` | View | Background gradient per weather / day / night |
| `Views/WeatherLayer*.swift`, `WeatherMotion.swift`, `WeatherParticle.swift`, `SeededGenerator.swift` | View | Animated clouds, rain, snow, sun glow and stars |
| `Views/WeatherCondition+Display.swift`, `TemperatureText.swift` | View | Symbol and text per condition; temperature formatting |
| `ViewModels/SearchViewModel.swift` | ViewModel | Screen state (`LoadState`), place search, race guard (request IDs), refresh rule, current place |
| `ViewModels/FavoritesViewModel.swift` | ViewModel | Favourites list: toggle, delete, "same place", last known temperature |
| `ViewModels/SettingsViewModel.swift` | ViewModel | Clears saved forecasts through the repository |
| `ViewModels/LoadState.swift`, `PlaceSearchState.swift`, `ForecastDisplay.swift`, `InputMode.swift` | ViewModel | The states the screen can be in |
| `ViewModels/UserMessages.swift` | ViewModel | Every error and banner text in one place |
| `Repository/WeatherRepository.swift` | Repository | Reuse fresh saved forecast → fetch → parse → save → fallback to saved forecast |
| `Repository/PlaceRepository.swift` | Repository | Place search: client → parser |
| `Repository/ForecastResult.swift` | Repository | A forecast plus when it was fetched and why it may be stale |
| `Networking/SMHIAPIClient.swift`, `WeatherAPIClient.swift` | Networking | Downloads SMHI JSON; protocol so tests can use a fake |
| `Networking/MapsCoGeocodingClient.swift`, `GeocodingClient.swift` | Networking | Downloads place matches; protocol for fakes |
| `Networking/APIEnvironment.swift` | Networking | The only place with server addresses |
| `Networking/SMHIForecastDTO.swift`, `MapsCoPlaceDTO.swift` | Networking | Structs that mirror the JSON exactly |
| `Parsing/ForecastParser.swift`, `GeocodingParser.swift` (+ `…Error.swift`) | Parsing | JSON → `Forecast` / `[Place]`; the only code that knows the API formats |
| `Transformation/ForecastGrouper.swift` | Transformation | Current + hourly today + 7 days, in the user's time zone |
| `Transformation/CompassDirection.swift` | Transformation | Wind degrees → compass point |
| `Persistence/UserDefaultsCacheStore.swift`, `CacheStore.swift`, `CachedForecast.swift` | Persistence | Saved forecast per place (JSON in UserDefaults) |
| `Persistence/UserDefaultsFavoritesStore.swift`, `FavoritesStore.swift` | Persistence | Saved favourites |
| `Persistence/Secrets.swift` | Persistence | Reads the API key from the gitignored `Secrets.plist` |
| `Input/CoordinateInput.swift` | Input | Validates typed coordinates (decimal comma, range, no `nan`) |
| `Models/*.swift` | Model | Our own types: `Forecast`, `ForecastStep`, `DailyForecast`, `GroupedForecast`, `WeatherCondition`, `Place`, `Coordinate`, `WeatherError`, `RefreshPolicy` |

## Data flow: "Search" → forecast on screen
1. **Search.** In Place mode the user types "Stockholm" and taps Search. `SearchView` calls
   `SearchViewModel.searchPlaces()`. An empty field gives a message and no request.
2. **Place search.** The ViewModel cancels any earlier search, gives this one a new request ID and sets
   "Searching…". `PlaceRepository.search` (off the main thread) calls `MapsCoGeocodingClient`, which
   reads the key from `Secrets.plist`, builds the URL with `URLComponents` (so "Malmö" is encoded) and
   downloads the answer.
3. **Matches.** `GeocodingParser` turns the JSON (coordinates arrive as strings) into `[Place]`,
   skipping broken items and identical rows. If this is still the newest search, the ViewModel shows
   the list.
4. **Choose a place.** Tapping a match calls `select(place)`: the list closes, the place becomes
   `currentPlace` (for the favourite star) and the state becomes `.loading` (the skeleton).
   In Coordinates mode, `CoordinateInput.validate` checks the two fields and the flow joins here.
5. **Forecast.** `WeatherRepository.forecast(for:reusingCacheYoungerThan:)` runs off the main thread.
   If a saved forecast is younger than the refresh setting, it is returned at once. Otherwise
   `SMHIAPIClient` downloads the forecast (coordinates with a decimal point, at most 6 decimals),
   the HTTP status is classified, `ForecastParser` builds a `Forecast`, and it is saved with the time.
6. **Back on screen.** If this is still the newest request (the race guard), `ForecastGrouper` splits
   the forecast into "now", today's hours and the next 7 days in the user's time zone, and the
   ViewModel sets `state = .loaded(…)`.
7. **Redraw.** `SearchViewModel` is `@Observable`, so `SearchView` redraws by itself: the background
   follows the weather, then the hero block, "Today" and "Next 7 days". Tapping a day opens
   `DayDetailView` (navigation lives in the View; the ViewModel never navigates).

## Error handling and offline behaviour
Every failure becomes one `WeatherError`, classified in plain functions in `Models/WeatherError.swift`,
and every case has a user text in `UserMessages`. The compiler forces a text for each new case, so no
error can end up as a blank screen.

| Situation | What the user sees |
|---|---|
| Offline, place loaded before | The saved forecast, with "Offline – showing data from 14:15" |
| Offline, nothing saved | Error screen "You're offline…" with "Try again" |
| Server error / broken answer, place loaded before | The saved forecast with "Couldn't update – showing data from …" (a broken answer never overwrites a good saved one) |
| Place outside SMHI's area (e.g. Paris) | "SMHI only has forecasts for the Nordic area…" |
| Request takes over 15 s | "The server didn't answer in time." (or the saved forecast) |
| Invalid coordinates | A message for the field, no request |
| Place search: no matches / missing key / key rejected / too many searches | "No places found…" / "Place search isn't set up…" / "The place search key was rejected…" / "Too many searches…" |
| A newer search replaced an older one | Nothing: the cancelled result is ignored |

Saved data: one forecast per place (coordinates rounded to ~1 km) and the favourites, both as JSON in
UserDefaults. Corrupt saved data is treated as "nothing saved", never a crash.

## Tests
- Unit tests (Swift Testing) are in `WeatherAppTests/`: 15 test files, about 90 tests. They cover the
  parsers (with two real API responses as fixtures), error classification, the repository's
  fetch/cache/fallback and reuse rules, grouping by local day (including a daylight-saving day),
  coordinate validation, compass directions, favourites, the refresh setting, the search ViewModel
  and the animated background's limits.
- No test uses the network: fakes for the API client and stores are in `WeatherAppTests/Fakes/`,
  and the clock and calendar are injected.
- Run them with **⌘U** in Xcode (the iPhone simulator). Results and the UX scenarios are in
  `docs/TEST_REPORT.md`.

## APIs
| Purpose | API | Address (in `APIEnvironment.swift`) |
|---|---|---|
| Forecast | SMHI open data, `snow1g/version/1` | `https://opendata-download-metfcst.smhi.se/api/category/snow1g/version/1/geotype/point/lon/{lon}/lat/{lat}/data.json` |
| Place search | geocode.maps.co | `https://geocode.maps.co/search?q={place}&limit=10&api_key={key}` |

- SMHI needs no key and only covers the Nordic area. The old `pmp3g` API was retired on 31 March 2026.
  The KTH test proxy is not used (it still serves the old format); the app always uses the real APIs.
- **Setting up the geocode.maps.co key:** copy `Secrets.example.plist` (repo root) to
  `WeatherApp/Secrets.plist` and replace `PASTE_YOUR_GEOCODE_MAPS_CO_KEY_HERE` with your free key.
  `Secrets.plist` is in `.gitignore` and is never committed. Xcode copies it into the app
  automatically (synced folder); no project setting is needed. Without a key, place search shows
  "isn't set up" and coordinate search still works.
