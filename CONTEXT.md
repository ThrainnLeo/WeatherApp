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
Choose one forecast API + one geocoding API (record the choice in SPEC.md §6 Decision log).

| Purpose | Option | URL |
|---|---|---|
| Forecast (international) | Open-Meteo | https://open-meteo.com/en/docs |
| Forecast (Sweden) | SMHI | https://opendata-download-metfcst.smhi.se/ |
| Geocoding (Sweden) | SMHI autocomplete | `https://www.smhi.se/wpta/backend_solr/autocomplete/search/{place}` |
| Geocoding (international) | geocode.maps.co | `https://geocode.maps.co/search?q={place}` |

**Development test server (KTH proxy, SMHI format) — use this while developing to avoid rate limits:**
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
- The AI agent never commits or pushes. Humans do.

## Language
All code, comments, commit messages and documentation in English.
