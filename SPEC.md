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
| Q10 | State preserved when leaving/returning to the app | | |
| Q11 | Loading state; avoiding stale data during a request | the loading state.| |
| Q12 | Two rapid searches — race condition guard | two quick searches. You search Stockholm (slow network), then Kiruna (fast). The request-ID guard. | |
| Q13 | Request timeout — what is displayed | 15 s in `SMHIAPIClient.makeSession()` → `URLError.timedOut` → `WeatherError.timeout` → repository falls back to the cache (`staleReason == .timeout`) or throws. *Display: ViewModel, not built yet.* | W-16 · `timedOutIsTimeout` |
| Q14 | Where network vs API errors (404/500) are distinguished | `Models/WeatherError.swift`: `init(_ error: URLError)` for network errors, `fromHTTP(status:body:)` for 404/500; both called in `SMHIAPIClient.fetchForecastData` | W-16 · `WeatherErrorTests` (E1–E5) |
| Q15 | No internet, first launch | `WeatherRepository.forecast(for:)`: no cache → the `guard` rethrows `.offline`. *Message: ViewModel, not built yet.* | W-10, W-16 · `offlineWithoutCacheThrowsOffline` |
| Q16 | No internet, after earlier successful load | `WeatherRepository.forecast(for:)` `catch`: returns the cached forecast with its old `fetchedAt` and `staleReason == .offline` | W-10 · `offlineWithCacheReturnsCachedForecast` |
| Q17 | Where error state is declared and how it reaches the UI | Declared in `Models/WeatherError.swift`; reaches the ViewModel as `throws(WeatherError)` or `ForecastResult.staleReason`. *ViewModel/UI part not built yet.* | W-16 |
| Q18 | Hardest error case | Candidate: "HTTP 200 but broken JSON while a cache exists": `WeatherRepository.fetchFresh` saves only after parsing succeeds, so the good cache survives | W-10 · `invalidJSONWithCacheReturnsCacheAndKeepsIt` |
| Q19 | MVVM layers in the code | the MVVM layers.| |
| Q20 | Why the network call is not in the View | the network call isn't in the View; the View only talks to the ViewModel.| |
| Q21 | Where testable logic is separated from UI | The parser is a plain struct with no UI and no network. A pure function with no UI | |
| Q22 | How navigation works; why the ViewModel doesn't navigate | the ViewModel has no navigation code.| |
| Q23 | One requirement ID → implementing code | | |
| Q24 | Architecture changes for adding hourly forecast | the grouper already produces hourly data for today, so the architecture change would be in this file.| |
| Q25 | A function the AI helped write — line by line | parse and makeStep are good candidates| |
| Q26 | AI meta-instructions + one requirement → code | §1 + | |
| Q27 | Where we pushed back on the AI, and why | | |
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
