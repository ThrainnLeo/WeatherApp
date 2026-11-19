# STYLE.md — How we work with the AI, and how we write code

## 1. Our goal
We want a working app **and** to be able to explain every line at the oral exam
("why", not just "what"). The AI is a tutor, reviewer and boilerplate writer — not the author
of the logic the lab tests.

## 2. Three code tiers
> Draft — discuss and adjust together before the first coding session.

| Tier | What (in this app) | Who writes | AI's role |
|---|---|---|---|
| **Core** | `ForecastParser` (JSON → domain model), data grouping (hourly today / daily rest), error classification (network vs HTTP vs decoding), repository fetch → cache → fallback logic, ViewModel state machine incl. race-condition guard, coordinate validation | Student | Tutor and reviewer only. Must follow the hint ladder (§3). |
| **Support** | `APIClient` (URLSession wrapper), cache store (UserDefaults/SwiftData), `NWPathMonitor` wrapper, navigation, settings storage, unit tests | Shared | May draft small pieces; we read, change and can explain every part. |
| **Boilerplate** | SwiftUI layout, styling, icons/colour mapping tables, previews, project mechanics | AI | Writes directly, explains the key parts. |

**Pair rule:** each Core component has one *owner* who writes it, and the other partner
must be able to teach it back before the PR is merged. Record owners in SPEC.md §4.

## 3. Hint ladder (Core code)
When we are stuck, go one step at a time and stop as soon as we can continue:
1. **Concept** — explain the idea in plain words with a small example
2. **Questions** — ask what the function must guarantee and what could go wrong
3. **Pseudocode** — steps without any programming language
4. **Skeleton** — signature and `// TODO` comments only
5. **Review** — we write it; the AI reviews without fixing
6. **Full solution** — only if we ask after steps 1–5. We then close it and rewrite from memory.

## 4. Teach-back after every Core or Support piece
- "Walk me through this function with this input."
- "What happens if this line is removed? Which test fails?"
- "Which oral exam question (SPEC.md §7) does this answer?"

If we can't answer, the piece is not done — regardless of who wrote it.

## 5. Architecture
```
View (SwiftUI)          – renders state, forwards user intents. No networking, no parsing.
  ↓
ViewModel (@Observable, @MainActor)
                        – owns UI state (idle / loading / loaded / error), calls repository.
                          Does not navigate; navigation lives in the View layer.
  ↓
Repository              – single entry point for data: fetch → parse → cache → fallback.
  ↓
APIClient · Parser · CacheStore · ConnectivityMonitor
```

Planned folders (Xcode synced folders under `WeatherApp/`):
```
WeatherApp/
  App/           WeatherApp.swift, root navigation
  Models/        domain models (Forecast, DailyForecast, HourlyForecast, Place, …)
  Networking/    APIClient, APIEnvironment, endpoints, DTOs
  Parsing/       ForecastParser, GeocodingParser
  Persistence/   CacheStore, FavoritesStore, SettingsStore
  Repository/    WeatherRepository
  ViewModels/    SearchViewModel, DetailViewModel, FavoritesViewModel, SettingsViewModel
  Views/         screens + small reusable components
WeatherAppTests/ unit tests (Swift Testing)
```

## 6. Naming and code conventions
- One main type per file; file name = type name.
- Names describe responsibility: `WeatherRepository`, not `DataManager`.
- DTOs (mirroring JSON) are suffixed `DTO`; domain models have no suffix.
- Errors are typed: `enum WeatherError: Error { case offline, timeout, http(Int), decoding, … }`.
- No force unwraps (`!`) or `try!` in production code.
- `async/await` only; no completion handlers.
- Dependencies are injected through initialisers (protocols where a test needs a fake).
- Comments explain *why*, not *what*.

## 7. Session start prompt (copy–paste)
```
Read CLAUDE.md, SPEC.md, STYLE.md and CONTEXT.md before anything else.
We follow STYLE.md: our goal is to learn, we write Core code ourselves, and you act
as tutor and reviewer. Today we want to work on: ______ (requirement IDs: ____).
Ask us what we have tried first. Remind us of the end-of-session ritual (SPEC.md §9).
```
