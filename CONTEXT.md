# CONTEXT.md — Course constraints and team workflow

## Course facts
- Course: HI1033 / CM2023 — Mobile Sports Application and Data Mining
- Lab: B:2 — Native Weather App (pair lab, Lab B:1 must be passed)
- Platform: **iOS, Swift, SwiftUI, Xcode** (fixed for the whole lab)
- Submission: one Reflection report + Appendix A (test report), B (README.md),
  C (SPEC.md), D (LLM_PROCESS.md). Code is shown at the oral exam, not submitted.
- Submit at least one day before the scheduled presentation.

## Constraints
- No external libraries — platform SDK only.
- Network: `URLSession` with `async/await`, called from the repository layer, never from a View.
- Parsing: `Codable` into our *own* DTO/model structs, never directly into view-facing types.
- Persistence: `UserDefaults` (small payloads) or `SwiftData` (structured).
- Connectivity: `NWPathMonitor` (Network framework).
- Testing: Xcode Simulator or physical device. **A browser preview does not count.**
  Test on both iPhone and iPad simulators, portrait and landscape.

## APIs
Chosen APIs (see SPEC.md §6 Decision log for why):

| Purpose | API | URL |
|---|---|---|
| Forecast | SMHI (snow1g) | `https://opendata-download-metfcst.smhi.se/api/category/snow1g/version/1/geotype/point/lon/{lon}/lat/{lat}/data.json` |
| Geocoding | geocode.maps.co | `https://geocode.maps.co/search?q={place}&api_key={key}` |

- The API key lives in a gitignored file and is never committed.
- SMHI only covers the Nordic area. Places outside it (e.g. "Paris") must show a clear
  message, not a crash or a blank screen.
- Not used: Open-Meteo, SMHI autocomplete (did not work when tested), KTH proxy.

**Notes (checked 2026-11-19):**
- SMHI retired its old forecast API (`pmp3g/version/2`) on 31 March 2026. The current one is
  `https://opendata-download-metfcst.smhi.se/api/category/snow1g/version/1/geotype/point/lon/{lon}/lat/{lat}/data.json`.
  Each time step has `time` and a flat `data` object (the old format used `validTime` and a `parameters` array).
- geocode.maps.co now requires a free API key (`api_key` parameter). The key lives in
  a file listed in `.gitignore` and is never committed (exact mechanism decided when we build W-08).

**Development test server (KTH proxy) — not used.** It still serves the old pmp3g format as a
fixed 2021 snapshot, so we develop against the real SMHI API (see SPEC.md §6). Kept for reference:
- Forecast: `https://maceo.sth.kth.se/weather/forecast?lonLat=lon/14.333/lat/60.383`
- Search:   `https://maceo.sth.kth.se/weather/search?location=Sigfridstorp`

**The final submission must use the real API, not the proxy.** Keep the base URL in one
place (e.g. an `APIEnvironment` enum) so switching is a one-line change.

Inspect every JSON response in a browser before writing parsing code.

## Team workflow (git)
- Repo on GitHub (private). Default branch: `main`. `main` must always build.
- One branch per feature/requirement: `feature/W-08-geocoding`, `fix/offline-banner`, …
- Before starting a session: `git pull` on `main`, then branch.
- Small commits with clear messages, reference requirement IDs: `W-12: add ForecastParser`.
- Merge via Pull Request; the *other* partner reviews (doubles as oral-exam prep).
- Avoid both partners changing project settings (`project.pbxproj`) at the same time.
  Adding Swift files inside the synced folders does **not** touch it.
- The AI agent works on a feature branch, never directly on `main`. It commits and pushes
  only when we say so, and asks us from time to time whether we want to. When a feature's
  code is done, it merges the branch into `main` after we confirm.

## Language
All code, comments, commit messages and documentation in English.
