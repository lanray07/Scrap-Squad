# Replay and sharing update

This update turns a completed run into a story worth replaying or sharing. It does not guarantee virality. All new gameplay is free, offline and independent of cosmetic purchases.

## Implemented

- **Combat momentum:** kills within 3.5 seconds extend a combo; every eight kills adds a score multiplier, capped at ×5. Twelve kills fill Overdrive. A manual activation gives six seconds of faster, stronger fire. It cannot stack or recharge while active. Pausing and upgrade choices freeze the engine timer.
- **Build discoveries:** Fire Core + Cryo Core grants Thermal Shock; Tesla Coil + a splitting upgrade grants Storm Lattice; Critical Processor + Overclock Module grants Perfect Storm. Each bonus applies once per run. Upgrade choices indicate a synergy they would complete. Weapon modifiers alone do not unlock these awards.
- **Daily Circuit:** UTC day selects a versioned `SQS1-XXXXXXXX` seed. Challenge codes use the same loaner weapon, weapon level, squad and robot levels with no city/reboot advantage. Cosmetics only affect appearance. The first three arenas rotate. Saved codes remain replayable after their day. This is offline asynchronous comparison, not live multiplayer, a global leaderboard or an anti-cheat system. Compare only the same app version.
- **Run it back:** retry from results without returning through the lobby. Challenge retries retain the same code and loadout; normal retries reroll the world. Rewards are claimed once per run ID.
- **Hall of Scrap:** thirty recent run records, lifetime best scores by mode, best combo, discovered synergies and earned medals. Six permanent mastery goals show progress without streaks, penalties, notifications or paid skips. Older version 1 saves decode without the new optional journal.
- **Native sharing:** preview and export a 1020-pixel-wide branded result image using ImageRenderer and Apple's share sheet, plus a replay code and public game website. Sharing is player initiated. No automatic posting, contact access, name, personal ID or backend is involved.
- **Original sound:** three composed synthesis loops (city, battle, boss) and eight authored cues. `Tools/compose_audio.py` reproduces them without samples or external assets. Sound honors silent mode, existing volume controls and background/pause stops. SFX concurrency is bounded. Overdrive has a static aura; wave, combo and synergy callouts respect reduced-motion preferences.

## Validation

[Final native validation](https://github.com/lanray07/Scrap-Squad/actions/runs/37158254127) passed Apple SDK compilation, 22 core tests, 13 tooling tests and all six iPhone UI tests for source `ddb294db90e44a7b426d14f332134e89f5042d34`. The replay test earns Overdrive through actual combat, activates it, previews a real run card, retries, confirms the combat clock continues and verifies saved mastery progress. Existing purchase/restore/refund and fusion/battle flows also passed.

New core tests cover UTC rotation, malformed codes, fixed loaner profiles, combo expiry/Overdrive gating, synergy prerequisites, seeded opening equivalence, old-save decoding, journal bounds/persistence and duplicate reward protection. Six genuine simulator captures and their source hashes are saved in [Replay/Captures](Replay/Captures/capture-provenance.json). The archive lazily prepares visible cards, clears rendered images when they leave the screen and starts a fresh SpriteKit scene on retry. The combat clock shows seconds.

[Signed build 7](https://github.com/lanray07/Scrap-Squad/actions/runs/37158256194) uploaded the same tested app source. All three music loops and eight cues were confirmed in the simulator bundle. [Free Argos generation](https://github.com/lanray07/Scrap-Squad/actions/runs/37157340806) produced 3,750 source-matched drafts across ten languages; coverage and token integrity passed, language quality remains unapproved.

## Product boundaries

[Additional device verification](DeviceQA/README.md) passed both replay and landscape/rotation cases on iPhone SE and iPad Pro 13-inch simulators on 4 October 2026. Twenty genuine captures include full landscape pause controls and the compact-device share card. App code is unchanged from build 7; broader physical-device and accessibility checks remain.

[Apple configuration verification](https://github.com/lanray07/Scrap-Squad/actions/runs/37158993311) confirmed processed build 7 is attached to version 1.0, resource `b96d37ee-18c5-4532-9860-3091624e86e2`. Both cosmetic products retain their pricing, eleven localizations, availability and processed review images. The [whitelisted status report](Replay/app-store-status.json) contains no credentials. No App Review submission or release occurred.

The game still needs device performance testing, gameplay tuning with real players, reviewed non-English in-app translations and real App Store sandbox checks. Cloud saves, friends, multiplayer, public rankings and live events require a separate online design and privacy review; they are not represented as working features. A richer 3D presentation and more biomes/weapons also remain future production work.

Before promising these mechanics in advertising, measure the first-run completion rate, whether players understand fusion, replay choices and voluntary sharing in a consented playtest. Launch with a truthful gameplay trailer and creator challenge codes. There are no invented player counts, automatic invitations, paid power, loot-box purchases or engagement guarantees.
