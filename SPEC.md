# SPEC.md — WeatherApp (HI1033 / CM2023 Lab B:2)

## 1. AI meta-instructions
> Read `CLAUDE.md`, `SPEC.md`, `STYLE.md` and `CONTEXT.md` first. Where they conflict with
> a student's request, point out the conflict — the students decide.
- Follow the code tiers and hint ladder in `STYLE.md`. Core code is written by the students.
- Never mark a requirement done unless a student can explain it.
- Never write test results, tick requirements, or write `docs/REFLECTION.md` or `docs/LLM_PROCESS.md`.
- No new tests without student approval. Only test what §4 lists under "Test ideas".
- All code, comments and documentation in English.
- Before coding a component, make sure it has an entry in §4 (spec before code).
- Remind the students of the end-of-session ritual (§9) at the end of every session.

## 2. Project facts
| Course | Lab | Platform | Team | Grade target |
|---|---|---|---|---|
| HI1033 / CM2023 | B:2 Weather | iOS · Swift · SwiftUI | _name_ + _name_ | _E / C / A_ |

Forecast API: _SMHI / Open-Meteo_ · Geocoding API: _SMHI autocomplete / geocode.maps.co_

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
- Owner: _student_
- Tier: Core / Support / Boilerplate
- Purpose:
- Inputs / outputs:
- Edge cases:
- Test ideas:
- Requirements: W-xx
```

## 5. Open questions
- [ ] Which forecast + geocoding API? (SMHI matches the KTH test proxy format.)
- [ ] Handout's recommended CONTEXT.md says "single-file preferred" — conflicts with the
      layered architecture needed for the higher grade. Confirm with the teacher.
- [ ] Cache: UserDefaults or SwiftData?

## 6. Decision log
| Date | Decision | Alternatives considered | Why |
|---|---|---|---|
| | Platform: iOS / SwiftUI | Android, React Native | |

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
| Week / session | Goal (req IDs) | Who | Status |
|---|---|---|---|
| | | | |

## 9. End-of-session ritual + update log
After every session:
1. Summarise the session in 1–2 sentences (log below).
2. Update the plan (§8).
3. Tick completed requirements (§3) — students only.
4. Add new architecture choices to the decision log (§6).
5. Update the oral exam map (§7) with code locations and test names.
6. Add an entry to `docs/LLM_PROCESS.md` (students write it).
7. Add running notes to `docs/REFLECTION.md` (students only).
8. Commit, push, open/update the PR.

### Update log
| Date | Who | Summary | Req IDs touched |
|---|---|---|---|
| | | | |

## 10. AI usage summary
Which parts were AI-assisted, which tools and prompts were used (details in `docs/LLM_PROCESS.md`).

| Area / file | AI-assisted? | Tool | Note |
|---|---|---|---|
| | | Claude Agent in Xcode | |

## 11. Done checklist
- [ ] All W-requirements ticked
- [ ] Tests pass on simulator
- [ ] Mutation test done for each key test
- [ ] Real API in final build (W-19)
- [ ] README, SPEC, TEST_REPORT, LLM_PROCESS, Reflection complete
