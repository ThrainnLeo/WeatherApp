# SPEC.md — WeatherApp (HI1033 / CM2023 Lab B:2)

## 1. AI meta-instructions
> Read `CLAUDE.md`, `SPEC.md`, `STYLE.md` and `CONTEXT.md` first. Where they conflict with
> a student's request, point out the conflict — the students decide.
- Follow the workflow in `STYLE.md`: you write the code in small steps and explain each step
  (STYLE.md §3); Core pieces end with a teach-back check (STYLE.md §4).
- Never mark a requirement done unless a student can explain it.
- Never write test results, tick requirements, or write `docs/REFLECTION.md` or `docs/LLM_PROCESS.md`.
- No new tests without student approval. Only test what §4 lists under "Test ideas".
- All code, comments and documentation in English.
- Before coding a component, make sure it has an entry in §4 (spec before code).
- Remind the students of the end-of-session ritual (§9) at the end of every session.

## 2. Project facts
| Course | Lab | Platform | Team | Grade target |
|---|---|---|---|---|
| HI1033 / CM2023 | B:2 Weather | iOS · Swift · SwiftUI | Thrainn Leo Thorisson + Hugo Persson | A |

Forecast API: SMHI snow1g · Geocoding API: geocode.maps.co (API key in a gitignored file) · KTH proxy: not used

## 3. Requirements checklist
Status: ☐ not started · ◐ in progress · ☑ done (only ticked by a student who can explain it)

### Basic (screens)
| ID | Requirement | Status |
|---|---|---|
| W-01 | Search/home screen: enter city name or coordinates; shows current conditions and a 7-day forecast summary | ☐ |
| W-02 | Detail screen: full forecast for a selected day — temperature, condition, plus extra API data (wind, precipitation, …) | ☐ |
| W-03 | Favourites: mark places as favourites; dedicated quick-access view for them | ☐ |
| W-04 | Settings screen: configure data refresh rate and other UI preferences | ☐ |

### Detailed
| ID | Requirement | Status |
|---|---|---|
| W-05 | Forecast data fetched from open-meteo.com or the SMHI API | ☐ |
| W-06 | Shows temperature + visual weather condition (icon/colour/text) for each of the next 7 days | ☐ |
| W-07 | Data grouped: hourly detail for today, daily overview for remaining days | ☐ |
| W-08 | Accepts city name or coordinates; city name resolved to coordinates via geocoding API | ☐ |
| W-09 | Parsed data stored locally so there is something to show without network | ☐ |
| W-10 | No network: no crash, meaningful message, last successfully fetched data shown if available | ☐ |
| W-11 | Works correctly in portrait and landscape (iPhone and iPad) | ☐ |
| W-12 | Separate class/struct parses the JSON response into the internal data model | ☐ |
| W-13 | Forecast data displayed in a scrollable list | ☐ |
| W-14 | Coordinate input accepts only valid floating-point values | ☐ |
| W-15 | All network requests run off the main thread | ☐ |
| W-16 | All errors handled: a failed request never causes a crash or a silent blank screen | ☐ |
| W-17 | Tests for at least two of: JSON parsing, error-state logic, data transformation — runnable and passing | ☐ |
| W-18 | Test report documents ≥ 20 UX scenarios (start state, action, expected result) | ☐ |
| W-19 | Final build uses the real API, not the KTH proxy | ☐ |

### Higher grade (craft)
| ID | Requirement | Status |
|---|---|---|
| H-01 | Structured code: networking, transformation, state and UI are distinct layers; deliberate naming | ☐ |
| H-02 | Designed UI: clear hierarchy, consistent spacing, designed loading and error states | ☐ |
| H-03 | Oral depth: we can explain trade-offs and consequences of each structural decision | ☐ |

### Submission
| ID | Requirement | Status |
|---|---|---|
| S-01 | Reflection report (~½ page): one surprise, one thing to do differently | ☐ |
| S-02 | Appendix A — `docs/TEST_REPORT.md` + test files | ☐ |
| S-03 | Appendix B — `README.md` architecture description | ☐ |
| S-04 | Appendix C — this SPEC.md, incl. update log | ☐ |
| S-05 | Appendix D — `docs/LLM_PROCESS.md` | ☐ |

## 4. Component specs (spec before code)
Template — copy for each component before coding it:

```
### ComponentName
- Owner (responsible for understanding it): _student_
- Tier: Core / Support / Boilerplate (sets explanation depth, STYLE.md §2)
- Purpose:
- Inputs / outputs:
- Edge cases:
- Test ideas:
- Requirements: W-xx
```

> Specs below approved by the students on 2026-11-20.

### SMHIForecastDTO
- Owner (responsible for understanding it): _student_
- Tier: Support
- Purpose: mirror the SMHI snow1g JSON exactly, so decoding is mechanical and all
  interpretation happens in `ForecastParser`.
- Inputs / outputs: raw JSON `Data` → `SMHIForecastDTO` (nested `TimeStep`, `StepData`, `Geometry`).
  Only the fields we use are declared; all others are ignored by `Decodable`.
- Edge cases: weather values are optional, because a missing key must not fail the whole
  response; `time` is required, because a step without a time is meaningless.
- Test ideas: covered through `ForecastParser` tests.
- Requirements: W-05, W-12

### Forecast (domain models: `Forecast`, `ForecastStep`, `WeatherCondition`)
- Owner (responsible for understanding it): _student_
- Tier: Support (`WeatherCondition` text/icon mapping: Boilerplate)
- Purpose: the app's own representation of a forecast, independent of the SMHI JSON.
  Views, ViewModels and the cache only ever see these types.
- Inputs / outputs: created by `ForecastParser`; `Codable` so the cache can store them (W-09).
- Edge cases: `WeatherCondition.unknown` for symbol codes outside 1–27; optional extras
  (gust, wind direction, precipitation probability, humidity) can be `nil`.
- Test ideas: `WeatherCondition(symbolCode:)` maps 1, 27 and an unknown code correctly.
- Requirements: W-06, W-07 (input for grouping), W-09, W-12

### ForecastParser
- Owner (responsible for understanding it): _student_
- Tier: Core
- Purpose: turn SMHI JSON into a `Forecast`. The only place that knows about SMHI's format.
- Inputs / outputs: `parse(_ data: Data) throws -> Forecast`. Throws `ForecastParserError`
  (`.invalidJSON`, `.noUsableTimeSteps`).
- Edge cases: invalid or non-JSON body (e.g. an HTML error page) → `.invalidJSON`;
  SMHI's missing-value marker `9999` → `nil`; a step without temperature or symbol is skipped;
  no usable steps → `.noUsableTimeSteps`; steps returned sorted by time; precipitation is the
  amount over the step's interval (1 h at first, later 3/6/12 h), so the interval start is kept.
