# Port audit — 8 October 2026

Original baseline: main commit `6ef4064`. All new application code is isolated in
`android/`; the added Android workflow is independent of the iOS release workflow.
No iOS source, package manifest, content, artwork or Apple signing configuration
has been edited.

## Gameplay inventory

| Original source | Systems reused |
| --- | --- |
| `Sources/ScrapCore/Models.swift` | Codable content, validation, rarities, elements, seven modes |
| `Battle.swift` | Seeded RNG, movement, auto-attacks, waves, enemy AI, bosses, upgrades, abilities, rewards |
| `CombatMechanics.swift` | Projectiles, weapon styles/ranges, piercing, circle/line/ring collisions, nine boss patterns |
| `CombatExcitement.swift` | Three evolutions, strikes, elite/scrap-storm/treasure events |
| `Progression.swift` | Player profile, fusion, roulette, construction, equipment, unlocks, offline rewards, missions, reboot, achievements |
| `Replay.swift` | Daily challenge codes, combo, Overdrive, synergies, medals, run history, six mastery milestones |
| `RobotStride.swift` | Distance-based stride/footprint geometry |
| `Cosmetics.swift` | Finish catalog, bundle grants, ownership checks, selection reconciliation |

`content.json` contains 8 robots, 16 weapons, 7 components, 12 recipes, 9 buildings,
9 biomes, 11 selectable upgrades and the original economy. Android loads the same
file. No balance data is authored independently.

## Assets

- Original 4×2 transparent PNG robot atlas: BOLT, TANK, ZIP, PATCH, NOVA, BOOMER,
  GLITCH, MAGNET. Atlas selection matches the original row/column order.
- Original BOLT icon source retained; Android gets a copied packaging resource.
- Eleven WAVs: `city`, `battle`, `boss`, `ui`, `fusion`, `ability`, `weapon`,
  `explosion`, `combo`, `overdrive`, `victory`. Three music loops and eight cues.
- Signature skins (ronin/bastion/medic) are original UIKit vector drawing code in
  `App/Views/SignatureRobotArt.swift`, four stride poses plus victory. Export or
  equivalent vector rendering remains required; copying the atlas alone does not
  reproduce them.
- Enemy hulls, arena grid, warning geometry, missiles, drones, weapon effects,
  footprints and evolution effects are SpriteKit drawing code, not image assets.
- Apple system icons and Avenir-specific presentation require platform-appropriate
  equivalents. Do not treat Apple framework resources as original portable art.
- Existing storefront images are not evidence of Android gameplay. Genuine
  screenshots must be captured after Android verification.

## Commerce

Seven non-consumable cosmetic products, from `StoreConfiguration.json`:

- `com.ScrapSquad.app.founder`
- `com.ScrapSquad.app.styles`
- `com.ScrapSquad.app.ronin`
- `com.ScrapSquad.app.bastion`
- `com.ScrapSquad.app.medic`
- `com.ScrapSquad.app.prism`
- `com.ScrapSquad.app.collection`

Amazon SKU registration must be confirmed against the actual catalog before
release. Product names/art and bundle grants are reusable; Apple transactions,
prices and ownership are not Amazon receipts. No subscriptions, ad SDK, analytics
SDK or player-account backend is present in the inspected iOS application.
Game Center is disabled in the shipped configuration.

User requested reuse of an existing backend for Amazon receipt verification.
Its URL, source and deployment technology have been requested, not supplied yet.
No merchant credential is embedded or assumed available.

## Saves and localization

The Swift Codable profile has schema version 1, original content IDs, inventories,
squad, buildings, levels, currencies, mission state, preferences, claimed run UUIDs
and optional journal. Swift's default Date encoding is retained by using the same
encoder/decoder. Saves are local; there is no existing cross-device transfer.
The iOS `.completeFileProtectionUnlessOpen` option is platform-specific; Android
uses AtomicFile in private application storage. Bad saves must be surfaced and
preserved rather than silently replaced.

Cosmetic selection is a separate versioned preference in the original app. It
must remain separate from untrusted entitlement grants.

The string catalog contains 416 English keys. Only English is currently marked
approved/translated in the shipped app catalog. Ten additional locale targets and
offline Argos translation/review tools exist; storefront translations do not imply
translated gameplay. Android exports approved entries to resources and retains
the original keys in a lookup catalog, using device-language matching with English
fallback. Additional platform strings need the same validation.

## Existing test inventory

Eight XCTest files cover core progression/content, combat, cosmetic grants,
excitement, replay/mastery, stride geometry, waves and release stress. iOS UI tests
cover onboarding/fusion, battle, layouts, excitement, replay/sharing and purchases.
The Android native oracle uses original actor-isolated sources. Generated traces
are executed through the real Android JNI entry point by instrumentation tests.
Those tests must pass before further phases are considered verified.

## Device and store requirements checked

- Fire OS 7 is Android 9/API 28; Fire OS 8 incorporates Android 10/11 updates.
  Initial package minSdk is 28, ABI ARM64; x86-64 is an emulator target. Add 32-bit
  support only after explicitly building/testing that runtime and device class.
- Fire OS submissions accept APK/AAB; Vega packages and TV controls are outside
  this initial tablet port.
- Tablet icons: 114×114 and 512×512. Tablet screenshots: 3–10 PNG/JPEG images;
  approved landscape sizes include 1280×800 and 1920×1200 (portrait accepted).
- Optional promotional artwork: 1024×500. Short description: 2,000 bytes; long
  description: 4,000 characters; 3–5 feature bullets, plain text.
- Appstore SDK public PEM is application-specific. Receipt verification uses a
  server-side secret. Sandbox/LAT and physical Fire-device testing remain required.

Sources checked:
https://developer.amazon.com/docs/fire-tablets/fire-os-7.html
https://developer.amazon.com/docs/app-submission/submitting-apps-to-amazon-appstore.html
https://developer.amazon.com/docs/app-submission/appstore-details.html
https://developer.amazon.com/docs/appstore-sdk/integrate-appstore-sdk.html
https://www.swift.org/documentation/articles/swift-sdk-for-android-getting-started.html
