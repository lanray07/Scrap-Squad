# Release status and outstanding work

Current distribution status: signed version 1.0, build 7 with combat momentum, challenges, mastery, sharing and optional one-time cosmetic purchases uploaded successfully to App Store Connect on 3 October 2026 and attached to the version record. Both products have eleven localizations, pricing, availability, review notes and genuine review screenshots saved. Store copy, privacy, age ratings and content rights are saved. See [App Store Connect status](Store/APP_STORE_CONNECT.md) and [cosmetic verification](Store/IAP/README.md). The app and purchases have not been submitted for review or approved. The broader gameplay, device, accessibility and performance checks below remain product-quality requirements.

**GitHub verification update:** Apple SDK compilation, 22 core tests, 13 tooling tests and six simulator UI tests pass, including the replay update and StoreKit purchases. See [PREMIUM_LOOP.md](PREMIUM_LOOP.md). The actual captures and downloadable artifacts are recorded in [GITHUB_BUILD.md](GITHUB_BUILD.md). The broader device, accessibility, performance and service checks below remain release requirements.

## Verification recorded on Windows

- Swift gameplay package compiles with Swift 6.3.1.
- Core tests exercise content consistency, ingredient transactions, roulette, offline caps/clock rollback, dock construction timing, run idempotency, squad constraints, reboot retention, daily/weekly resets, deterministic combat/upgrade pauses, campaign completion, ability cooldown and save serialization.
- Python translation tests cover protected names, positional placeholders, missing/duplicated provider tokens and expansion warnings.
- All English content localization references resolve. Missing locales are reported explicitly.
- Native Swift files were syntax-parsed; this is not an iOS SDK build.
- Generated robot atlas was inspected and integrated into SwiftUI and SpriteKit.

## Required Mac pass

1. Apple SDK compilation, 22 core tests and six UI tests passed on GitHub's Mac runners; iPhone and iPad portrait captures are recorded. Complete small-iPhone and landscape/device checks and run `Tools/verify_macos.sh` for broader local verification.
2. Play the complete tutorial → mission → three choices → boss → rewards → workshop → fusion → blueprint → city upgrade → save/relaunch path.
3. Validate move gesture geometry, render/update cadence, safe areas, Dynamic Type, VoiceOver focus, background/foreground pause, memory, battery and 60fps targets. Check arena aspect ratio on iPad; the engine currently uses normalized coordinates rather than a fixed physical aspect ratio.
4. Confirm the generated atlas has clean per-cell framing at all scales. It is a static pose set, not a skeletal animation library. Procedural enemies, city structures, terrain and effects require a premium art pass; music and biome audio are not bundled. There are generated UI feedback tones only.
5. Ten actual iPhone captures and ten actual iPad captures have been framed and uploaded to App Store Connect's required slots. Refresh these screenshots if the app UI or gameplay changes before submission.
6. Run pseudo-localized German/French expansion, CJK and RTL layout tests. Review the actual 375 English-source translation drafts before announcing additional language support. `DEVELOPMENT_LANGUAGE` is English in the generated project.
7. The actual bundle identifier and team are configured and cloud-signed build 7 is uploaded and attached. Game Center is disabled for release 1.0. Before enabling it in a future release, configure records, update privacy disclosures and test sign-in decline, offline reporting, achievement retries and leaderboard submissions. Current client scores are not server-authoritative; add integrity/anti-cheat before competitive events.
8. Two cosmetic products are configured and local StoreKit UI tests passed purchase, equip/remove, relaunch persistence, restore and refund removal. A bundled UI-test StoreKit configuration enables repeatable QA. Complete real-device App Store sandbox/TestFlight validation, including Ask to Buy, pending approval, cancellation, interrupted delivery and cross-device restore. The app and purchases are not live.
9. Privacy, age rating, content rights, support/marketing URLs and existing review contact details are saved. Build 7 declares app-only UserDefaults access for cosmetic preferences, without analytics/tracking; StoreKit verification stays on-device. Reassess disclosures and required-reason API declarations if dependencies, services or data handling change.
10. Tune progression with device playtests and measured retention/economy data. Current numbers are initial balancing values, not proven production balance.

## Features from the master prompt that remain incomplete

| Requirement | Current status / remaining work |
| --- | --- |
| Premium stylized 3D | Generated 3D-looking 2D robot sprites; no real 3D scene/rigs, expression/victory sets or completed biome/environment art |
| Signature weapon spectacle | Native trails, splash and status logic; distinct drone armies, orbitals, laser beams and missile guidance still need weapon-specific visuals/behaviors |
| Robot progression | Levels and affinities implemented; rank evolution and a dedicated robot-factory UI remain |
| City facilities | All nine buildable/visible; several are cosmetic scaffolding. Research uses a level bonus, not a full branch research tree |
| Blueprint scope | 12 recipes, not 180. The 25/100 collection achievements are expansion milestones and cannot be completed with this content pack |
| Boss variety | Nine named encounters share one armor/telegraph/phase controller. Unique patterns, multi-part weakpoints and bespoke arena hazards remain |
| Squad positioning | Formation follows player; explicit editable formation/positioning remains |
| Roguelite specificity | Synergy-ranked choices implemented; some modifiers still share underlying effects |
| Roulette presentation | Immediate animated reveal, haptics, tone and text sharing; timed countdown, dedicated particles/audio and rendered share card remain |
| Events/community goals | Daily/weekly local tasks and daily anomaly only. No seasonal service, community server, event calendar or global progress |
| Monetization | Optional verified non-consumable tint cosmetics adapter. Ads, consumable packs, subscriptions and season pass are not offered |
| Audio | Volume channels and cue routing, synthesized feedback; licensed/original music and combat sound library remain |
| Localization | English source ready; ten other locales have export/translation/review/import tooling, not approved app translations |
| ASO | English draft and six truthful screenshot briefs. Market-specific keyword research and localized descriptions remain |
| Production QA | Core tests pass; Apple SDK compilation, simulator/device QA, store integration, performance profiling and release approval remain |

The app deliberately makes no claims about live community totals, actual player rankings, discounted products or unshipped blueprint counts. Daily activities use UTC keys and no streak dependency. Local clocks are used for expeditions; introduce server time if economic integrity later requires it.
