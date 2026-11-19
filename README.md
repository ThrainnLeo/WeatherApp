# WeatherApp

iOS weather app (Swift, SwiftUI) — HI1033 / CM2023 Lab B:2.
Team: Thrainn Leo Thorisson, Hugo Persson

> Appendix B. Update this file as the code changes. A reader should understand the
> architecture before opening Xcode.

## Overview
This lab is about designing and building a working weather application for a mobile platform. We will practice REST API integration, JSON parsing, state management, error handling, and UI design by using AI tools (LLMs) as part of the development workflow.
Most of us check a weather forecast every day. In this lab we will build our own: an app that fetches real forecast data from a public API and displays it in a way that is both functional and considered.

## Architecture
The app is built with MVVM plus a repository layer, so each part has one clear job. The SwiftUI views only show data and pass on what the user does, like searching for a city or adding a favourite. Each view has a ViewModel that keeps the screen’s state (loading, showing data or showing an error) and asks the repository for weather data. The repository is the app’s single source of data. It fetches the forecast from SMHI through an API client, turns the JSON into our own models with a parser, saves the result locally and returns it. When there is no network, it returns the last saved forecast together with a message that explains why. Place names are turned into coordinates with geocode.maps.co. Because networking, parsing, storage and UI are kept apart, each part can be tested on its own, and changing one layer, such as how data is stored, doesn’t affect the others.

```
View → ViewModel → Repository → APIClient / Parser / CacheStore
```

## Main files and responsibilities
| File | Layer | Responsibility |
|---|---|---|
| | | |

## Data flow: search → screen
1. _…_

## Error handling and offline behaviour
_…_

## Tests
_Where the tests are, what they cover, how to run them (⌘U)._

## APIs
_Forecast API, geocoding API, and how the dev proxy / real API is switched._
