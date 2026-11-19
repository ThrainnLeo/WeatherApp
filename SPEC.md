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

## 7. Oral exam map
Fill in as components are completed. Q26 is always asked first.

| # | Question (short) | Code location | Test / req |
|---|---|---|---|
| Q1 | Function that makes the API request — where, what does it return? | | |
| Q2 | How JSON is parsed into the model | | |
| Q3 | Which fields are used / ignored, and why | | |
| Q4 | HTTP 200 but JSON missing an expected field | | |
| Q5 | Full data flow: "search" pressed → forecast on screen | | |
| Q6 | Caching: what is stored, when refreshed | | |
| Q7 | Where fetched data lives at runtime (declaration) | | |
| Q8 | What happens to displayed data on a new search | | |
| Q9 | How the UI learns new data arrived | | |
| Q10 | State preserved when leaving/returning to the app | | |
| Q11 | Loading state; avoiding stale data during a request | | |
| Q12 | Two rapid searches — race condition guard | | |
| Q13 | Request timeout — what is displayed | | |
| Q14 | Where network vs API errors (404/500) are distinguished | | |
| Q15 | No internet, first launch | | |
| Q16 | No internet, after earlier successful load | | |
| Q17 | Where error state is declared and how it reaches the UI | | |
| Q18 | Hardest error case | | |
| Q19 | MVVM layers in the code | | |
| Q20 | Why the network call is not in the View | | |
| Q21 | Where testable logic is separated from UI | | |
| Q22 | How navigation works; why the ViewModel doesn't navigate | | |
| Q23 | One requirement ID → implementing code | | |
| Q24 | Architecture changes for adding hourly forecast | | |
| Q25 | A function the AI helped write — line by line | | |
| Q26 | AI meta-instructions + one requirement → code | §1 + | |
| Q27 | Where we pushed back on the AI, and why | | |
| Q28 | How AI code was verified — show a test | | |
| Q29 | Most effective prompt, and why | | |
| Q30 | What we'd do differently with the same tools | | |

## 8. Plan and status
| Session | Goal (req IDs) | Who | Status |
|---|---|---|---|
| 1 | Context files, API and architecture decisions | Thrainn | ☑ |
| | | | |

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