- Test ideas: parses the real Stockholm sample (step count, first step's values, dates in UTC);
  `9999` becomes `nil`; step missing temperature is skipped; steps given in reverse order come
  back sorted; non-JSON → `.invalidJSON`; empty `timeSeries` → `.noUsableTimeSteps`.
- Requirements: W-05, W-12, W-17

> Specs below approved by the students on 2026-11-20 (session 3).

### Coordinate
- Owner (responsible for understanding it): _student_
- Tier: Support
- Purpose: a place as latitude + longitude, used by the API client, cache key and (later)
  favourites and coordinate input (W-08, W-14).
- Inputs / outputs: `Coordinate(latitude:longitude:)`; `Codable`, `Hashable`.
- Edge cases: range validation (−90…90, −180…180) belongs to coordinate input (W-14), not here.
- Test ideas: none on its own (covered through API client and cache tests).
- Requirements: W-05, W-09

### WeatherError
- Owner (responsible for understanding it): _student_
- Tier: Core (error classification)
- Purpose: the one error type the ViewModel sees. Classification of low-level failures
  (URLError, HTTP status, parser error) happens here, in pure functions with no network.
- Inputs / outputs: `URLError` → `.offline`, `.timeout`, `.cancelled` or `.network`;
  HTTP status + body → `.outsideForecastArea`, `.http(code)`; `ForecastParserError` → `.decoding`.
- Edge cases: SMHI answers 404 both for out-of-area points (plain text "Requested point is out of
  bounds") and for malformed URLs (HTML page); only the first is `.outsideForecastArea`.
  `.cancelled` is not shown to the user (a newer search replaced the request).
- Test ideas: URLError `.notConnectedToInternet` → `.offline`; `.timedOut` → `.timeout`;
  404 "out of bounds" → `.outsideForecastArea`; 404 HTML → `.http(404)`; 500 → `.http(500)`.
- Requirements: W-10, W-16, W-17

### SMHIAPIClient (protocol `WeatherAPIClient`, plus `APIEnvironment`)
- Owner (responsible for understanding it): _student_
- Tier: Support
- Purpose: build the SMHI URL and download the raw JSON. Knows nothing about parsing or caching.
- Inputs / outputs: `fetchForecastData(for: Coordinate) async throws(WeatherError) -> Data`.
  Base URL lives only in `APIEnvironment` (one-line switch, W-19).
- Edge cases: coordinates formatted with at most 6 decimals and always a decimal point
  (SMHI returns 404 for 7+ decimals or `18,07`, which a Swedish-locale formatter would produce);
  request timeout 15 s instead of the default 60 s; non-2xx status → classified by `WeatherError`.
- Test ideas: URL for (59.3293, 18.0686) is `…/lon/18.0686/lat/59.3293/data.json`;
  long decimals are rounded to 6.
- Requirements: W-05, W-15, W-16, W-19

### CacheStore (protocol) + UserDefaultsCacheStore
- Owner (responsible for understanding it): _student_
- Tier: Support
- Purpose: remember the last successful forecast per place, so there is something to show offline.
- Inputs / outputs: `save(_ cached: CachedForecast, for: Coordinate)`,
  `load(for: Coordinate) -> CachedForecast?`. `CachedForecast` = `Forecast` + `fetchedAt: Date`.
  Stored as JSON (`Codable`) in an injected `UserDefaults`.
- Edge cases: key uses coordinates rounded to 2 decimals (~1 km), so the same city found twice
  with slightly different coordinates shares one entry; corrupt or old-format data → `nil`
  (treated as "no cache"), never a crash; a failed save does not fail the fetch.
- Test ideas: save then load returns the same value; load for an unknown place → `nil`;
  corrupt data → `nil`. (Run against a throwaway `UserDefaults(suiteName:)`.)
- Requirements: W-09, W-10

### WeatherRepository
- Owner (responsible for understanding it): _student_
- Tier: Core
- Purpose: the ViewModel's single entry point for forecasts: fetch → parse → cache → fallback.
- Inputs / outputs: `forecast(for: Coordinate) async throws(WeatherError) -> ForecastResult`.
  `ForecastResult` = `forecast`, `fetchedAt`, `staleReason: WeatherError?` (`nil` = fresh from
  the network; set = cached data shown because of that error).
  Dependencies injected: `WeatherAPIClient`, `ForecastParser`, `CacheStore`, clock (`now`).
- Edge cases: any failure (offline, timeout, HTTP, decoding) falls back to the cache if one
  exists, otherwise the error is thrown; parse errors never overwrite a good cache;
  `@concurrent` so parsing runs off the main thread (W-15).
- Test ideas (fake API client + fake cache): success → fresh result and cache saved;
  offline with cache → cached result with `staleReason == .offline`; offline without cache →
  throws `.offline`; invalid JSON with cache → cached result, cache not overwritten;
  `.outsideForecastArea` without cache → throws `.outsideForecastArea`;
  HTTP 500 with cache → cached result with `staleReason == .http(500)`.
- Requirements: W-05, W-09, W-10, W-15, W-16, W-17

> Specs below approved by the students on 2026-11-22 (session 4).

### DailyForecast + GroupedForecast (models)
- Owner (responsible for understanding it): _student_
- Tier: Support
- Purpose: the shapes the screens need. `GroupedForecast` = `current: ForecastStep?`,
  `today: [ForecastStep]` (hourly), `days: [DailyForecast]` (the next 7 days after today).
  `DailyForecast` = `date` (local midnight), `minTemperature`, `maxTemperature`, `condition`,
  `precipitation: Double?` (mm), `maxWindSpeed: Double?`, `steps: [ForecastStep]` (for the detail
  screen, W-02).
- Inputs / outputs: created by `ForecastGrouper`; not cached (they depend on "now").
- Edge cases: `precipitation` / `maxWindSpeed` are `nil` when no step has a value.
- Test ideas: covered through `ForecastGrouper` tests.
- Requirements: W-01, W-02, W-06, W-07

### ForecastGrouper
- Owner (responsible for understanding it): _student_
- Tier: Core (data transformation)
- Purpose: turn a `Forecast` (UTC steps) into "current + hourly today + daily for the next 7 days",
  using calendar days in the user's time zone.
- Inputs / outputs: `ForecastGrouper(calendar:)`, `group(_ forecast: Forecast, now: Date) -> GroupedForecast`.
  The calendar (with the device's time zone) and `now` are injected so tests are repeatable.
- Rules: steps before the start of the current hour are ignored (old cached data);
  `current` = first remaining step; `today` = remaining steps on today's local date;
  `days` = tomorrow + 6 more days, days without steps skipped; min/max over the day's steps;
  `condition` = the step closest to 12:00 local time; precipitation is summed per day by the
  midpoint of each step's interval (a 13:00→01:00 step counts for the day it mostly covers).
- Edge cases: SMHI times are UTC, so 23:00Z is already the next day in Sweden; daylight-saving
  days have 23 or 25 hours (handled by `Calendar`, not by adding 24 h); later days have only
  2–4 steps, so min/max is coarse; late evening `today` can be empty; a cached forecast from
  days ago can have no steps left for today.
- Test ideas: a step at 23:00 UTC lands on the next local day; `today` holds only steps from the
  current hour to local midnight; daily min/max; condition taken from the step nearest 12:00;
  a 12 h step crossing midnight adds its precipitation to the earlier day; at most 7 days, empty
  days skipped; steps in the past (old cache) are ignored and `current` is the first remaining step;
  a daylight-saving day (25 Oct 2026, 25 hours) is grouped correctly.
- Requirements: W-01, W-06, W-07, W-17

> Specs below approved by the students on 2026-11-22 (session 4).

### CoordinateInput (validation)
- Owner (responsible for understanding it): _student_
- Tier: Core (coordinate validation)
- Purpose: turn the two text fields into a `Coordinate`, or explain what is wrong.
- Inputs / outputs: `CoordinateInput.validate(latitude: String, longitude: String)
  -> Result<Coordinate, CoordinateInputError>`; errors: `.notANumber(field)`, `.outOfRange(field)`.
- Edge cases: decimal comma accepted (`59,33`, what a Swedish keyboard types); spaces trimmed;
  empty text, `abc`, `nan`, `inf` rejected; latitude must be −90…90, longitude −180…180;
  points outside SMHI's area are valid input (SMHI answers "outside forecast area").
- Test ideas: `59.33`/`18.07` valid; `59,33` valid; `abc` → notANumber; empty → notANumber;
  `nan` → notANumber; latitude `91` → outOfRange; longitude `-181` → outOfRange.
- Requirements: W-01, W-14, W-17

### SearchViewModel
- Owner (responsible for understanding it): _student_
- Tier: Core (ViewModel state machine incl. race-condition guard)
- Purpose: owns the search screen's state and talks to the repository. Does not navigate.
- Inputs / outputs: `latitudeText`, `longitudeText`, `search()`, `refresh()`;
  `state: LoadState` = `.idle` · `.loading` · `.loaded(ForecastDisplay)` · `.failed(message)`;
  `ForecastDisplay` = `GroupedForecast` + `fetchedAt` + optional stale banner text.
  `@Observable` + `@MainActor`; repository, grouper and clock injected.
- Edge cases: invalid input → message, no request; a new search clears the old place's data
  (`.loading`, never another place's forecast under the new name); two quick searches → the
  older request is cancelled and its result ignored even if it arrives last (request ID check);
  `.cancelled` is never shown; cached data shows a banner ("Offline – showing data from 14:15").
- Test ideas (real repository with `FakeAPIClient` + `FakeCacheStore`): success → `.loaded`; offline with cache → `.loaded` with banner;
  offline without cache → `.failed` with the offline message; invalid input → no repository call;
  slow first search finishing after a second search does not overwrite the second result.
- Requirements: W-01, W-10, W-14, W-15, W-16, W-17

### SearchView + WeatherCondition display (SwiftUI)
- Owner (responsible for understanding it): _student_
- Tier: Boilerplate
- Purpose: the first screen: latitude/longitude fields + search button; idle hint, loading
  spinner, error with retry, stale banner; "Now" header, "Today" hourly row, "Next 7 days"
  scrollable list (W-13). `WeatherCondition` → SF Symbol + English text.
- Inputs / outputs: reads `SearchViewModel.state`, calls `search()` / `refresh()`
  (pull to refresh). App entry point builds the repository and ViewModel.
- Edge cases: empty "Today" section late in the evening ("No more hours today");
  layout works in portrait and landscape (W-11 checked later on iPad too).
- Test ideas: none automated now (UX scenarios go to TEST_REPORT, W-18).
- Requirements: W-01, W-06, W-10, W-13, W-16

> Specs below approved by the students on 2026-11-22 (session 5).

### Secrets (API key loading)
- Owner (responsible for understanding it): _student_
- Tier: Support
- Purpose: read the geocode.maps.co key from `WeatherApp/Secrets.plist` (gitignored; copied into
  the app automatically by the synced folder, no `project.pbxproj` edit). A committed
  `Secrets.example.plist` at the repo root shows the partner what to create.
- Inputs / outputs: `Secrets.geocodeMapsAPIKey(in: Bundle) -> String?`.
- Edge cases: file missing, key empty, or still the placeholder → `nil` (place search shows
  "not set up"; coordinate search keeps working). The key is inside the built app, so it is
  hidden from git but not secret from someone with the app; fine for a free lab key.
- Test ideas: none (needs a bundle; verified by running the app).
- Requirements: W-08

### MapsCoPlaceDTO + Place (model)
- Owner (responsible for understanding it): _student_
- Tier: Support
- Purpose: `MapsCoPlaceDTO` mirrors one item of the JSON array (`lat`, `lon` — strings —,
  `display_name`; other fields ignored). `Place` = `name` ("Stockholm"), `detail`
  ("Stockholms kommun, Stockholm County, Sweden"), `coordinate`. `Codable`/`Hashable` for
  favourites later (W-03).
- Edge cases: fields we don't decode (e.g. `osm_id`, documented as a string, elsewhere a number)
  can't break decoding.
- Test ideas: covered through `GeocodingParser` tests.
- Requirements: W-08

### GeocodingParser
- Owner (responsible for understanding it): _student_
- Tier: Core (JSON → domain model)
- Purpose: turn the geocode.maps.co JSON array into `[Place]`.
- Inputs / outputs: `parse(_ data: Data) throws(GeocodingParserError) -> [Place]`; error `.invalidJSON`.
- Edge cases: `[]` → empty list (not an error); `lat`/`lon` that aren't numbers or are out of
  range → that item skipped; `display_name` split at the first comma into name + detail;
  duplicates removed: two entries count as the same when their full text (name + detail) is
  identical, because the user can't tell such rows apart (the real "Paris" answer has two
  "Paris, Île-de-France, France" entries ~2 km apart — changed 2026-11-22, was "same name
  within ~1 km"); order from the API kept, the first of each duplicate wins.
- Test ideas: real "Stockholm" response (count, first place's name/detail/coordinate);
  `[]` → empty; item with `lat: "abc"` skipped; HTML error page → `.invalidJSON`;
  two Paris entries with identical text but different coordinates → one result.
- Requirements: W-08, W-12, W-17

### GeocodingClient (protocol) + MapsCoGeocodingClient, PlaceRepository
- Owner (responsible for understanding it): _student_
- Tier: Support
- Purpose: download place matches (client) and turn them into `[Place]` (repository:
  client → parser, no cache). Base URL in `APIEnvironment`.
- Inputs / outputs: `searchData(for query: String) async throws(WeatherError) -> Data`;
  `PlaceRepository.search(_ query:) async throws(WeatherError) -> [Place]` (`@concurrent`).
- Edge cases: query encoded with `URLComponents` ("Malmö", "Åre", spaces); `limit=10`;
  missing key → `.apiKeyMissing` without any request; same 15 s timeout and URLError
  classification as SMHI.
- Test ideas: none new now (the URL encoding can be checked later if wanted).
- Requirements: W-08, W-15, W-16

### WeatherError (new cases)
- Tier: Core (error classification)
- New cases: `.apiKeyMissing` (no usable key, found before any request), `.apiKeyRejected`
  (HTTP 401/403), `.rateLimited` (HTTP 429). `fromHTTP` maps those codes for both APIs.
- Test ideas: 401 → `.apiKeyRejected`; 429 → `.rateLimited`.
- Requirements: W-16, W-17

### SearchViewModel + SearchView (place mode)
- Tier: Core (ViewModel state) / Boilerplate (view)
- Purpose: `inputMode` = `.place` (default) / `.coordinates` (segmented picker). Place mode: one
  text field → `searchPlaces()` → `placeSearch` = `.idle` · `.searching` · `.results([Place])` ·
  `.noResults` · `.failed(message)`; tapping a place → `select(_ place:)` → forecast for its
  coordinate (same path as coordinate search). Forecast header shows the place name, or the
  coordinates in coordinate mode.
- Edge cases: empty query → message, no request; no results → "No places found for …";
  Paris → selectable, then SMHI's "outside the forecast area" message; missing key → message
  pointing to Secrets.plist, coordinate mode still works; offline / rate limited → message;
  a second place search cancels the first (same request-ID guard).
- Test ideas: (decided in step 2).
- Requirements: W-01, W-08, W-14, W-16

> Spec below (UI polish, branch `feature/ui-polish`) approved by the students on 2026-11-23.

### WeatherTheme + hero block (UI polish)
- Owner (responsible for understanding it): _student_
- Tier: Boilerplate
- Purpose: make the forecast screen show the weather at a glance. `WeatherTheme` (sunny, cloudy,
  rain, snow, storm) gives one background gradient per kind of weather; `WeatherCondition.theme`
  maps SMHI's 27 conditions to it. `CurrentConditionsView` becomes a centred hero block (place name,
  symbol, large temperature, condition, high/low, wind). Forecast rows sit on `.ultraThinMaterial`.
- Inputs / outputs: `WeatherCondition.theme -> WeatherTheme`; `WeatherTheme.gradient -> LinearGradient`.
  `SearchView` picks the theme from the current step (else the first day) and applies it only when
  a forecast is loaded.
- Edge cases: no theme (idle, loading, error) → normal system background and the user's light/dark
  setting; with a theme the screen uses the dark colour scheme so text stays white on the gradient;
  `.unknown` condition → cloudy theme; Dynamic Type: the large temperature uses `@ScaledMetric`;
  the "High/Low" values only cover the hours left today (that is what `today` holds).
- Test ideas: none automated (UX scenarios go to TEST_REPORT, W-18). `WeatherCondition.symbolColor`
  is removed: symbols use `.multicolor`, which is readable now that the background is dark.
- Requirements: W-01, W-06, H-02

> Spec below (step 5, branch `feature/ui-polish`) approved by the students on 2026-11-23.

### StartView + designed states (UI polish)
- Owner (responsible for understanding it): _student_
- Tier: Boilerplate
- Purpose: a designed first screen and designed loading/error states (H-02). When nothing is loaded
  (`.idle`) the screen shows a night-sky gradient, a large animated symbol, a short friendly headline
  and a hint that depends on the input mode. `.loading` shows a redacted skeleton of the forecast
  instead of a spinner row; `.failed` shows a `ContentUnavailableView` with the message and
  "Try again". Place search results ("Choose a place") are unchanged.
- Inputs / outputs: `StartView(hint:)` only draws; no ViewModel, repository or test changes.
- Edge cases: the idle gradient adds a new `WeatherTheme.night`, so the screen keeps the dark colour
  scheme and nothing flashes grey → colour; loading and error use the night sky too, so a failed
  search never shows the previous place's weather colours; `symbolEffect` is off when Reduce Motion
  is on; skeleton rows are hidden from VoiceOver and the loading state announces "Loading forecast".
- Test ideas: none automated (UX scenarios go to TEST_REPORT, W-18). Not done here: one-tap
  quick-pick places (tried and removed on 2026-11-23, students' choice) and reopening on the last
  searched place (touches ViewModel + persistence, belongs with favourites, W-03).
- Requirements: W-01, W-10, W-16, H-02

> Specs below approved by the students on 2026-11-23 (session 7, branch `feature/final-screens`).

### DayDetailView (detail screen)
- Owner (responsible for understanding it): _student_
- Tier: Boilerplate (view) — navigation in the View layer
- Purpose: tapping a day in "Next 7 days" opens its full forecast (W-02): header with weekday and
  date, symbol, condition, min/max, total precipitation, strongest wind; then one row per forecast
  step with time span, symbol, temperature, wind speed + compass direction, gust, precipitation,
  precipitation chance and humidity. Same weather background and frosted rows as the main screen.
- Inputs / outputs: `DayDetailView(day: DailyForecast)`; opened with `NavigationLink(value:)` +
  `.navigationDestination(for: DailyForecast.self)` in `SearchView`. No ViewModel: it only shows a
  day that is already loaded and has no state or actions. `ForecastStep` and `DailyForecast` become
  `Hashable` (needed by value-based navigation).
- Edge cases: later days have 2–4 steps 6–12 h apart, so each row shows its span ("07:00–13:00")
  instead of one time, so an amount is not read as one hour's rain; missing values (`nil`) are left
  out, not shown as 0; today is not opened here (it is shown hour by hour on the main screen).
- Test ideas: none automated for the view (UX scenarios go to TEST_REPORT, W-18).
- Requirements: W-02, W-06, H-02

### CompassDirection
- Owner (responsible for understanding it): _student_
- Tier: Support
- Purpose: turn SMHI's wind direction in degrees (the direction the wind comes from) into one of
  8 compass points for the detail screen: N, NE, E, SE, S, SW, W, NW.
- Inputs / outputs: `CompassDirection.abbreviation(forDegrees:) -> String`.
- Edge cases: each point covers 45°, centred on it (N = 337.5°–22.5°), so 359° is N; values below 0
  or 360 and above are wrapped first.
- Test ideas: 0° → N; 90° → E; 225° → SW; 359° → N; boundary between two points:
  22.4° → N and 22.5° → NE.
- Requirements: W-02

> Specs below approved by the students on 2026-11-23 (W-03, branch `feature/W-03-favourites`).

### FavoritesStore (protocol) + UserDefaultsFavoritesStore
- Owner (responsible for understanding it): _student_
- Tier: Support
- Purpose: keep the user's favourite places between app launches (W-03).
- Inputs / outputs: `load() -> [Place]`, `save(_ places: [Place])`. Stored as one JSON array
  (`Codable`) in an injected `UserDefaults`, in the order the user added them.
- Edge cases: nothing saved yet or corrupt / old-format data → empty list, never a crash;
  a failed save is ignored (the list stays correct in memory for this session).
- Test ideas (throwaway `UserDefaults(suiteName:)`): save then load gives the same places in the
  same order; corrupt data → empty list.
- Requirements: W-03

### FavoritesViewModel
- Owner (responsible for understanding it): _student_
- Tier: Core (state)
- Purpose: the favourites list and its actions, separate from `SearchViewModel` (decision 1).
- Inputs / outputs: `favorites: [Place]`, `isFavorite(_:)`, `toggle(_:)`, `remove(at:)`,
  `lastKnownTemperature(for:)`; `@Observable` + `@MainActor`; store and `WeatherRepository` injected
  (the temperature is read through the repository's new `cachedForecast(for:)`, never straight from
  the cache, so the layer rule holds). Every change is saved straight away.
- Edge cases: "same place" = coordinates equal when rounded to 2 decimals (~1 km), the same rule as
  the forecast cache, so adding a place twice keeps one entry (decision 4); coordinate searches can
  be favourites, named "59.33, 18.07" (decision 3).
- Test ideas (fake store): `toggle` adds, a second `toggle` removes; adding the same place twice
  gives one entry; `isFavorite` is true for a place ~500 m from a saved one; `remove(at:)` removes
  the right place and the store is saved.
- Requirements: W-03, W-17

### SearchViewModel (current place) + FavoritesView + star button
- Tier: Core (`currentPlace`) / Boilerplate (views)
- Purpose: `SearchViewModel.currentPlace` is the place whose forecast is shown (from a place search,
  or a `Place` named by its coordinates). A star next to the place name toggles it. A toolbar button
  opens `FavoritesView` as a sheet (decision 2): name, region and the last known temperature from the
  forecast cache, if any (decision 5); tap → sheet closes and the forecast loads; swipe to delete.
- Edge cases: no star unless a forecast is shown (so Paris can't be added); empty list →
  "No favourites yet. Tap ★ on a forecast to add one."; opening a favourite offline shows cached data
  with the banner; reopening the last place at launch is not part of this (decision 6).
- Test ideas: none automated for the views (UX scenarios go to TEST_REPORT, W-18).
- Requirements: W-03, W-09, W-10

> Spec below approved by Hugo on 2026-11-24 (branch `feature/hugo-final`); Thrainn to review.
> Choices: light day variant (not the "dark everywhere" fallback); loading and error follow the start screen's sky.

### Day/night sky (time-dependent start screen)
- Owner (responsible for understanding it): Hugo
- Tier: Boilerplate (colours, views) · Support (the day-or-night rule and its refresh)
- Purpose: the start screen follows the time of day: a light day sky between 06:00 and 18:00, the
  current night sky otherwise (H-02). A sky is a `WeatherTheme`, so the gradient and the colour
  scheme come from one value and can't disagree.
- Inputs / outputs:
  - `WeatherTheme.day` (new case, light blue gradient) and `WeatherTheme.colorScheme: ColorScheme`
    (`.light` for `.day`, `.dark` for every other theme).
  - `WeatherTheme.sky(at date: Date, calendar: Calendar = .current) -> WeatherTheme`: `.day` if the
    local hour is 6…17, else `.night`. Pure function with the date and calendar injected (like
    `ForecastGrouper`), so a test can pass any time.
  - `SearchView` holds `@State sky` (the day or night `WeatherTheme`); `theme` returns the sky for every state without a
    forecast (idle, loading, failed) and the weather's theme once loaded; the fixed
    `.preferredColorScheme(.dark)` becomes `.preferredColorScheme(theme.colorScheme)`.
  - `StartView` gets the sky as a parameter: sun symbol (`sun.max.fill`) by day, moon by night.
  - `FavoritesView` gets the sky as a parameter, sets its own `.preferredColorScheme` and uses the
    sky gradient instead of the fixed `.night` one (see edge cases).
- How day and night are decided: the device's local hour from `Calendar.current`, so it follows the
  phone's time zone. Not sunrise/sunset: `ForecastStep` has no sun data, and no place is chosen yet
  on the start screen. Known limit: at Nordic latitudes real daylight differs a lot from 06–18
  (Kiruna: dark all day in December, sun at midnight in June). Accepted for a start screen.
- How it updates while the app is open: one task on the screen,
  `.task(id: scenePhase)`. When the scene becomes `.active` the task runs, sets `sky`
  straight away, then repeats every 60 s with `Task.sleep`; when the app goes to the background the
  task is cancelled and stops. Coming back to the app therefore corrects the sky at once, and an app
  left open shifts within a minute of 06:00 / 18:00. `sky` is only written when the value
  changes (SwiftUI does not compare, so a write every minute would redraw every minute). The
  existing `.id(theme)` + `.transition(.opacity)` + `.animation(.smooth, value: theme)` cross-fades
  the gradient. Alternatives not chosen: `TimelineView` with a schedule for the exact 06:00 / 18:00
  moments (exact, but it must wrap every view that reads the time and is harder to explain);
  `Timer.publish` + `.onReceive` (works, but adds Combine to an async/await-only codebase).
- How it works with `.preferredColorScheme(.dark)` (changes decision "App always uses the dark
  colour scheme", 2026-11-23, which is replaced if this is approved):
  - A light sky needs dark text, so the day sky can't live under a forced dark scheme. The scheme
    now follows the theme: `.light` only for `.day`, `.dark` for the night sky and for all weather
    themes, whose gradients are unchanged (still tuned for white text).
  - Text (`.primary` / `.secondary`) and the frosted rows adapt by themselves, so no view needs
    hard-coded colours. Nav bar, status bar and the keyboard follow the scheme.
  - Cost: during the day the scheme flips light → dark when a forecast arrives (new search from the
    start screen) and back to light when the user returns to the start screen. The gradient
    cross-fades but the system's scheme change is a short, separate fade; check on a device how
    it looks. If it looks bad, fallback (one-line change): keep `.dark` everywhere and make `.day`
    a bright blue that still holds 4.5:1 for white text (hardly lighter than `.sunny`).
- Edge cases:
  - Loading and error screens use the same sky as the start screen. Otherwise a daytime search
    would go light → night-dark → weather colours.
  - `FavoritesView` is a sheet that inherits the scheme. With a fixed night gradient it would show
    dark text on a dark gradient in daytime, so it takes the sky and sets its own scheme. (Check
    on a device that a sheet honours its own `.preferredColorScheme`.)
  - A forecast on screen is not affected when 06:00 / 18:00 passes; its weather theme stays.
  - Time zone or clock change (travel, manual change): the next tick (≤ 60 s) corrects it.
  - Reduce Motion: the gradient is a cross-fade, which is allowed; the symbol pulse is off as today.
    The brightness jump at the exact shift is softened by the cross-fade, not removed.
  - Contrast: day gradient and `.secondary` text on the frosted rows must be checked by eye
    (also with Increase Contrast); the values in `WeatherTheme` are estimates.
  - Previews and screenshots at different hours need the sky injected (a parameter), not the real clock.
- Test ideas (approved by Hugo 2026-11-24, in `WeatherThemeTests`): `sky(at:)` for 05:59 → night,
  06:00 → day, 17:59 → day, 18:00 → night, 00:00 → night; the same instant gives different
  answers with a UTC and a Stockholm calendar (the calendar is really used); `colorScheme` is
  `.light` only for `.day`. The views have no automated tests (UX scenarios go to TEST_REPORT, W-18).
- Decision log entry to add if approved: "2026-11-24 — Start/loading/error sky follows the time of
  day; the colour scheme follows the theme (replaces 'app always dark')".
- Requirements: H-02, W-06

> Spec below approved by Hugo on 2026-11-24 (branch `feature/hugo-final`); Thrainn to review.
> Choices: `.storm` = denser rain, no lightning; the still frame under Reduce Motion is judged in the
> simulator; step 6's small items are a separate step after the background.

### Animated weather background (UI polish step 6)
- Owner (responsible for understanding it): Hugo
- Tier: Boilerplate (drawing) · Support (layer data, motion maths, pause rules)
- Purpose: show the weather behind the text, not only as a gradient: drifting clouds (cloudy), falling
  rain (rain), falling snow (snow), a faint sun glow (sunny), stars (night). SwiftUI only
  (`TimelineView`, `Canvas`, SF Symbols), no packages (H-02, W-06).
- Design rules (from Emil's and Apple's motion rules): it is ambient, so slow, low contrast and never
  on the text; constant motion is linear; nothing pops in (elements enter from outside the screen,
  stars never go to 0 opacity); no blur (expensive); no flashes, so no lightning for `.storm`.
- How it connects to `WeatherTheme` (data in the theme, drawing in the view):
  - `WeatherLayer` (new enum, plain data, `Equatable, Sendable`): `.sunGlow`, `.clouds(count:)`,
    `.rain(count:)`, `.snow(count:)`, `.stars(count:)`. Each has a `minimumInterval` (seconds between
    frames). A layer carries no colours or sizes; the view decides how it looks.
  - `WeatherTheme.layers: [WeatherLayer]` and `WeatherTheme.frameInterval: Double` (the smallest
    `minimumInterval` of its layers). `gradient` and `colorScheme` stay as they are.
  - Proposed mapping (counts are starting values, tuned on a device):

    | Theme | Layers | Frame interval |
    |---|---|---|
    | `.day` (light) | sun glow, 2 white clouds | 1/20 s |
    | `.night` | 55 stars (slow twinkle) | 1/10 s |
    | `.sunny` | sun glow, 1 cloud | 1/20 s |
    | `.cloudy` | 4 clouds | 1/20 s |
    | `.rain` | 2 clouds, 40 rain streaks | 1/30 s |
    | `.snow` | 2 clouds, 36 snowflakes | 1/30 s |
    | `.storm` | 3 clouds, 70 rain streaks (no lightning) | 1/30 s |

  - `.day` is the only light theme, so its clouds are white with some opacity on the pale blue
    gradient and its glow is warm; the dark themes use white at low opacity. The layer colours are
    chosen in the view from `theme.colorScheme`, not stored in the theme.
- Inputs / outputs:
  - `WeatherBackground(theme: WeatherTheme, isAnimated: Bool = true, isPaused: Bool = false)` (new view, replaces
    `theme.gradient.ignoresSafeArea()...`): the gradient plus one `TimelineView(.animation(minimumInterval:
    theme.frameInterval, paused:))` that draws one `Canvas`. Clouds are the SF Symbol `cloud.fill`,
    passed to `Canvas` as a symbol so it is resolved once, not every frame.
  - Every element is a pure function of time, a seed and the canvas size (for example
    `y = (startY + speed · t) mod (height + margin)`); there is no per-frame state. A seeded generator
    gives each element its fixed start position, speed and phase, so rotation, iPad resizing and
    returning from the background need no special code. Wrapping lives in a pure helper.
  - Also new: `WeatherParticle` (the fixed start values of one element, made from a seed, with a pool
    per layer kind from which a layer takes its first `count`), `WeatherMotion` (wrapping and
    position, pure), `SeededGenerator` (a small repeatable random generator), and
    `WeatherLayerRenderer` (the `Canvas` drawing, `nonisolated`, so the `Canvas` closure has no actor
    isolation to cross). All in `Views/`, next to `WeatherTheme`.
  - `SearchView` uses `WeatherBackground(theme: theme)`; the existing `.id(theme)` +
    `.transition(.opacity)` + `.animation(.smooth, value: theme)` cross-fades gradient and layers
    together. `DayDetailView` and `FavoritesView` use `isAnimated: false` (gradient only), so only one
    animated background exists and the secondary screens stay calm.
- Reduce Motion and battery (the background pauses, and a paused `TimelineView` draws one still frame):
  - Reduce Motion on (`accessibilityReduceMotion`) → paused: a still frame of the same layers; the
    theme cross-fade stays (it is opacity only).
  - Low Power Mode on → paused, the same still frame. Read with `ProcessInfo.isLowPowerModeEnabled`
    and updated from `NSProcessInfoPowerStateDidChange` (a `.task` over `NotificationCenter.notifications`).
  - App not `.active` (`scenePhase`) → paused.
  - Who decides (changed 2026-11-24 after the performance review): `SearchView` decides, once, from
    Reduce Motion, Low Power Mode, `scenePhase` and whether something covers it, and hands the result
    to `WeatherBackground(isPaused:)`. `WeatherBackground` itself holds no state, no environment reads
    and no task, so the gradient-only backgrounds (day detail, favourites sheet) cost nothing extra and
    there is one Low Power Mode listener in the app, not one per background.
  - Frame rate is capped per theme (table above): a slow cloud needs 20 fps, not 60; stars 10 fps.
  - Budget: at most 80 moving elements per theme; one `Canvas` pass; no blur, no per-frame view updates.
  - Covered → paused: while the favourites sheet is open or a day detail is pushed, the main
    background is paused. `SearchView` knows both: `showingFavorites`, and a `NavigationStack(path:)`
    it owns (`[DailyForecast]`), which is not empty while a detail is shown. To be confirmed with the
    CPU gauge on a device. Acceptance: Xcode's Energy Impact stays "Low" on a real device after a few
    minutes on each theme. The Simulator is not representative for this.
- Edge cases: the text stays readable (cloud opacity ≤ about 0.15 on dark themes, rain streak ≤ 0.3,
  checked by eye, also with Increase Contrast; the hero block sits directly on the background, so it
  is the place to check); rows are frosted material, which also softens what moves behind them;
  `allowsHitTesting(false)` and `accessibilityHidden(true)` on the background; a theme change mid-flight
  starts the new layers at whatever phase the shared clock gives; Reduce Motion or Low Power Mode
  switched on while the screen is open pauses immediately; large `Date` values are fine in `Double`.
- Test ideas (approved by Hugo 2026-11-24, in `WeatherLayerTests` and `WeatherMotionTests`): `WeatherTheme.layers` mapping
  (rain has rain, night has stars, cloudy has clouds, day and sunny have the sun glow, storm has no
  flash layer); budget (every theme ≤ 80 elements, no `frameInterval` below 1/30 s, i.e. never more
  than 30 fps); the wrapping helper (an element that has fallen one full cycle is back at the top and
  never ends up outside the margin); the seeded generator gives the same positions for the same seed.
  The views have no automated tests (UX scenarios go to TEST_REPORT, W-18).
- Maybe later: a "Animated background" switch on the settings screen (W-04).
- Requirements: H-02, W-06

> Step 6, small items (approved by Hugo 2026-11-24 as a separate step after the background):
> `.contentTransition(.numericText())` on the hero temperature; `.symbolEffect(.bounce)` and
> `.sensoryFeedback(.selection)` when the favourite star is toggled; `.sensoryFeedback(.error)` when a
> search fails. Not proposed: a success haptic on every loaded forecast (over-feedback; Apple's rule
> is to keep haptics for meaningful moments).

> Spec below approved by Hugo on 2026-11-24 (W-04 settings, branch `feature/W-04-settings`); Thrainn to review.
> Choices: 1 hour as the default refresh; the "Updated" text is enough to show the age of a reused forecast.

### Settings screen (W-04)
- Owner (responsible for understanding it): Hugo
- Tier: Core (the "reuse a fresh saved forecast" rule in `WeatherRepository`, and how `SearchViewModel`
  uses it) · Support (`RefreshPolicy`, `SettingsViewModel`, `CacheStore.removeAll`) · Boilerplate
  (`SettingsView`, the gear button, the "Updated" text)
- Purpose: let the user choose how often the app asks SMHI for new data, and a few UI preferences.
  Three settings, no unit switching (°C/°F, m/s) — decided by the students on 2026-11-24 because
  `TemperatureText` is used in nearly every view and the switch would touch them all.
- **How we read "data refresh rate" (decision, with reasons).** We read it as *how old a saved forecast
  may be before the app fetches a new one* ("cache age"), not as an automatic reload on a timer.
  - Why cache age: (1) SMHI renews its forecast about once an hour, and its answers say so
    (`cache-control: max-age=3600`), so asking more often returns the same data; (2) it saves network
    use and battery, which we have just worked to reduce (the performance review of the animated
    background); (3) it works offline and with the existing fallback (W-09, W-10); (4) the decision log
    already says "a 'use cache if fresh' rule comes with the refresh-rate setting (W-04)", and today the
    repository always tries the network first; (5) a user always keeps full control, because pull to
    refresh and "Try again" always fetch new data.
  - Not chosen: a timer that reloads while the app is open. It costs battery, needs a task to manage
    (cancel, pause in the background, avoid doubles), and the data it fetches would normally be
    unchanged.
- The three settings:
  1. **Refresh forecast** (`RefreshPolicy`): Always · 15 min · 1 hour (default) · 3 hours. A saved
     forecast younger than this is shown without contacting SMHI. "Always" is today's behaviour.
     On screen it is worded "Reuse saved forecast for": Never · 15 minutes · 1 hour · 3 hours, because
     "refresh every hour" would sound like a timer (changed when the screen was built, 2026-11-24).
  2. **Animated background**: on (default) / off. Off draws the gradient only (no layers, no timeline).
     It is separate from Reduce Motion and Low Power Mode, which still pause the layers when it is on.
  3. **Clear saved forecasts**: removes the forecasts saved for offline use, after a confirmation.
- Inputs / outputs:
  - `RefreshPolicy` (new enum, `Int` raw values so `@AppStorage` can store it): `maxCacheAge: TimeInterval`
    (0, 900, 3600, 10800 s); `RefreshPolicy.key`; `RefreshPolicy.stored(in:)` (reads `UserDefaults`, the
    default argument is `.standard` so a test can pass its own; a missing or unknown value gives
    `.hour1`; a missing value is not read as `0`, which would mean "Always").
  - `WeatherRepository.forecast(for:reusingCacheYoungerThan:)` (the new parameter is `TimeInterval?`,
    `nil` = never reuse, i.e. always fetch). If a saved forecast exists and `now − fetchedAt` is below
    the limit, it is returned at once as `ForecastResult(forecast, fetchedAt: <its original time>,
    staleReason: nil)`, with no request and no new save. Otherwise as today: fetch, parse, save, and on
    failure fall back to the saved forecast with `staleReason`.
  - `SearchViewModel` gets `refreshPolicy: () -> RefreshPolicy` (injected, default
    `RefreshPolicy.stored()`, the same way `now` is injected). Choosing a place, a coordinate search and
    opening a favourite pass `refreshPolicy().maxCacheAge`; pull to refresh and "Try again" pass `nil`.
  - `CacheStore.removeAll()` (new protocol method) and `UserDefaultsCacheStore.removeAll()`: removes
    only the keys that start with `forecast.`, so favourites and settings are kept.
    `WeatherRepository.clearSavedForecasts()` forwards it.
  - `SettingsViewModel` (new, `@Observable` + `@MainActor`, repository injected): `clearSavedForecasts()`.
    The "cleared" text is `@State` in the view (changed when built, 2026-11-24): a flag in the ViewModel
    would live as long as the app and show the text the next time the sheet opens. The View never
    touches the repository.
  - `SettingsView(sky:)`: a sheet like `FavoritesView` (`NavigationStack`, `Form`, "Done", the sky
    gradient, its own colour scheme from `sky`). The refresh picker and the animation switch use
    `@AppStorage` (decision log: "Settings stored with `@AppStorage`"), with `RefreshPolicy.key` shared
    with the ViewModel's default. Opened with a gear button (`gearshape`) in the toolbar next to the
    favourites button. `SearchView` reads `@AppStorage("animatedBackground")` for `isAnimated`.
- **"Updated" text:** below the weather summary in the hero block: "Updated 14:15" (`fetchedAt`,
  short time), caption size, secondary colour. Shown for every loaded forecast whose `staleMessage` is
  `nil`; when the offline banner is shown it already says "showing data from 14:15", so no second
  line. A reused saved forecast shows its original time, so it is clear why nothing changed. Part of
  the hero's combined VoiceOver text.
- **What happens to the favourites' last known temperature when the forecasts are cleared:**
  - The favourites list itself is unchanged: it is stored separately (`UserDefaultsFavoritesStore`).
  - `FavoritesViewModel.lastKnownTemperature` reads the saved forecast, which is gone, so it returns
    `nil` and the row simply shows no temperature (the view already hides the number when it is `nil`).
    No placeholder, no error.
  - A temperature comes back for a place the next time that place is loaded (every successful load
    saves again): open the favourite, or search for it.
  - `FavoritesView` reads the cache when it is drawn, and Settings and Favourites are separate sheets,
    so the list is always drawn after the clearing; no refresh signal is needed.
  - The confirmation text says so: "Saved forecasts are used when you are offline. Favourites are
    kept. Offline, a place shows nothing until you have loaded it again."
- Edge cases:
  - A saved forecast with `fetchedAt` in the future (the clock was set back) is not reused: age < 0
    counts as old, so the app fetches.
  - The limit is checked when a place is chosen; changing the setting does not reload what is on screen.
  - A saved forecast within the limit is also used offline (it never needed the network), so W-10
    still holds; an older one offline falls back as today, with the banner.
  - Clearing while a request is running: that request saves its result afterwards, so one forecast can
    reappear. Accepted.
  - The forecast on screen stays when the saved ones are cleared. Pull to refresh offline right after
    clearing then has no saved forecast to fall back on and shows the error screen (the existing rule
    "no cache, no data"); the confirmation text above warns about it.
  - First launch: refresh 1 hour, animation on.
  - Reduce Motion and Low Power Mode keep working whatever the animation switch says.
- Test ideas (approved by Hugo 2026-11-24; `FakeAPIClient` gets a call counter
  and `FakeCacheStore` a `removeAll`, both in the test target):
  - Repository: a saved forecast younger than the limit gives no request, `staleReason == nil` and its
    original `fetchedAt`; an older one fetches; `nil` fetches even if the saved one is fresh; a future
    `fetchedAt` fetches; an older one with a failing request still falls back with `staleReason`; a
    reused forecast is not saved again.
  - `RefreshPolicy`: the four `maxCacheAge` values; an unknown raw value gives `.hour1`.
  - `UserDefaultsCacheStore.removeAll`: removes `forecast.*` keys and keeps another key (a throwaway
    `UserDefaults(suiteName:)`).
  - `FavoritesViewModel`: after the cache is cleared `lastKnownTemperature` is `nil` and the favourites
    are unchanged.
  - `SearchViewModel` (it has no tests yet): choosing a place with a fresh saved forecast makes no
    request, pull to refresh makes one.
  - The views have no automated tests (UX scenarios go to TEST_REPORT, W-18).
- Steps (small, each explained and checked in the simulator before the next): 1) this spec; 2) `RefreshPolicy`
  and the repository rule with tests; 3) `SearchViewModel` wiring and the "Updated" text;
  4) `SettingsView`, the gear button and the animation switch; 5) clearing saved forecasts
  (`CacheStore.removeAll`, `SettingsViewModel`) with tests; 6) SPEC plan, update log and decision log.
- Requirements: W-04, W-09, W-10, H-02

## 5. Open questions
- [x] Which forecast + geocoding API? → SMHI snow1g + geocode.maps.co (§6)
- [x] KTH proxy format (old pmp3g or new snow1g)? → no longer relevant: we use the real
      SMHI API from the start and don't use the proxy (§6)
- [x] "Single-file preferred" (handout's CONTEXT.md template) vs layered architecture?
      → multi-file, layered (§6). Ask the teacher if in doubt.
- [x] Cache: UserDefaults or SwiftData? → UserDefaults + Codable JSON (§6)

## 6. Decision log
- **2026-11-19 — Platform: iOS / Swift / SwiftUI**
  - Alternatives: Android (Kotlin), React Native (Expo)
  - Why: we both use Macs and want the Claude Agent integration in Xcode.

- **2026-11-19 — Workflow: the AI agent writes the code and explains each step**
  - Alternatives: we write the Core code ourselves, with the AI as tutor and reviewer (hint ladder)
  - Why: we want to spend our time understanding design decisions and trade-offs rather than syntax.
    The fixed explanation format (STYLE.md §3) and teach-back checks (STYLE.md §4) make sure we can
    still explain every line at the oral exam.

- **2026-11-19 — Forecast API: SMHI `snow1g/version/1` · Geocoding: SMHI autocomplete**
  *(geocoding part superseded — see "Geocoding: switched to geocode.maps.co" below)*
  - Alternatives: Open-Meteo + geocode.maps.co
  - Why: no API keys to manage or keep out of git. SMHI returns hourly steps, so we build daily
    summaries ourselves, which gives us testable data-transformation logic (W-07, W-17).
  - Trade-off: coverage limited to the Nordic area.

- **2026-11-19 — Architecture: multi-file, layered MVVM + repository**
  - Structure: View → ViewModel → Repository → APIClient / Parser / CacheStore
  - Alternatives: single file, as suggested in the handout's CONTEXT.md template
  - Why: the higher-grade criteria ask for networking, data transformation, state and UI as distinct
    layers, and the README must describe the main files. Each layer can be tested on its own.

- **2026-11-19 — Cache: UserDefaults with JSON-encoded Codable models, behind a `CacheStore` protocol**
  - Settings stored with `@AppStorage`
  - Alternatives: SwiftData
  - Why: payloads are small (last forecast, favourites, settings), and we already need Codable models
    for parsing, so caching is one encode/decode. The protocol lets tests use a fake store and lets us
    switch to SwiftData later without changing other layers.

- **2026-11-19 — Development API: real SMHI API from the start (KTH proxy not used)**
  - Why: avoids any format mismatch between proxy and real API, and the final build must use the real API anyway (W-19).
  - Consequence: we avoid unnecessary requests (search on submit, not per keystroke; reuse the cache).

- **2026-11-19 — Geocoding: switched to geocode.maps.co (replaces SMHI autocomplete)**
  - Alternatives: SMHI autocomplete (the only other geocoder the handout allows)
  - Why: SMHI autocomplete did not work when tested.
  - Consequences: needs a free API key, kept in a gitignored file with a committed example file
    the partner copies. Geocoding is international but SMHI forecasts only cover the Nordic area,
    so places outside it must show a clear "outside forecast area" message (W-16).

- **2026-11-19 — Git: the agent may commit, push and merge, but only on our go-ahead**
  - Alternatives: the agent never touches git; we run all git commands ourselves
  - Why: saves time on routine git steps. The agent works on a feature branch, asks us when to
    commit and push, and merges into `main` only when we confirm a feature is done
    (CLAUDE.md, CONTEXT.md, STYLE.md §5).

- **2026-11-20 — Parsing: separate DTO and domain model**
  - Structure: `SMHIForecastDTO` mirrors the JSON; `ForecastParser` maps it to `Forecast`.
  - Alternatives: decode JSON straight into the domain model
  - Why: SMHI's quirks (`9999` for missing values, `[lon, lat]` order, snake_case) stay inside the
    parser. When SMHI changed format in March 2026, a design like this needed only DTO and parser changes.

- **2026-11-20 — Parser rules**
  - `9999` → `nil`; a step without temperature or symbol is skipped (not kept with `nil`);
    steps sorted by time; keys mapped with `.convertFromSnakeCase` (not explicit `CodingKeys`);
    the parser throws its own small `ForecastParserError`, mapped to `WeatherError.decoding` later.
  - Why: every screen needs temperature and symbol, so a step without them is useless; skipping
    one step is better than failing the whole forecast.

- **2026-11-20 — Testing: Swift Testing, real fixture + inline JSON**
  - A real SMHI response cut to 8 steps for the normal case; small inline JSON for edge cases.
  - Alternatives: XCTest; the full 68 KB response; live network in tests
  - Why: the fixture proves we handle SMHI's real format; inline JSON makes each edge case visible
    in the test itself; no network keeps tests fast and repeatable.

- **2026-11-20 — Errors: one `WeatherError` type, classified in plain functions**
  - Cases: offline, timeout, cancelled, network, outsideForecastArea, http(code), decoding.
  - 404 with body "out of bounds" → `.outsideForecastArea`; any other 404 → `.http(404)`.
  - Alternatives: classify inside the API client's catch blocks; treat every 404 as out of area
  - Why: pure functions can be unit tested without a network; a malformed URL (our bug) should
    not be shown to the user as "outside the forecast area".

- **2026-11-20 — Cache: one entry per place, fallback on any error**
  - Key = coordinates rounded to 2 decimals (~1 km). On any failure the repository returns the
    cached forecast with `staleReason`; without a cache the error is thrown.
  - The repository always tries the network first; a "use cache if fresh" rule comes with the
    refresh-rate setting (W-04).
  - Alternatives: cache only the latest forecast; fall back only when offline
  - Why: works with favourites (W-03); old data with an explanation beats a blank screen (W-10, W-16).

- **2026-11-20 — Networking details**
  - Request timeout 15 s (default 60 s). Coordinates formatted with the POSIX locale and at most
    6 decimals.
  - Why: SMHI returns 404 for 7+ decimals and for a decimal comma, which a Swedish-language phone
    would produce with locale-aware formatting.

- **2026-11-20 — Concurrency: `@concurrent` on `WeatherRepository.forecast(for:)`**
  - Why: measured in this project that a plain `nonisolated async` function runs on the main thread
    when called from the main actor (approachable concurrency setting); only `@concurrent` moves
    parsing off the main thread (W-15).

- **2026-11-23 — App always uses the dark colour scheme** *(superseded 2026-11-24, see "Start/loading/error sky follows the time of day" below)*
  - `.preferredColorScheme(.dark)` in `SearchView`; gradients are fixed colours, not light/dark pairs.
  - Alternatives: light and dark gradient pairs; dark only while a forecast is shown
  - Why: white text on every gradient with no hard-coded text colours, and no grey → colour flash
    between start screen and forecast. Cost: the user's light/dark setting is ignored.
    One line to change if we want it back.

- **2026-11-23 — Symbols: `.multicolor`, not `.palette` or per-condition colours**
  - Alternatives: `.hierarchical` + `symbolColor` table (before), `.palette`
  - Why: on the dark background the white clouds of `.multicolor` are readable, and layer order in
    `.palette` differs per symbol, which we could not check. The `symbolColor` table was removed.

- **2026-11-23 — Start, loading and error screens use a night-sky theme**
  - Why: a failed search must not show the previous place's weather colours.

- **2026-11-23 — No quick-pick cities on the start screen**
  - Tried five (Stockholm, Oslo, Helsinki, Copenhagen, Kiruna) and removed them on our decision.
  - Note: Reykjavik is outside SMHI's forecast area (404), so Iceland can't be offered.

- **2026-11-24 — Start/loading/error sky follows the time of day; the colour scheme follows the theme**
  - `WeatherTheme.sky(at:)` gives `.day` from 06:00 up to 18:00 local time, else `.night`; `SearchView`
    keeps it fresh with `.task(id: scenePhase)` (checked every 60 s while the app is active, and
    at once when the app returns). `WeatherTheme.colorScheme` is `.light` for `.day` and `.dark`
    for everything else; `SearchView` and `FavoritesView` use it in `.preferredColorScheme`.
    Replaces "App always uses the dark colour scheme" (2026-11-23).
  - Alternatives: keep `.dark` everywhere with a bright blue day sky (fallback, not needed);
    `TimelineView` with a schedule for the exact shift; `Timer.publish` + `.onReceive`;
    real sunrise/sunset (no sun data in `ForecastStep`, no place on the start screen).
  - Why: the students wanted a light screen by day. One theme value decides both gradient and
    scheme, so they can't disagree; loading and error use the same sky, so a daytime search does
    not go light → night-dark → weather colours.
  - Consequence: during the day the scheme flips light → dark when a forecast arrives. Seen in the
    simulator 2026-11-24: a soft cross-fade, with a slight blink, judged acceptable. Clock hours
    are wrong at Nordic latitudes (dark all day in Kiruna in December); accepted for a start screen.

## 7. Oral exam map
Fill in as components are completed. Q26 is always asked first.

| # | Question (short) | Code location | Test / req |
|---|---|---|---|
| Q1 | Function that makes the API request — where, what does it return? | `Networking/SMHIAPIClient.swift` → `fetchForecastData(for:)`: builds the URL with `makeURL(for:)`, returns raw `Data` or throws `WeatherError` | W-05 · faked in `WeatherRepositoryTests` |
| Q2 | How JSON is parsed into the model | ForecastParser.parse| |
| Q3 | Which fields are used / ignored, and why | The 8 fields in StepData. The 16 cloud, pressure and visibility fields are ignored because no screen needs them.| |
| Q4 | HTTP 200 but JSON missing an expected field | Optional values become nil. A missing time gives .invalidJSON. A missing temperature or symbol skips the step.| |
| Q5 | Full data flow: "search" pressed → forecast on screen | *Partial (no UI yet):* `WeatherRepository.forecast(for:)` → `SMHIAPIClient.fetchForecastData` → `ForecastParser.parse` → `CacheStore.save` → `ForecastResult` | `successReturnsFreshForecastAndSavesIt` |
| Q6 | Caching: what is stored, when refreshed | `Persistence/UserDefaultsCacheStore.swift`: one `CachedForecast` (forecast + `fetchedAt`) per place, key rounded to 2 decimals; written after every successful fetch + parse in `WeatherRepository.fetchFresh` | W-09 · `successReturnsFreshForecastAndSavesIt`, `invalidJSONWithCacheReturnsCacheAndKeepsIt` |
| Q7 | Where fetched data lives at runtime (declaration) | data lives in SearchViewModel.state.| |
| Q8 | What happens to displayed data on a new search | a new search sets .loading and clears the old place.| |
| Q9 | How the UI learns new data arrived | @Observable.| |
| Q10 | State preserved when leaving/returning to the app | state kept when leaving and returning to the app): favourites are in UserDefaults and survive a restart| |
| Q11 | Loading state; avoiding stale data during a request | the loading state.| |
| Q12 | Two rapid searches — race condition guard | two quick searches. You search Stockholm (slow network), then Kiruna (fast). The request-ID guard. | |
| Q13 | Request timeout — what is displayed | 15 s in `SMHIAPIClient.makeSession()` → `URLError.timedOut` → `WeatherError.timeout` → repository falls back to the cache (`staleReason == .timeout`) or throws. *Display: ViewModel, not built yet.* | W-16 · `timedOutIsTimeout` |
| Q14 | Where network vs API errors (404/500) are distinguished | `Models/WeatherError.swift`: `init(_ error: URLError)` for network errors, `fromHTTP(status:body:)` for 404/500; both called in `SMHIAPIClient.fetchForecastData` | W-16 · `WeatherErrorTests` (E1–E5) |
| Q15 | No internet, first launch | `WeatherRepository.forecast(for:)`: no cache → the `guard` rethrows `.offline`. *Message: ViewModel, not built yet.* | W-10, W-16 · `offlineWithoutCacheThrowsOffline` |
| Q16 | No internet, after earlier successful load | `WeatherRepository.forecast(for:)` `catch`: returns the cached forecast with its old `fetchedAt` and `staleReason == .offline` | W-10 · `offlineWithCacheReturnsCachedForecast` |
| Q17 | Where error state is declared and how it reaches the UI | Declared in `Models/WeatherError.swift`; reaches the ViewModel as `throws(WeatherError)` or `ForecastResult.staleReason`. *ViewModel/UI part not built yet.* | W-16 |
| Q18 | Hardest error case | Candidate: "HTTP 200 but broken JSON while a cache exists": `WeatherRepository.fetchFresh` saves only after parsing succeeds, so the good cache survives | W-10 · `invalidJSONWithCacheReturnsCacheAndKeepsIt` |
| Q19 | MVVM layers in the code | the MVVM layers. `SearchView` only reads `viewModel.state` and picks a `WeatherTheme`; no network or parsing in the views| FavoritesView only displays; the logic is in the ViewModel and the store.|
| Q20 | Why the network call is not in the View | the network call isn't in the View; the View only talks to the ViewModel. `StartView`, `ForecastSkeletonView` and `WeatherTheme` are pure drawing; `SearchView` forwards taps to the ViewModel| FavoritesView only displays; the logic is in the ViewModel and the store.|
| Q21 | Where testable logic is separated from UI | The parser is a plain struct with no UI and no network. A pure function with no UI | |
| Q22 | How navigation works; why the ViewModel doesn't navigate | the ViewModel has no navigation code.| navigation lives in SearchView (navigationDestination). The ViewModel has no navigation code|
| Q23 | One requirement ID → implementing code | | |
| Q24 | Architecture changes for adding hourly forecast | the grouper already produces hourly data for today, so the architecture change would be in this file.| a new screen came from the existing DailyForecast.steps, without any change to networking or parsing|
| Q25 | A function the AI helped write — line by line | parse and makeStep are good candidates| |
| Q26 | AI meta-instructions + one requirement → code | §1 + | |
| Q27 | Where we pushed back on the AI, and why | Example: removed the quick-pick buttons; the AI first suggested Reykjavik, which SMHI does not cover | |
| Q28 | How AI code was verified — show a test | | |
| Q29 | Most effective prompt, and why | | |
| Q30 | What we'd do differently with the same tools | | |

## 8. Plan and status
| Session | Goal (req IDs) | Who | Status |
|---|---|---|---|
| 1 | Context files, API and architecture decisions | Thrainn | ☑ |
| 2 | SMHI DTO, domain models, ForecastParser + tests (W-05, W-12, W-17) | Thrainn | ◐ code + tests done; teach-back and PR review pending |
| 3 | API client, error classification, cache, repository + tests (W-05, W-09, W-10, W-15, W-16, W-17) | Thrainn | ◐ code + tests done; teach-back and PR review pending |
| 4 | Grouping: hourly today / daily rest, in the user's time zone (W-07, W-17 data transformation) | | ☐ |
| 5 | ViewModel state machine incl. race-condition guard; first search screen (W-01, W-10, W-15, W-16) | | ☐ |
| 6 | UI polish: hero block, weather-driven background, start screen, loading and error states (W-01, W-06, H-02) | Hugo | ◐ steps 1, 2, 3, 5 done; 4, 6, 7 left; teach-back and PR review pending |
| 8 | Day/night sky: start, loading and error screens follow the time of day; colour scheme follows the theme; 4 tests (13 cases) (H-02) | Hugo | ◐ code + tests done; teach-back and PR review pending |

## 9. End-of-session ritual + update log
After every session:
1. Summarise the session in 1–2 sentences (update log below).
2. Update the plan (§8).
3. Tick completed requirements (§3) — students only, and only if we can explain them.
4. Add new decisions to the decision log (§6).
5. Update the oral exam map (§7) with code locations and test names.
6. Write an entry in `docs/LLM_PROCESS.md` (students only).
7. Add running notes to `docs/REFLECTION.md` (students only).
8. Commit and push on the feature branch; merge into `main` once the feature is done and
   the partner has reviewed it.

### Update log
| Date | Who | Summary | Req IDs touched |
|---|---|---|---|
| 2026-11-19 | Thrainn | Set up Xcode project, GitHub repo and context files; decided APIs, architecture, cache and AI workflow. | — |
| 2026-11-20 | Thrainn | Session 2: SMHI DTO, domain models and ForecastParser (9999 → nil, skipped steps, sorting); 7 parser tests with a real Stockholm fixture. | W-05, W-12, W-17 |
| 2026-11-20 | Thrainn | Session 3: API client, WeatherError classification, UserDefaults cache and WeatherRepository with cache fallback (`@concurrent`); 11 tests with fakes. | W-05, W-09, W-10, W-15, W-16, W-17 |
| 2026-11-23 | Hugo | Session 6: UI polish on `feature/ui-polish`: hero block, gradient background per weather (`WeatherTheme`), frosted rows, multicolor symbols, start screen with night sky, redacted loading skeleton and `ContentUnavailableView` for errors. No ViewModel or test changes. | W-01, W-06, H-02 |
| 2026-11-24 | Hugo | Session 8: time-dependent sky on `feature/hugo-final`: `WeatherTheme.day`, `colorScheme` per theme and `sky(at:)` (06:00–18:00 local time), kept fresh with `.task(id: scenePhase)`; start/loading/error screens and the favourites sheet follow it; replaces "app always dark". 4 new tests (13 cases) in `WeatherThemeTests`. | H-02 |

## 10. AI usage summary
Which parts were AI-assisted, which tools and prompts were used (details in `docs/LLM_PROCESS.md`).

| Area / file | AI-assisted? | Tool | Note |
|---|---|---|---|
| Context files (CLAUDE, SPEC, STYLE, CONTEXT) | Yes | Claude (chat) | Drafted by AI, reviewed and edited by us |
| App code | Yes | Claude Agent in Xcode | Written by the agent, explained per STYLE.md §3 |
| | | | |

## 11. Done checklist
- [ ] All W-requirements ticked
- [ ] Tests pass on simulator (iPhone + iPad, portrait + landscape)
- [ ] Mutation test done for each key test
- [ ] Real API in final build (W-19)
- [ ] No API key in git history
- [ ] README, SPEC, TEST_REPORT, LLM_PROCESS, Reflection complete
