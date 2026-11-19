# STYLE.md — How we work with the AI, and how we write code

## 1. Our goal
We want a working app **and** to be able to explain every line at the oral exam
("why", not just "what"). The AI agent writes the code. Its second job, just as important,
is to explain that code well enough that we understand it and can defend it ourselves.

Code we don't understand yet is not finished, however well it works.

## 2. Division of work
The agent writes all the code. How deep the explanation goes depends on the tier.

| Tier | What (in this app) | Explanation depth |
|---|---|---|
| **Core** | `ForecastParser` (JSON → domain model), data grouping (hourly today / daily rest), error classification (network vs HTTP vs decoding), repository fetch → cache → fallback logic, ViewModel state machine incl. race-condition guard, coordinate validation | **Deep:** full explanation format (§3), plus a teach-back check (§4) before we move on. |
| **Support** | `APIClient` (URLSession wrapper), cache store (UserDefaults/SwiftData), `NWPathMonitor` wrapper, navigation, settings storage, unit tests | **Medium:** what each function does, key decisions, and how it connects to the other layers. |
| **Boilerplate** | SwiftUI layout, styling, icons/colour mapping tables, previews, project mechanics | **Short:** summary of what was built and anything non-obvious. |

## 3. How the agent writes code
**Before writing**
- Give a short plan: which files and types will change, which requirement IDs this covers,
  and the main design choice. **Wait for our OK.**
- For a new component, draft its entry in SPEC.md §4 (component specs) first, for us to approve.

**While writing**
- Work in small, reviewable steps: one component or one function group at a time.
  No whole features in one go, no large refactors without asking.
- Code comments explain *why*, not *what*.

**After each step, explain using this format:**
1. **What I did** — summary and the list of files changed.
2. **How it works** — walk through the important lines in the order the data flows.
3. **Why this way** — the design decision, one alternative, and the trade-off.
4. **Edge cases** — what can go wrong and how the code handles it.
5. **How to verify** — a test to run (⌘U) or a step to try in the Simulator.
6. **Exam link** — which oral exam questions (SPEC.md §7) this code answers.
7. **Check questions** — 2–3 short questions for us (Core and Support only).

**Language**
- Plain English. Explain Swift concepts the first time they appear
  (e.g. `async/await`, `Codable`, `@Observable`, `@MainActor`, `Task` cancellation)
  with a short example.
- If we say "I don't get it", explain again in a *different* way (smaller example,
  analogy, step-by-step trace with real values) rather than repeating the same words.

## 4. Teach-back (understanding check)
After every Core piece, the agent asks us to explain it back, e.g.:
- "Walk me through this function with this input."
- "What happens if this line is removed? Which test fails?"
- "Which oral exam question does this answer?"

The agent corrects misunderstandings. The piece counts as done only when we can answer.
The partner who wasn't in the session goes through the same questions during PR review.

## 5. What the agent still never does
- Write `docs/REFLECTION.md` or `docs/LLM_PROCESS.md`, write test results, or tick requirements.
- Add new tests without our approval. It proposes which tests to write; we choose.
- Commit, push or merge into `main` without our go-ahead. It works on a feature branch,
  asks us from time to time whether to commit and push, and merges into `main` only when
  we confirm the feature's code is done.

## 6. Architecture
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

## 7. Naming and code conventions
- One main type per file; file name = type name.
- Names describe responsibility: `WeatherRepository`, not `DataManager`.
- DTOs (mirroring JSON) are suffixed `DTO`; domain models have no suffix.
- Errors are typed: `enum WeatherError: Error { case offline, timeout, http(Int), decoding, … }`.
- No force unwraps (`!`) or `try!` in production code.
- `async/await` only; no completion handlers.
- Dependencies are injected through initialisers (protocols where a test needs a fake).

## 8. Session start prompt (copy–paste)
```
Read CLAUDE.md, SPEC.md, STYLE.md and CONTEXT.md before anything else.
We follow STYLE.md: you write the code in small steps, and after each step
you explain it using the format in STYLE.md §3 so we understand every line.
Today we want to work on: ______ (requirement IDs: ____).
Start with a short plan and wait for our OK before writing code.
Remind us of the end-of-session ritual (SPEC.md §9) at the end.
```
