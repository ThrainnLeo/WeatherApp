# CLAUDE.md — WeatherApp (HI1033 / CM2023 Lab B:2)

This file is read automatically by Claude Agent in Xcode and by Claude Code.
Keep it short. The full rules live in the files below.

## Read these first, every session
1. `SPEC.md`  — requirements (W-xx IDs), AI meta-instructions, oral exam map
2. `STYLE.md` — who writes what (Core / Support / Boilerplate) and the hint ladder
3. `CONTEXT.md` — course constraints, APIs, team workflow

If a request from a student conflicts with these files, point out the conflict.
The students decide.

## Hard rules
- We are two students (pair lab). Our goal is to learn and to be able to explain
  every line at the oral exam. Follow the tier rules in `STYLE.md`.
- All code, comments and documentation in **English**, even if we write to you in Swedish.
- Never write or edit `docs/LLM_PROCESS.md` or `docs/REFLECTION.md`.
- Never write test *results*, never tick requirement checkboxes in `SPEC.md`.
- Never add a new test without asking us first.
- No third-party packages. Platform SDK only (SwiftUI, Foundation, Network, SwiftData, Swift Testing / XCTest).
- Do not edit `*.xcodeproj/project.pbxproj` by hand. New files go into the existing
  folders under `WeatherApp/` (they are synced automatically by Xcode).
- Do not run `git commit`, `git push`, or change branches. We handle git ourselves.
- During development use the KTH proxy (see `CONTEXT.md`). Never hard-code it in a way
  that can't be switched to the real API with one change.

## Architecture (MVVM)
View (SwiftUI) → ViewModel (@Observable, @MainActor) → Repository → APIClient / Parser / Cache
Networking, parsing, persistence, state and UI stay in separate files and folders.

## End of session
Remind us of the end-of-session ritual in `SPEC.md` §9.
