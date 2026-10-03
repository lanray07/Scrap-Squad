# Scrap Squad: Merge & Survive

Native iPhone/iPad game foundation using SwiftUI, SpriteKit and a standalone Swift gameplay package. This repository was created from the supplied master prompt. **It is a playable implementation foundation, not a release-certified production game.** The iOS application has not been compiled or run on this Windows host.

## GitHub Xcode builds

The project is connected to [lanray07/Scrap-Squad](https://github.com/lanray07/Scrap-Squad). The `Validate native game` workflow builds with Xcode on a macOS runner, validates the core/tooling, saves a simulator app zip, and runs onboarding/fusion and battle/pause/retreat smoke tests. Xcode result bundles, test screenshots and startup diagnostics are retained as workflow artifacts.

[Xcode build and both simulator tests passed in run #4](https://github.com/lanray07/Scrap-Squad/actions/runs/37147738498). See `Docs/GITHUB_BUILD.md` for verification details, artifact links and actual captures.

The simulator build requires no Apple signing secrets. The existing Apple team and App Store Connect secrets are not consumed by this workflow. A signed device archive or TestFlight upload is a separate distribution action.

You can trigger a fresh build from GitHub Actions using **Run workflow**, or through:

```sh
gh workflow run validate.yml --repo lanray07/Scrap-Squad --ref main
```

After downloading the simulator zip on a Mac, unzip it and install the app into a booted iOS simulator:

```sh
xcrun simctl install booted ScrapSquad.app
xcrun simctl launch booted com.ScrapSquad.app
```

## Open on a Mac

Requires Xcode with an iOS 17+ SDK, and XcodeGen. From this folder:

```sh
xcodegen generate
open ScrapSquad.xcodeproj
```

Choose the ScrapSquad scheme and an iPhone or iPad simulator. The build script prepares the 1024px app icon from the original generated source. For a device, set your development team and your registered bundle identifier. The supplied identifier is a development default; the existing App Store Connect app was not inspected or changed.

Run `bash Tools/verify_macos.sh` for package tests and an unsigned simulator build. The Xcode project is generated from `project.yml`; edit that file rather than the generated project.

## What works in the source

- Automatic real-time combat, drag movement, commander abilities, targeting priority, knockback, critical hits, burn, freeze, splash, additional targets/projectiles, repair, and three paused upgrade selections.
- Ten enemy archetypes, boss armor breakage, low-health attack acceleration, dodgeable attack circles, biome palettes and environmental danger circles.
- Eight original robot characters, generated art atlas, squad limits, affinity bonuses, unlocks, robot/weapon levels, and active/passive effects.
- Sixteen weapons and **twelve** discoverable recipes, atomic ingredient consumption, inventory, equipping, clues, rarity labels and a rules-based roulette with displayed equal probabilities.
- Nine campaign zones, seven mode configurations, two-minute missions, endless Survival/Arena, three-boss Boss Rush, double-scrap Scrap Run, projectile-boosted Fusion Lab, and a daily elemental modifier.
- City construction with visible level growth, damage research, squad capacity unlocks, expedition rates, eight-hour offline cap, daily/weekly tasks without streaks, local achievements and Core Reboot with retention explanation.
- Atomic local saves, corrupt-save protection, duplicate reward suppression, source String Catalogs, reviewed translation pipeline, pseudo-localization generation, accessibility labels and configurable effects/audio/haptics.
- StoreKit 2 verification, pending/cancelled/error handling, transaction updates, restore and non-consumable cosmetic tint application. The product list is intentionally empty until real products are configured.
- Game Center authentication, achievement reporting, leaderboard reporting and system leaderboard UI. Identifiers must be registered and the capability enabled before integration testing.

The shipped app language is English. Architecture supports ten additional locales; these appear in the picker only after approved translations are included. No player data is sent to translation services.

## Structure

| Location | Responsibility |
| --- | --- |
| `Sources/ScrapCore` | Models, validated content, progression and deterministic combat |
| `Sources/ScrapCore/Resources/content.json` | Recipes, combat stats, roster, zones, economy |
| `App/State` | Persistent application state and localization utilities |
| `App/Gameplay` | SpriteKit renderer; gameplay remains in the core |
| `App/Views` | Native navigation and interactive screens |
| `App/Services` | Game Center, StoreKit, audio/haptic adapters |
| `App/Resources` | Art, source String Catalog, store configuration, privacy manifest |
| `Tools` | Content authoring, localization, metadata and Mac verification |
| `Docs` | Release gaps, economy, artwork provenance and store drafts |

## Authoring and validation

```sh
python3 Tools/author_content.py
swift test
python3 Tools/localize.py audit
python3 -m unittest discover -s Tools -p 'test_localize.py'
python3 Tools/store_campaign.py
```

On this Windows machine, SwiftPM needs a scratch path without spaces:

```powershell
swift test --scratch-path C:\Users\User\ScrapSquadBuild
```

The Swift core is compiled and tested here. Parsing app Swift files does **not** validate UIKit, SwiftUI, SpriteKit, StoreKit or GameKit type correctness. Read `Docs/RELEASE.md` before treating this as an App Store build.

## Localization

The default GitHub localization workflow uses free, offline Argos models for all ten target languages. It runs automatically when the English catalog changes and uploads reviewable drafts; no API key is needed. See [automatic localization](Docs/AUTO_LOCALIZATION.md) for local use, review and optional service adapters.

```sh
python3 Tools/localize.py export de localization-review.json
python3 Tools/localize.py extract new-source-keys.json
python3 Tools/localize.py pseudo /tmp/Localizable.strings
# Optional explicit developer action, using your HTTPS provider adapter:
python3 Tools/localize.py translate localization-review.json --endpoint https://your-provider.example/translate --out localization-draft.json
# After a human reviews every entry and sets approved=true:
python3 Tools/localize.py import-approved localization-draft.json
```

The provider adapter accepts a JSON body with `sourceLanguage`, `targetLanguage`, `instruction` and `strings: [{key,text}]`; it must return `translations: [{key,text}]`. Supply its bearer credential locally via `TRANSLATION_API_KEY`. No provider is called by normal builds or catalog auditing. Placeholder/name changes block imports. Source hashes prevent stale imports. Expansion and unchanged translations require explicit reviewer acknowledgment using `allowWarnings`.

## Service configuration

Game Center is disabled in release 1.0. Before enabling `GameCenterService.enabled`, register IDs `scrapsquad.survival`, `scrapsquad.bossrush`, `scrapsquad.daily`, and the six `scrapsquad.<achievement>` identifiers in App Store Connect. Add the entitlement, test the integration, provide appropriate consent and update the privacy policy/disclosures before enabling network reporting.

Two real non-consumable cosmetic packs are configured in `App/Resources/StoreConfiguration.json`: `com.ScrapSquad.app.founder` (£2.99 UK base price) and `com.ScrapSquad.app.styles` (£1.99). The catalog maps each pack to bundled robot finishes; Founder extras add optional golden weapon trails and a Squad badge. Ownership is verified through StoreKit, selections persist locally, and refunds remove access. No purchase changes combat or progression. See [cosmetic products and verification](Docs/Store/IAP/README.md).

No ads, subscriptions, consumables, season-pass charges, analytics or remote community totals are shipped. These require separate service and product work, as recorded in the release checklist.

## App Store distribution

The separate manual `release.yml` workflow consumes the existing Apple secrets, archives for iOS and uses Apple's cloud distribution signing during export/upload. It needs no registered development device. It removes its temporary private key after the run; keys and signing material are not saved as artifacts. [Release workflow run 5](https://github.com/lanray07/Scrap-Squad/actions/runs/37155902457) uploaded version 1.0, build 5, including cosmetic purchases and the app-only UserDefaults privacy reason. This build is attached in App Store Connect. Upload success does not mean App Review approval.

`store-products.yml` updates the approved cosmetic products, eleven storefront localizations, exact GBP base prices and 173-region availability through Apple's API using the same existing secrets. Its optional completion step uploads actual review screenshots and attaches a processed build. It does not submit review, accept agreements or configure recurring subscriptions.

The public [privacy policy](https://lanray07.github.io/Scrap-Squad/privacy.html) and [support website](https://lanray07.github.io/Scrap-Squad/) are hosted without a paid service on GitHub Pages. See [current App Store Connect status](Docs/Store/APP_STORE_CONNECT.md) for saved metadata and submission preparation.
