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

At the end, remind us of the end-of-session ritual (SPEC.md §9).

## AI mistakes and how we handled them

## Work log
| Date | Who | Task given to the AI | What it produced | Kept / changed | Observations | Time |
|---|---|---|---|---|---|---|
| 19/11/2026  | Thrainn| Finished writing the .md files | Changes in rules and API | Kept| The agent was confusing when pointing out the errors | 30 min |
|  20/11/2026| Thrainn | Let the agent read SMHI forcast by creating functions (SMHIForcastDTO) That copies the JSON into models in the code. It also did some tests | It produced new files for the code (Models, Networking, Parsing, fixtures, fakes and added to WeatherAppUITest |  | |  |
|  22/11/2026| Thrainn | I asked the agent to group the forecast as horly, dayly and weekly information and to fix the ViewModels first screen  | It produced a design with 6 decisions for both tasks |  |  I noticed that I had to go to  and generate a API Key to  ttps://geocode.maps.co/account/translate the coordinates of the location  for a good UI |  3h|
| 23/11/2026| Hugo | After downloading Emil Kowalski design skills "Använd skillsen apple-design, mobile-native och write-swift. Granska SearchView och prognosvyerna mot Apples Human Interface Guidelines. Principerna i skillsen är skrivna för webben, så översätt dem till idiomatisk SwiftUI (inga CSS-lösningar, inga tredjepartspaket). Föreslå 5–7 konkreta förbättringar, till exempel SF Symbols för väder, typografi för temperaturer, färger efter väderlek, spacing och subtila animationer. Rangordna dem efter hur stor visuell skillnad de gör och hur mycket arbete de kräver. Skriv ingen kod förrän jag har valt." | It produced a redesigned UI for the app | Kept | It did not change the original visuals when starting the app so it looked a bit strange when it went from a white/ grey screen to a lightblue one after searching for a location | 2h |
| 23/11/2026 | Hugo | After running with the 1, 2, 3 improvement that Claude suggested I started to fix the things that needed improvement, "Set the home screen to a night/ day mode (depending on time of day) that matches the weather visuals. Remove the preset cities from the Home Screen" | It produced a slightly better version of the app where the old white/ grey color is all gone and is now using a light blue/ dark purple color depending on weather and time of day. | kept | after the first part of the promo I noticed the preset cities looked out of place and decided to remove them quickly after | 1h |
