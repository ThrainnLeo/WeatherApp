# Appendix A — Test report

Environment (unit test run): Xcode 27.2 (27B52), iPhone 17 Simulator, iOS 27.2 (24B8117).
Run on 27 Nov 2026 at 17:09 with ⌘U, on the merged code (favourites, settings and animated
background included). UX scenarios: iPhone and iPad simulators, see section 3.

All unit tests use **Swift Testing** and live in `WeatherAppTests/`. They run with ⌘U in Xcode,
or from the command line:

```
xcodebuild test -project WeatherApp.xcodeproj -scheme WeatherApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:WeatherAppTests
```

No unit test uses the network: API clients and stores are replaced by fakes
(`WeatherAppTests/Fakes/`), the clock and calendar are injected, and two real responses saved
from the APIs are used as fixtures (`WeatherAppTests/Fixtures/`).

## 1. Unit tests

Result of the run: **90 tests, 90 passed, 0 failed, 0 skipped** (about 33 s). Swift Testing counts a
parameterised test once, however many cases it has. The UI-test template (`WeatherAppUITests`) is
switched off in the scheme: it contains no tests of our app.

| Component | Test name | Requirement | What it checks | Result |
|---|---|---|---|---|
| **ForecastParser** (`ForecastParserTests`) | `parsesRealStockholmSample` | W-05, W-12 | The real SMHI fixture gives 8 steps, latitude/longitude not swapped, first step's values and UTC times | Passed |
| | `missingWindSpeedBecomesNilButStepIsKept` | W-12 | SMHI's missing-value marker `9999` becomes `nil`; the step stays | Passed |
| | `stepWithMissingTemperatureIsSkipped` | W-12 | A step without temperature is dropped, the others are kept | Passed |
| | `stepsInReverseOrderComeBackSorted` | W-12 | Steps come back sorted by time | Passed |
| | `nonJSONBodyThrowsInvalidJSON` | W-16 | An HTML error page gives `.invalidJSON`, no crash | Passed |
| | `emptyTimeSeriesThrowsNoUsableTimeSteps` | W-16 | An empty `timeSeries` gives `.noUsableTimeSteps` | Passed |
| | `weatherConditionMapsSymbolCode` (3 cases) | W-06 | Symbol codes 1, 27 and an unknown code (42) map to the right condition | Passed |
| **WeatherError** (`WeatherErrorTests`) | `noInternetIsOffline` | W-10, W-16 | `URLError.notConnectedToInternet` → `.offline` | Passed |
| | `timedOutIsTimeout` | W-16 | `URLError.timedOut` → `.timeout` | Passed |
| | `notFoundOutOfBoundsIsOutsideForecastArea` | W-16 | SMHI's 404 "out of bounds" → `.outsideForecastArea` | Passed |
| | `notFoundHTMLPageIsHTTP404` | W-16 | A 404 HTML page (our own bad URL) → `.http(404)`, not "outside area" | Passed |
| | `serverErrorIsHTTP500` | W-16 | 500 → `.http(500)` | Passed |
| | `unauthorizedIsAPIKeyRejected` | W-08, W-16 | 401 → `.apiKeyRejected` | Passed |
| | `tooManyRequestsIsRateLimited` | W-08, W-16 | 429 → `.rateLimited` | Passed |
| **WeatherRepository** (`WeatherRepositoryTests`) | `successReturnsFreshForecastAndSavesIt` | W-05, W-09 | Online: fresh result, saved with the injected time | Passed |
| | `offlineWithCacheReturnsCachedForecast` | W-09, W-10 | Offline with a saved forecast: it is shown with `staleReason == .offline` | Passed |
| | `offlineWithoutCacheThrowsOffline` | W-10, W-16 | Offline, nothing saved: `.offline` is thrown | Passed |
| | `invalidJSONWithCacheReturnsCacheAndKeepsIt` | W-10, W-16 | A broken answer never overwrites a good saved forecast | Passed |
| | `outsideForecastAreaWithoutCacheThrowsThatError` | W-16 | "Outside forecast area" reaches the UI unchanged | Passed |
| | `serverErrorWithCacheReturnsCachedForecast` | W-10, W-16 | Server error 500 falls back to the saved forecast | Passed |
| | `freshSavedForecastIsReusedWithoutAnyRequest` | W-04 | A saved forecast younger than the limit is shown with no request | Passed |
| | `theLimitItselfCountsAsOld` (parameterised) | W-04 | Just under the limit is reused, exactly at the limit is fetched again | Passed |
| | `olderSavedForecastIsFetchedAgain` | W-04 | An older saved forecast is fetched again | Passed |
| | `noLimitFetchesEvenIfTheSavedForecastIsFresh` | W-04 | Pull to refresh / "Try again" always fetch | Passed |
| | `savedForecastFromTheFutureIsNotReused` | W-04 | A `fetchedAt` in the future (clock set back) is not trusted | Passed |
| | `oldSavedForecastWithAFailingRequestStillFallsBack` | W-04, W-10 | Old saved forecast + failing request: falls back with a reason | Passed |
| | `noSavedForecastFetchesWhateverTheLimit` | W-04 | Nothing saved: always fetches | Passed |
| **ForecastGrouper** (`ForecastGrouperTests`) | `stepAt2300UTCBelongsToNextLocalDay` | W-07 | Days follow the user's time zone, not UTC | Passed |
| | `todayHoldsStepsFromCurrentHourToMidnight` | W-07 | "Today" holds only the current hour up to local midnight | Passed |
| | `dailyMinAndMaxCoverAllStepsOfTheDay` | W-06, W-07 | Daily min/max over all steps of the day | Passed |
| | `dailyConditionComesFromStepNearestMidday` | W-06 | A day's condition comes from the step nearest 12:00 | Passed |
| | `rainOfStepCrossingMidnightCountsForEarlierDay` | W-07 | Precipitation is counted by the middle of its interval | Passed |
| | `atMostSevenDaysAndEmptyDaysAreSkipped` | W-06, W-07 | At most 7 days after today; days without data are skipped | Passed |
| | `pastStepsAreIgnoredAndCurrentIsFirstRemainingStep` | W-07, W-10 | Old cached steps are ignored; "now" is the first remaining step | Passed |
| | `daylightSavingDayWith25HoursIsGroupedCorrectly` | W-07 | The 25-hour day (25 Oct 2026) is grouped correctly | Passed |
| **CoordinateInput** (`CoordinateInputTests`) | `decimalPointIsValid` | W-14 | "59.33" / "18.07" is accepted | Passed |
| | `decimalCommaIsValid` | W-14 | "59,33" (Swedish keyboard) is accepted | Passed |
| | `lettersAreNotANumber` | W-14 | "abc" is rejected | Passed |
| | `emptyTextIsNotANumber` | W-14 | Empty text is rejected | Passed |
| | `nanIsNotANumber` | W-14 | "nan" is rejected (Swift's `Double("nan")` succeeds) | Passed |
| | `latitudeAbove90IsOutOfRange` | W-14 | Latitude 91 is out of range | Passed |
| | `longitudeBelowMinus180IsOutOfRange` | W-14 | Longitude -181 is out of range | Passed |
| **GeocodingParser** (`GeocodingParserTests`) | `parsesRealStockholmResponse` | W-08, W-12 | The real geocode.maps.co fixture: count, name, detail, coordinates (sent as strings) | Passed |
| | `emptyArrayGivesNoPlaces` | W-08 | `[]` means "nothing found", not an error | Passed |
| | `itemWithInvalidLatitudeIsSkipped` | W-08 | An item with `lat: "abc"` is skipped | Passed |
| | `htmlErrorPageThrowsInvalidJSON` | W-16 | An HTML page gives `.invalidJSON` | Passed |
| | `entriesWithIdenticalTextAreShownOnce` | W-08 | Two identical "Paris" entries become one row | Passed |
| **CompassDirection** (`CompassDirectionTests`) | `mapsDegreesToCompassPoint` (3 cases) | W-02 | 0° → N, 90° → E, 225° → SW | Passed |
| | `justBelow360IsNorth` | W-02 | 359° → N (wrap-around) | Passed |
| | `justBeforeBoundaryIsStillNorth` | W-02 | 22.4° → N | Passed |
| | `atBoundaryItBecomesNortheast` | W-02 | 22.5° → NE | Passed |
| **Favourites store** (`FavoritesStoreTests`) | `savedPlacesLoadBackInTheSameOrder` | W-03 | Saved favourites load back in the same order | Passed |
| | `corruptDataLoadsAsEmptyList` | W-03 | Corrupt saved data gives an empty list, no crash | Passed |
| **FavoritesViewModel** (`FavoritesViewModelTests`) | `toggleAddsAndSecondToggleRemoves` | W-03 | ★ adds, ★ again removes, both saved | Passed |
| | `sameCoordinatesTwiceGiveOneEntry` | W-03 | Same place by name and by coordinates never gives two entries | Passed |
| | `placeAFewHundredMetresAwayIsAFavorite` | W-03 | A place ~400 m away counts as the same | Passed |
| | `removeAtOffsetsRemovesThatPlaceAndSaves` | W-03 | Swipe to delete removes the right place and saves once | Passed |
| | `clearingSavedForecastsRemovesTheTemperatureButKeepsTheFavourites` | W-03, W-04 | After "Clear saved forecasts" the favourite stays but shows no temperature | Passed |
| **RefreshPolicy** (`RefreshPolicyTests`) | `maxCacheAgeIsInSeconds` (4 cases) | W-04 | Never / 15 min / 1 h / 3 h give 0, 900, 3600, 10800 s | Passed |
| | `aNewInstallUsesOneHour` | W-04 | The default is 1 hour | Passed |
| | `missingValueGivesTheDefaultNotAlways` | W-04 | A missing setting is not read as 0 ("always fetch") | Passed |
| | `savedValueIsRead` (4 cases) | W-04 | Each saved value is read back | Passed |
| | `unknownSavedValueGivesTheDefault` | W-04 | An unknown saved value gives the default | Passed |
| **SearchViewModel** (`SearchViewModelTests`) | `choosingAPlaceWithAFreshSavedForecastMakesNoRequest` | W-01, W-04 | Choosing a place with a fresh saved forecast makes no request | Passed |
| | `choosingAPlaceWithAnOldSavedForecastAsksSMHI` | W-01, W-04 | An old saved forecast makes a request | Passed |
| | `neverReusingMeansAFreshSavedForecastIsStillFetchedAgain` | W-04 | With "Never", even a fresh saved forecast is fetched | Passed |
| | `pullToRefreshAsksSMHIEvenWhenTheSavedForecastIsFresh` | W-04 | Pull to refresh always makes a request | Passed |
| **Forecast cache** (`UserDefaultsCacheStoreTests`) | `removeAllForgetsEveryForecastAndKeepsOtherKeys` | W-04, W-09 | "Clear saved forecasts" removes forecasts only, not favourites or settings | Passed |
| **WeatherTheme** (`WeatherThemeTests`) | `sameMomentIsDayInStockholmAndNightInUTC` | H-02 | Day/night sky follows the local time zone | Passed |
| | `dayIsLight` | H-02 | The day sky uses the light colour scheme | Passed |
| | `everyOtherThemeIsDark` (6 cases) | H-02 | All other themes use the dark scheme (readable text) | Passed |
| | `dayRunsFrom0600UpTo1800` (parameterised) | H-02 | The day sky is used from 06:00 up to 18:00 local time | Passed |
| **Background layers** (`WeatherLayerTests`) | `rainThemesHaveRain` (2 cases) | W-06, H-02 | Rain and storm themes draw rain | Passed |
| | `nightHasStarsAndNothingElse` | H-02 | Night shows only stars | Passed |
| | `onlyNightHasStars` | H-02 | No other theme shows stars | Passed |
| | `snowHasSnowAndCloudyHasClouds` | W-06, H-02 | Snow and cloudy themes draw the right layer | Passed |
| | `dayAndSunnyHaveTheSunGlow` (2 cases) | W-06, H-02 | Day and sunny themes draw the sun glow | Passed |
| | `stormRainsHarderThanRain` | H-02 | Storm has more rain than rain | Passed |
| | `noThemeHasMoreThan80Elements` (per theme) | H-02 | Performance limit: at most 80 moving elements | Passed |
| | `noThemeRunsFasterThan30FramesPerSecond` (per theme) | H-02 | Performance limit: at most 30 frames per second | Passed |
| | `frameIntervalIsTheShortestOfTheLayers` | H-02 | The frame rate follows the fastest layer | Passed |
| | `everyLayerGetsAsManyParticlesAsItAsksFor` (per theme) | H-02 | Each layer gets its requested number of elements | Passed |
| **Background motion** (`WeatherMotionTests`) | `positionNeverLeavesTheMargins` | H-02 | Moving elements stay inside the drawing area | Passed |
| | `positionRepeatsAfterOneCycle` | H-02 | Motion repeats after one cycle | Passed |
| | `elementLeavesBelowAndComesBackInAboveTheTop` | H-02 | Falling elements wrap from bottom to top | Passed |
| | `sameSeedGivesTheSameParticles` | H-02 | The same seed gives the same layout every launch | Passed |
| | `differentSeedsGiveDifferentParticles` | H-02 | Different seeds give different layouts | Passed |
| | `fieldHasTheRequestedCountAndValuesInRange` | H-02 | Generated values are in range | Passed |
| | `negativeCountGivesAnEmptyField` | H-02 | A negative count gives no elements, no crash | Passed |
| | `wrappedKeepsTheValueInsideTheLength` (parameterised) | H-02 | A position wraps around and always stays inside the length | Passed |

W-17 ("tests for at least two of JSON parsing, error-state logic, data transformation") is covered
by all three: `ForecastParserTests` / `GeocodingParserTests` (parsing), `WeatherErrorTests` /
`WeatherRepositoryTests` (error-state logic), `ForecastGrouperTests` (data transformation).

## 2. Mutation tests
For each key test: a small deliberate change in production code, then a test run. The test should
fail; afterwards the change is reverted (proved with `git diff`).

| Test name | Mutation made (production code) | Test failed? |
|---|---|---|
| `stepsInReverseOrderComeBackSorted` | `ForecastParser.parse`: remove `.sorted { $0.time < $1.time }` | |
| `notFoundOutOfBoundsIsOutsideForecastArea` | `WeatherError.fromHTTP`: remove the "out of bounds" check, so every 404 becomes `.http(404)` | |
| `justBelow360IsNorth`, `atBoundaryItBecomesNortheast` | `CompassDirection`: remove the half-sector shift (`+ 22.5`) | |
| `offlineWithCacheReturnsCachedForecast` | `WeatherRepository.forecast(for:)`: rethrow the error instead of falling back to the saved forecast | |

## 3. UX scenarios (minimum 20)
Run in the iPhone and iPad simulators. "Actual / pass" is filled in by us after testing.

| # | Starting state | Action | Expected result | Actual / pass |
|---|---|---|---|---|
| 1 | Fresh install, online, Place mode | Type "Stockholm", tap Search | A list of matches; the Swedish Stockholm is first | |
| 2 | Match list for "Stockholm" shown | Tap "Stockholm, Stockholms kommun…" | Loading skeleton, then hero (place name, symbol, temperature, condition, high/low, wind, "Updated …"), "Today" by the hour and "Next 7 days" | |
| 3 | Place mode, online | Type " Malmö " (spaces, å/ä/ö) and search | Malmö is found; spaces and "ö" cause no error | |
| 4 | Place mode, online | Search "xyzxyzqq" | "No places found for "xyzxyzqq"." No crash | |
| 5 | Place mode | Tap Search with an empty field | "Type a place name, e.g. Stockholm." No request | |
| 6 | Place mode, online | Search "Paris" and choose Paris, France | Error screen: "SMHI only has forecasts for the Nordic area…" with "Try again" | |
| 7 | `Secrets.plist` missing or with the placeholder | Search any place | "Place search isn't set up…" message; Coordinates mode still works | |
| 8 | Coordinates mode, online | Enter 59.33 / 18.07, tap Show forecast | Forecast for "59.33, 18.07" | |
| 9 | Coordinates mode | Enter 59,33 / 18,07 (decimal comma) | Accepted, same forecast as scenario 8 | |
| 10 | Coordinates mode | Enter "abc" as latitude | "Enter the latitude as a number, e.g. 59.33." No request | |
| 11 | Coordinates mode | Enter latitude 91 | "Latitude must be between −90 and 90." | |
| 12 | Coordinates mode | Enter longitude -181 | "Longitude must be between −180 and 180." | |
| 13 | Stockholm loaded earlier, then flight mode on | Pull to refresh | Saved forecast stays, orange banner "Offline – showing data from …" | |
| 14 | Fresh install (nothing saved), flight mode on | Search by coordinates 59.33 / 18.07 | Error screen "You're offline…" with "Try again"; no crash, no blank screen | |
| 15 | Scenario 14, then flight mode off | Tap "Try again" | The forecast loads | |
| 16 | Forecast shown | Tap a day in "Next 7 days" | Detail screen: date, summary, one row per step with time span, wind with compass point, precipitation and humidity | |
| 17 | Detail screen of a later day (5–7 days ahead) | Look at the rows | Rows show spans like "07:00–13:00", not single hours | |
| 18 | Forecast for Stockholm shown | Tap ★ next to the name, open the favourites list (star-list button) | Star turns filled; Stockholm is in the list with its temperature | |
| 19 | Stockholm and Kiruna are favourites, Kiruna shown | Open favourites, tap Stockholm | Sheet closes, Stockholm's forecast loads | |
| 20 | Favourites list open | Swipe a favourite left and delete it | It disappears; still gone after restarting the app | |
| 21 | No favourites | Open the favourites list | "No favourites yet. Tap ★ on a forecast to add one." | |
| 22 | Settings: "Reuse saved forecast for" = 1 hour; Stockholm loaded less than an hour ago | Choose Stockholm again | Shown at once; "Updated" shows the original time (no new request) | |
| 23 | Settings: "Reuse saved forecast for" = Never | Choose a place loaded a minute ago | A new request is made; "Updated" shows the current time | |
| 24 | Stockholm is a favourite with a temperature | Settings → Clear saved forecasts → confirm, then open favourites | Stockholm is still a favourite but shows no temperature | |
| 25 | Forecast shown, animated background on | Settings → turn "Animated background" off | The background becomes a still gradient | |
| 26 | Forecast shown on iPhone, portrait | Rotate to landscape and back | Layout adapts; list still scrolls; nothing cut off; data unchanged | |
| 27 | Forecast shown on iPad, portrait | Rotate to landscape | Layout uses the wider screen sensibly; everything readable | |
| 28 | iPad, landscape | Open the detail screen, favourites and settings | All three screens work and are readable on the large screen | |
| 29 | Stockholm searched, then Kiruna searched quickly after | Wait for both to finish | Kiruna's forecast is shown, never Stockholm's (race guard) | |

## 4. Test files
These are attached to the submission:

| File | What it holds |
|---|---|
| `WeatherAppTests/ForecastParserTests.swift` | SMHI parser tests |
| `WeatherAppTests/GeocodingParserTests.swift` | geocode.maps.co parser tests |
| `WeatherAppTests/WeatherErrorTests.swift` | Error classification tests |
| `WeatherAppTests/WeatherRepositoryTests.swift` | Fetch → cache → fallback and reuse tests |
| `WeatherAppTests/ForecastGrouperTests.swift` | Hourly today / daily rest grouping tests |
| `WeatherAppTests/CoordinateInputTests.swift` | Coordinate validation tests |
| `WeatherAppTests/CompassDirectionTests.swift` | Wind direction tests |
| `WeatherAppTests/FavoritesStoreTests.swift` | Favourites storage tests |
| `WeatherAppTests/FavoritesViewModelTests.swift` | Favourites logic tests |
| `WeatherAppTests/RefreshPolicyTests.swift` | Refresh setting tests |
| `WeatherAppTests/SearchViewModelTests.swift` | Search screen state tests |
| `WeatherAppTests/UserDefaultsCacheStoreTests.swift` | Forecast cache tests |
| `WeatherAppTests/WeatherThemeTests.swift` | Day/night theme tests |
| `WeatherAppTests/WeatherLayerTests.swift` | Animated background layer tests |
| `WeatherAppTests/WeatherMotionTests.swift` | Animated background motion tests |
| `WeatherAppTests/Fakes/FakeAPIClient.swift` | Fake SMHI client used by the tests |
| `WeatherAppTests/Fakes/FakeCacheStore.swift` | In-memory forecast cache used by the tests |
| `WeatherAppTests/Fakes/FakeFavoritesStore.swift` | In-memory favourites store used by the tests |
| `WeatherAppTests/Fixtures/smhi_stockholm_sample.json` | Real SMHI response (8 steps) |
| `WeatherAppTests/Fixtures/geocode_stockholm_sample.json` | Real geocode.maps.co response (no API key in it) |
