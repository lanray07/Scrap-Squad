# Release status and outstanding work

Status: native source foundation; **not ready for submission**. No signing, upload, purchase, App Store metadata edit or deployment has been performed.

**GitHub verification update:** Xcode compilation and both onboarding/fusion and battle/pause/retreat simulator smoke tests pass. The actual captures and downloadable artifacts are recorded in [GITHUB_BUILD.md](GITHUB_BUILD.md). The broader device, accessibility, performance and service checks below remain release requirements.

## Verification recorded on Windows

- Swift gameplay package compiles with Swift 6.3.1.
- Core tests exercise content consistency, ingredient transactions, roulette, offline caps/clock rollback, dock construction timing, run idempotency, squad constraints, reboot retention, daily/weekly resets, deterministic combat/upgrade pauses, campaign completion, ability cooldown and save serialization.
- Python translation tests cover protected names, positional placeholders, missing/duplicated provider tokens and expansion warnings.
- All English content localization references resolve. Missing locales are reported explicitly.
- Native Swift files were syntax-parsed; this is not an iOS SDK build.
- Generated robot atlas was inspected and integrated into SwiftUI and SpriteKit.

## Required Mac pass

1. Run `Tools/verify_macos.sh`. Resolve any Apple SDK type/concurrency diagnostics. Launch on a small iPhone, a large iPhone and iPad in both orientations.
2. Play the complete tutorial → mission → three choices → boss → rewards → workshop → fusion → blueprint → city upgrade → save/relaunch path.
3. Validate move gesture geometry, render/update cadence, safe areas, Dynamic Type, VoiceOver focus, background/foreground pause, memory, battery and 60fps targets. Check arena aspect ratio on iPad; the engine currently uses normalized coordinates rather than a fixed physical aspect ratio.
4. Confirm the generated atlas has clean per-cell framing at all scales. It is a static pose set, not a skeletal animation library. Procedural enemies, city structures, terrain and effects require a premium art pass; music and biome audio are not bundled. There are generated UI feedback tones only.
5. Capture actual simulator/device screenshots. Do not use generated art as purported gameplay screenshots. Export all required sizes from the current App Store Connect requirements.
6. Run pseudo-localized German/French expansion, CJK and RTL layout tests. Translate and review the actual 308 English strings before announcing additional language support. Set `DEVELOPMENT_LANGUAGE` to English in the generated project if it differs.
7. Configure the actual bundle identifier, development team, capabilities and Game Center records. Test sign-in decline, offline reporting, achievement retries and leaderboard submissions. Current client scores are not server-authoritative; add integrity/anti-cheat before competitive events.
8. Configure and sandbox-test actual cosmetic products. Test Ask to Buy, pending transactions, cancellation, interrupted delivery, refund/revocation and restore. Add a local StoreKit configuration for repeatable QA. No real purchases are currently available.
9. Verify privacy disclosures and required-reason API declarations against the final compiled dependencies; the included manifest describes this source build without analytics/tracking. Complete age rating, support URL, privacy policy and contact information using actual operator details.
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
