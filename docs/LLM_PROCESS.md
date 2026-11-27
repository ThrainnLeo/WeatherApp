# Appendix D — LLM process log

> Written by the students only. The AI must not write or edit this file.

## Tools and context files
_Which AI tools were used, and which context files were loaded each session._

## Who wrote what
| Component / file | Who wrote | Note |
|---|---|---|
| CONTEXT.md| Thrainn|  |
| CLAUDE.md | Thrainn | The file is not finished yet, I have to consult with my partner on how the app should look |
|  STYLE.md|  Thrainn|  |
|  SPEC.md|  Thrainn|  |
|  README.md|  Thrainn| The file is not finished, just wrote the overview and the architecture of the app |

## Representative prompts (3–5)
* Read CLAUDE.md, SPEC.md, STYLE.md and CONTEXT.md before anything else.
We follow STYLE.md: our goal is to learn, When writing, you can summurize what you have done and explain what you did so we can understand.

     Before we write any code:
1. Summarise in 5 bullet points the rules you will follow in this project.
2. Note two corrections to CONTEXT.md: SMHI retired the pmp3g API on
   31 March 2026 (current: snow1g/version/1), and geocode.maps.co now
   requires an API key.
3. Help us choose between SMHI and Open-Meteo. Show the structure of one
   forecast response from each (fetch them if you can, including the KTH
   proxy), and list trade-offs against W-05 to W-10. Do not decide for us.
* Can you read the files again and then if you think that it looks good you can comit it to GitHub

- Read CLAUDE.md, SPEC.md, STYLE.md and CONTEXT.md before anything else.
  We follow STYLE.md: you write the code in small steps, and after each step
  you explain it using the format in STYLE.md §3 so we understand every line.

* The data foundation, fetching and parsing an SMHI forecast 
(W-05, W-12, start on W-17). No UI yet.
  Create and work on a branch named feature/W-12-forecast-parser.

* Hello, I am ready to keep working on the app. group the forecast into hourly for today and daily for the rest, in the user's time zone (W-07). After that comes the ViewModel and the first search screen
- 

Step 1 (no code yet):
- Fetch one real SMHI snow1g forecast for Stockholm (lon 18.07, lat 59.33)
  and show us the JSON structure: the top-level fields, what one time step
  looks like, and which fields we need for W-06 and W-07 (temperature,
  weather symbol, wind, precipitation). Explain what the weather symbol
  numbers mean.
- Propose the DTOs (mirroring the JSON), the domain models the app will use,
  and a ForecastParser that maps one to the other. Draft their component
  specs in SPEC.md §4.
- Wait for our OK.

Step 2 (after our OK):
- Write the models and the parser.
- Save a small real JSON sample in the test target and propose which parser
  tests to write. Wait for us to choose before writing them.
- Explain per STYLE.md §3 and end with the teach-back (STYLE.md §4).

At the end, remind us of the end-of-session ritual (SPEC.md §9).

## AI mistakes and how we handled them

## Work log
| Date | Who | Task given to the AI | What it produced | Kept / changed | Observations | Time |
|---|---|---|---|---|---|---|
| 19/11/2026  | Thrainn| Finished writing the .md files | Changes in rules and API | Kept| The agent was confusing when pointing out the errors | 30 min |
|  20/11/2026| Thrainn | Let the agent read SMHI forcast by creating functions (SMHIForcastDTO) That copies the JSON into models in the code. It also did some tests | It produced new files for the code (Models, Networking, Parsing, fixtures, fakes and added to WeatherAppUITest | kept | |  1h|
|  22/11/2026| Thrainn | I asked the agent to group the forecast as horly, dayly and weekly information and to fix the ViewModels first screen  | It produced a design with 6 decisions for both tasks |  kept|  I noticed that I had to go to  and generate a API Key to  ttps://geocode.maps.co/account/translate the coordinates of the location  for a good UI |  3h|
| 23/11/2026| Hugo | After downloading Emil Kowalski design skills, create but don't code 5-7 visual changes using the skills now added, change things like SU visuals, colors, spacing, fonts and such to improve the visuals. | It produced a redesigned UI for the app | Kept | It did not change the original visuals when starting the app so it looked a bit strange when it went from a white/ grey screen to a lightblue one after searching for a location | 2h |
| 23/11/2026 | Hugo | After running with the 1, 2, 3 improvement that Claude suggested I started to fix the things that needed improvement, "Set the home screen to a night/ day mode (depending on time of day) that matches the weather visuals. Remove the preset cities from the Home Screen" | It produced a slightly better version of the app where the old white/ grey color is all gone and is now using a light blue/ dark purple color depending on weather and time of day. | kept | after the first part of the promo I noticed the preset cities looked out of place and decided to remove them quickly after | 1h |
| 23/11/2026 | Thrainn |  Asked what was left on the app, then I asked to build a ditaild screen and tests to make sure that the code worked lastly I asked to add the favorite feature where the user can add locations to a list for easy access |  It produced a list of unfinished tasks and gave me a plan for todays session. I merged every branch on GitHub to the main branch and then it produced specs for the screen aswell as some code for the testing It also produced the favorite feature |  kept  |  Today my envirement (Xcode) chrashed two times while prompting. This is the first time it happened and this can be becouse I am running the agent in the enverement.I maneged to keep going by forcequitting the application (Xcode) and start over without compremizing the code| 2h|  
|  |  |  |  |  |  |  |
