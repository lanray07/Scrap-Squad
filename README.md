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
xcrun simctl launch booted com.scrapsquad.mergeandsurvive
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
python3 Tools/store_metadata.py
```

On this Windows machine, SwiftPM needs a scratch path without spaces:

```powershell
swift test --scratch-path C:\Users\User\ScrapSquadBuild
```

The Swift core is compiled and tested here. Parsing app Swift files does **not** validate UIKit, SwiftUI, SpriteKit, StoreKit or GameKit type correctness. Read `Docs/RELEASE.md` before treating this as an App Store build.

## Localization

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

Register Game Center IDs `scrapsquad.survival`, `scrapsquad.bossrush`, `scrapsquad.daily`, and the six `scrapsquad.<achievement>` identifiers in App Store Connect. Add the Game Center capability in the generated project and reflect it in `project.yml`/an entitlements file once provisioned.

For cosmetic products, add real non-consumable IDs to `App/Resources/StoreConfiguration.json` and map each to an existing robot and a six-digit hex tint:

```json
{
  "cosmeticProductIDs": ["YOUR_REGISTERED_PRODUCT_ID"],
  "finishes": {
    "YOUR_REGISTERED_PRODUCT_ID": {"robotID": "bolt", "tint": "FFB7A5"}
  }
}
```

No ads, subscriptions, consumables, season-pass charges, analytics or remote community totals are shipped. These require separate service and product work, as recorded in the release checklist.
