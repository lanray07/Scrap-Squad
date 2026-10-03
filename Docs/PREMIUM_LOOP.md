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

New core tests cover UTC rotation, malformed codes, fixed loaner profiles, combo expiry/Overdrive gating, synergy prerequisites, seeded opening equivalence, old-save decoding, journal bounds/persistence and duplicate reward protection. A native UI test covers mastery, circuit deployment, result sharing preview, retry and saved records, with genuine simulator captures. Validation status is recorded after GitHub's Apple SDK run completes.

## Product boundaries

The game still needs device performance testing, gameplay tuning with real players, reviewed non-English in-app translations and real App Store sandbox checks. Cloud saves, friends, multiplayer, public rankings and live events require a separate online design and privacy review; they are not represented as working features. A richer 3D presentation and more biomes/weapons also remain future production work.

Before promising these mechanics in advertising, measure the first-run completion rate, whether players understand fusion, replay choices and voluntary sharing in a consented playtest. Launch with a truthful gameplay trailer and creator challenge codes. There are no invented player counts, automatic invitations, paid power, loot-box purchases or engagement guarantees.
