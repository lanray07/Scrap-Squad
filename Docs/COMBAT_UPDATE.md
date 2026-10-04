# Weapon spectacle and boss combat

This combat pass replaces arena-wide instant targeting with bounded engagement and distinct attack behaviors. Progression rewards, the free gameplay model and cosmetic-only purchases are retained. Balance values are starting points for physical-device playtests, not measured retention improvements.

## Weapon behavior

| Family | Implemented behavior |
| --- | --- |
| Basic/flame bolts | Local targeting, impact and existing burn/status modifiers |
| Shotgun/frost/blizzard | Multi-target volleys, with existing freeze and splash modifiers |
| Fire Drone | Up to six drones orbit the player and fire from their current positions |
| Rocket/Missile Swarm | Visible projectiles pursue moving targets, retarget nearby living enemies when needed and apply damage/splash on impact |
| Workshop/Prism/Singularity lasers | Beams pierce up to three additional aligned living targets, in distance order, within beam range |
| Arc/Chain/Plasma/Aurora | Linked lightning jumps to nearby unstruck targets, with per-hop damage falloff and a maximum of six jumps |
| Orbital Hammer | Artillery columns and larger impact rings with existing explosive splash |

Primary range is 0.40 world units for standard weapons, 0.48 for missiles and 0.52 for beams/artillery. Chain links must be within 0.22 units. Missiles travel at 0.75 units per second, expire after 2.5 seconds and are capped at 48 concurrent projectiles. Timed upgrade choices and Pause freeze simulation. No hit is granted to a missile merely because it was fired.

## Boss identities

| Biome | Attack pattern |
| --- | --- |
| Rust Flats | Locked-target slam |
| Neon Junkyard | Marked charge lane and dash |
| Frozen Foundry | Crossing frost lanes |
| Toxic Processing Plant | Three rotated mine circles |
| Abandoned Megacity | Three-lane fan |
| Electric Wastes | Shock ring with a safe center |
| Machine Graveyard | Alternating horizontal/vertical sweep |
| Orbital Factory | Four-point bombardment |
| Quantum Rift | Outer ring and central collapse |

Warnings lock their target when cast. Their circle, capsule or ring geometry is shared by simulation and rendering. Boss windup is 1.5 seconds, reduced to 1.1 seconds below half health; the attack interval then decreases from 3.8 to 2.4 seconds. Overlapping areas from one detonation do not multiply the hit. A short damage grace period prevents simultaneous warning ticks from stacking. Defeated bosses clear their remaining warnings. Armor break correctly carries excess damage through to health. Boss palette, modules and phase trim vary by encounter; multi-part weakpoints and fully authored animations remain future work.

Environmental warnings also resolve once after their visible countdown, replacing a frame-dependent damage window. Burrowed enemies cannot be directly targeted. Dead targets are excluded from projectile retargeting and repair healing.

## Pacing and geometry

Later waves include short spawn bursts, while the live-enemy cap remains 80. Distant newly spawned enemies are no longer automatically destroyed by basic weapons. The camera tracks the squad and the arena uses one scale for both axes, preserving movement speed, circular telegraphs and attack distances across aspect ratios. Smaller arenas scale units down; movement boundaries are marked. This does not certify every physical-device layout or frame rate.

Effect rendering stops accepting new impacts once the effects layer reaches 350 nodes. Missile and warning counts are bounded. Reduced Motion disables floating damage-number movement and particles; warning information remains visible. Existing particle, damage-number, sound and screen-shake preferences remain respected.

## Verification

[Final native validation](https://github.com/lanray07/Scrap-Squad/actions/runs/37172499986) passed Apple SDK compilation, 29 core tests, 13 tooling tests and all eight iPhone UI tests for source `2a2306418d78e6450d8b8b8f5f39d051ec6dd105`. UI cases took 268.911 seconds and include the new boss encounter, replay/rotation, fusion and StoreKit purchase/restore/refund flows. The unfiltered runner's Bash 3.2 empty-array issue was fixed before this successful run.

New core checks cover piercing alignment/exclusions/range, all nine dodgeable patterns, local engagement, delayed missile impact, drone orbit geometry, local lightning links, warning escape/damage and upgrade-time freezing. Existing seed equivalence, campaign completion, reward/save and cosmetic tests also passed.

[Compact-device validation](https://github.com/lanray07/Scrap-Squad/actions/runs/37172032601) passed two replay/rotation cases each on iPhone SE and iPad Pro 13-inch, on iOS 26.2. Times were 140.406 and 131.483 seconds respectively. That matrix used `0f9cbb7`; its camera, UI geometry and rendering are identical to the final release source. Final native validation also covers the subsequent dead-target selection fix.

Thirty-one genuine, unmodified captures and their provenance are recorded for [iPhone Pro Max](Combat/Captures/iPhone-Pro-Max/capture-provenance.json), [iPhone SE](Combat/Captures/iPhone-SE/capture-provenance.json) and [iPad Pro](Combat/Captures/iPad-Pro/capture-provenance.json). Inspected captures show the [boss warning](Combat/Captures/iPhone-Pro-Max/Combat-01-boss-encounter.png), [orbiting drones and Overdrive](Combat/Captures/iPhone-SE/Premium-06-overdrive.png), and [iPad landscape arena](Combat/Captures/iPad-Pro/Layout-02-landscape-combat.png). Each report records source, workflow, test, dimensions/orientation and SHA-256. Apple PNG orientation metadata is preserved.

Physical-device playtesting, FPS/thermal/battery profiling, VoiceOver/enlarged Dynamic Type, live Apple sandbox purchases and human balance feedback remain release checks. No measured retention or virality claim is made.

Compare challenge scores only between the same app build: these pre-release combat changes alter outcomes from build 7 even with an identical code and loadout. The seed protocol remains SQS1 because the game has not launched. A future released rules change must explicitly version score comparisons and challenge compatibility.

## Distribution

[Signed release run 8](https://github.com/lanray07/Scrap-Squad/actions/runs/37173028209) successfully uploaded version 1.0 build 8 from the verified source. [Apple API completion](https://github.com/lanray07/Scrap-Squad/actions/runs/37173348117) confirmed Apple processing and attached build 8, resource `33bdbcc9-e7cb-4b1e-8e99-5c3ed6c1d8b5`, to version 1.0. The first attachment attempt ran before processing completed; the subsequent check succeeded. The [non-sensitive status report](Combat/app-store-status.json) also verifies both cosmetic products, eleven product locales, prices, 173 regions and review screenshots. No App Review submission or release was performed.

The store gallery should be refreshed for the updated gameplay before submission. Physical-device performance, accessibility, balance playtests and live Apple sandbox purchases remain required checks in [RELEASE.md](RELEASE.md).
