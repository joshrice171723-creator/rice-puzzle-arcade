# Measurement and genuine tester plan

No measured users, retention or paid revenue is claimed. No external analytics service is configured. Start with actual Console/AdMob reports and consent-appropriate local instrumentation; do not silently add remote telemetry.

## Per-app metrics and definitions

| Metric | Definition / intended source |
| --- | --- |
| Daily active players | Distinct lawful player identifiers active on date; unavailable until appropriate measurement exists |
| Sessions/player, sessions/day | Sessions divided by observed players; define a session boundary before deployment |
| Session length | Foreground active milliseconds per session, excluding paused/dialog/ad time |
| D1 / D7 return | Start-date cohort returning on day 1 / day 7; require appropriate retention measurement |
| Ads/player | Valid paid ad impressions divided by measured active players; never count test impressions |
| Reward acceptance | Explicit reward-video requests divided by displayed eligible offers |
| Reward delivery | Confirmed benefits divided by SDK earned callbacks; duplicate callbacks must not inflate count |
| Interstitial show rate | Confirmed shows divided by eligible end-of-run transitions |
| Fill/errors | Loaded ads / requests; errors by format and SDK code, without private payloads |
| Estimated/final revenue | Separate actual AdMob estimated reporting from finalized payouts |
| Realized eCPM | Reported ad revenue / valid paid impressions × 1,000 |
| Crash-free sessions | Sessions without crash / observed sessions; requires actual crash data source |
| Store conversion | Actual store acquisitions / measured listing visitors in Play Console |
| Privacy choices | Aggregate consent availability/choice counts only when lawful; never infer sensitive traits |

`estimated ad revenue = valid paid impressions / 1,000 × realized eCPM` is an accounting relationship, not a forecast. Unknown values remain unknown. These metrics never feed gameplay difficulty, random selection or loss timing.

Event contracts: `game_start`, `game_end`, `session_duration`, `round_completed`, `reward_offer_shown`, `reward_earned`, `ad_request`, `ad_loaded`, `ad_shown`, `ad_failed`, optional SDK impression revenue. Use app/version/format and aggregate counts, avoid identity, contact, location, demographics and raw ad payloads. Select lawful retention/collection settings before any remote sink is enabled; update privacy and Play disclosures first.

## Genuine closed-test recruitment

When signed builds and Console testing are ready, recruit through Joshua-approved friends, colleagues and communities. No outreach has been sent. Explain device needs, duration and honest-feedback expectations; no payment, ad-click request or review incentive. If the new-personal-account rule applies, keep at least 12 genuine testers continuously opted in for 14 days **per app**; enrollment alone is not useful testing evidence. Record opt-in dates and app version privately without publishing contact details.

Draft invitation: “I'm testing three original Android puzzles: a shape-placement game, a number-merging game and a timed symbol-matching game. Would you like to try one and share candid feedback? If you join the Play closed test, please remain opted in for the full test period. There is no purchase required. Test builds use test ads; please do not interact with live advertising for testing.” Add a verified opt-in link only after Console creates it.

## Feedback template (copy into a verified support issue or private form)

- Game and exact app version:
- Device model / Android version:
- What were you trying to do?
- Steps to reproduce:
- Expected result / actual result:
- Did the app pause, restart, go offline or return from the background?
- Were controls and symbols understandable? Any hard-to-read text or small targets?
- Were optional ad benefits clear? Never include advertising identifiers.
- One thing you enjoyed / one thing you would change:
- Screenshot or short recording with personal information removed (optional):

Do not collect names/emails beyond what the chosen testing channel actually needs. No feedback form endpoint or public issue tracker is claimed live. Triage crashes and blocked play first, then usability; retain a version-specific defect/repair/retest log for each app and summarize real feedback for production application.

## Organic launch materials

Prepare three actual vertical clips for each game and five native screenshots per listing. Post only to owner-approved channels after release eligibility and truthful availability are confirmed. Start with honest play examples and testing learnings. Evaluate actual retention and reliability before any separately approved acquisition spending.
