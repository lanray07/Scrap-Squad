# Release status and outstanding work

Current distribution status: signed version 1.0, build 15 with distinct weapon attacks, nine boss patterns, combat momentum, challenges, mastery, sharing and optional one-time cosmetic purchases uploaded successfully to App Store Connect on 4 October 2026 and attached to the version record. All seven products have eleven localizations, pricing, availability, review notes and genuine review screenshots saved. Store copy, privacy, age ratings and content rights are saved. See [App Store Connect status](Store/APP_STORE_CONNECT.md) and [cosmetic verification](Store/IAP/README.md). The app and purchases have not been submitted for review or approved. See [release completion evidence](RELEASE_COMPLETION.md) and [device acceptance checklist](TESTFLIGHT_QA.md). The broader gameplay, device, accessibility and performance checks below remain product-quality requirements.

**GitHub verification update:** Build 15 adds three signature skins, Prism Arsenal, live previews and an ownership-aware bundle. It retains evolutions, Dash/perfect dodges, wave events, the wave fixes and walking/footprints. Apple SDK compilation, 49 core tests, 19 tooling tests and all 21 iPhone UI tests passed in the full native run. Three purchase/preview cases each passed on iPhone and iPad Pro 13 in the device-family matrix. See [current revenue update evidence](PREMIUM_SHOP.md). Physical performance, assistive testing, live Apple sandbox acceptance and human language review remain required.

## Verification recorded on Windows

- Swift gameplay package compiles with Swift 6.3.1.
- Core tests exercise content consistency, ingredient transactions, roulette, offline caps/clock rollback, dock construction timing, run idempotency, squad constraints, reboot retention, daily/weekly resets, deterministic combat/upgrade pauses, campaign completion, ability cooldown and save serialization.
- Python translation tests cover protected names, positional placeholders, missing/duplicated provider tokens and expansion warnings.
- All English content localization references resolve. Missing locales are reported explicitly.
- Native Swift files were syntax-parsed; this is not an iOS SDK build.
- Generated robot atlas was inspected and integrated into SwiftUI and SpriteKit.

## Required Mac pass

1. Apple SDK compilation, 30 core tests and eleven iPhone UI tests passed on GitHub's Mac runners. Two replay/rotation cases each also passed on iPhone SE and iPad Pro, with 31 genuine captures across the three devices; see [combat verification](COMBAT_UPDATE.md). Complete physical-device, split-view and accessibility checks and run `Tools/verify_macos.sh` for broader local verification.
2. Play the complete tutorial → mission → three choices → boss → rewards → workshop → fusion → blueprint → city upgrade → save/relaunch path.
3. Validate move gesture geometry, render/update cadence, safe areas, Dynamic Type, VoiceOver focus, background/foreground pause, memory, battery and 60fps targets. The camera now uses one physical scale for both axes across screen aspect ratios; verify movement and warning readability on physical devices.
4. Confirm the generated atlas has clean per-cell framing at all scales. It is a static pose set, not a skeletal animation library. Procedural enemies, city structures, terrain and effects require further art work. Three original city/combat/boss music loops and eight original sound cues are bundled; check their mix, silent-mode behavior and headphone output on physical devices.
5. Ten actual iPhone captures and ten actual iPad captures have been framed and uploaded to App Store Connect's required slots. Both ten-frame campaigns were refreshed for build 10 on 4 October; Apple processing, checksums and order are verified in [release completion](RELEASE_COMPLETION.md). Refresh again if visible gameplay changes before submission.
6. Run pseudo-localized German/French expansion, CJK and RTL layout tests. Review the actual 416 English-source translation drafts before announcing additional language support. `DEVELOPMENT_LANGUAGE` is English in the generated project.
7. The actual bundle identifier and team are configured and cloud-signed build 10 is uploaded and attached. Game Center is disabled for release 1.0. Before enabling it in a future release, configure records, update privacy disclosures and test sign-in decline, offline reporting, achievement retries and leaderboard submissions. Current client scores are not server-authoritative; add integrity/anti-cheat before competitive events.
8. Seven cosmetic products are configured and local StoreKit UI tests passed purchase, equip/remove, relaunch persistence, restore and refund removal. A bundled UI-test StoreKit configuration enables repeatable QA, including approval/decline and interrupted delivery. Complete real-device App Store sandbox/TestFlight validation, including Ask to Buy, pending approval, cancellation, interrupted delivery and cross-device restore. The app and purchases are not live.
9. Privacy, age rating, content rights, support/marketing URLs and existing review contact details are saved. Build 10 declares app-only UserDefaults access for cosmetic preferences, without analytics/tracking; StoreKit verification stays on-device. Reassess disclosures and required-reason API declarations if dependencies, services or data handling change.
10. Tune progression with device playtests and measured retention/economy data. Current numbers are initial balancing values, not proven production balance.

## Features from the master prompt that remain incomplete

| Requirement | Current status / remaining work |
| --- | --- |
| Premium stylized 3D | Generated 3D-looking 2D robot sprites; no real 3D scene/rigs, expression/victory sets or completed biome/environment art |
| Signature weapon spectacle | Orbiting drones, guided missiles, piercing beams, local chain lightning and artillery impacts implemented; deeper authored animation and physical-device tuning remain |
| Robot progression | Levels and affinities implemented; rank evolution and a dedicated robot-factory UI remain |
| City facilities | All nine buildable/visible; several are cosmetic scaffolding. Research uses a level bonus, not a full branch research tree |
| Blueprint scope | 12 recipes, not 180. The 25/100 collection achievements are expansion milestones and cannot be completed with this content pack |
| Boss variety | Nine distinct dodgeable attack patterns implemented with shared warning geometry and enrage timing; multi-part weakpoints and bespoke arena art remain |
| Squad positioning | Formation follows player; explicit editable formation/positioning remains |
| Roguelite specificity | Synergy-ranked choices implemented; some modifiers still share underlying effects |
| Roulette presentation | Immediate animated reveal, haptics, tone and text sharing; timed countdown, dedicated particles/audio and rendered share card remain |
| Events/community goals | Daily/weekly local tasks and daily anomaly only. No seasonal service, community server, event calendar or global progress |
| Monetization | Seven optional non-consumables: two classic packs, three signature robot skins, Prism Arsenal and an overlap-protected bundle. Ads, consumable packs, subscriptions and season pass are not offered |
| Audio | Three bundled original music loops, eight sound cues, independent volume controls and bounded playback; device listening and biome-specific expansion remain |
| Localization | English source ready; ten other locales have export/translation/review/import tooling, not approved app translations |
| ASO | Eleven storefront descriptions/localizations and ten genuine premium screenshots per iPhone/iPad set saved; build 10 replay/combat galleries refreshed and verified; market testing remains |
| Production QA | Apple SDK compilation, 30 core/16 tooling/thirteen unique UI cases per family plus four compact/iPad replay/rotation cases and signed upload verified; broader device/accessibility QA, real Apple sandbox, performance profiling and review approval remain |

The app deliberately makes no claims about live community totals, actual player rankings, discounted products or unshipped blueprint counts. Daily activities use UTC keys and no streak dependency. Local clocks are used for expeditions; introduce server time if economic integrity later requires it.
