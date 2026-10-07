# Scrap Squad player beta

Prepared 7 October 2026 for version 1.0, build 15. This is a testing plan, not a claim that testing has taken place. The App Store rejection remains unresolved; this beta does not resubmit the App Store version.

## Cohort and schedule

Recruit 5–10 willing adults, including at least two iPhone and two iPad users, a mix of survivor-game players and newcomers, and an older supported device if available. External access requires Beta App Review approval. Do not give players developer-account access. Keep invitations private; do not enable an unrestricted public link.

Ask each person for three 15–20 minute sessions over three days. Let the first five minutes be unprompted: record where they get stuck before giving the walkthrough. Returning for later sessions is voluntary. Ask which moment made them want to return and which made them stop.

Use anonymous tester IDs in the repository. Keep invitation emails in App Store Connect, not this repository. Ask for gameplay screenshots or clips without personal notifications, Apple IDs or payment details. Feedback should go through TestFlight's Send Beta Feedback; a screenshot plus exact reproduction steps is preferred.

## Session 1: first impression, crafting and movement

1. Install build 15 through TestFlight. Record device, OS and whether this is a fresh install or update. Do not delete an existing install solely for this test: progress is stored locally.
2. Complete onboarding unaided. Report the first confusing instruction or button.
3. City > Open Workshop: fuse Basic Blaster + Fire Core, equip Flame Blaster, then Battle > Deploy squad. Confirm the equipped weapon changes combat visibly.
4. Drag in several directions, stop, turn, dash and use Ability. Check robot movement/footprints follow movement rather than staying static. Repeat with Reduce Motion enabled; distinguish intentionally reduced effects from broken movement.
5. Pause/resume, open an upgrade choice, briefly background the app, then return. Report any combat or timer progression while paused or awaiting resume.
6. Rate control responsiveness and clarity from 1–5, with one concrete example for each rating.

## Session 2: waves, challenge and replay

1. Play Survival or Arena long enough to pass wave 6 if possible. Record the highest wave, elapsed time and outcome; report stalled numbering, invisible enemies, sudden unavoidable damage or spawn problems. Failure to survive is not automatically a defect.
2. Try Boss Rush when accessible. A successful finish must require three defeated bosses; report premature victory or a run that does not finish after the third defeat.
3. Try different upgrades and a weapon evolution when available. Describe how it changes the decisions you make, not just its appearance.
4. Share a Daily Circuit code with another tester and compare displayed challenge/loadout. Record the code and any mismatch. There is no server leaderboard; local result-card sharing is optional.
5. Ask: What felt distinctive? Which other game did this remind you of, and exactly why? What one change would make you choose this game again? Do not coach positive answers.

## Session 3: cosmetics, persistence and purchases

1. Shop > Signature collection > Try in the arena. Confirm preview combat works and returning does not save preview rewards or grant ownership.
2. Confirm the offer clearly states what is included, that it is cosmetic, and that it is a one-time purchase. Note clipped text or unclear prices on either device.
3. Optional TestFlight purchase test: proceed only if the Apple purchase sheet clearly identifies the test/sandbox environment and says the purchase will not be charged. If a charge is indicated or the environment is unclear, cancel and report it. Never provide payment credentials to the developer.
4. Cancel once: nothing should be granted. If testing a successful transaction, verify the cosmetic can be equipped, remains owned after relaunch, and Restore Purchases reconciles ownership. Where available, test another device with the same test account without sharing credentials.
5. Owning Signature Collection should grant its four components and prevent duplicate individual purchases. Owning a component should block the overlapping bundle. Classic packs are separate. TANK/PATCH gameplay unlocks still apply.
6. Relaunch and check ordinary progression/equipment persistence. Report crashes, stutter, excess heat and battery concerns with device and approximate session length; do not infer FPS from impressions.

## Feedback and release decisions

Use FEEDBACK_TEMPLATE.md and feedback.csv. Keep raw observations separate from developer interpretation. Each applied fix needs an issue ID, before/after behavior, commit, tested build and retest result. Automated tests support evidence; they do not substitute for player feedback.

Proposed beta completion criteria: at least five actual participants, coverage of both device families, all critical journeys attempted, no unresolved crash/data-loss/purchase-entitlement defects, and a documented fix/retest for each accepted high-priority issue. If recruitment or survival limits coverage, report the gaps explicitly rather than marking them passed. Numbers are planning targets, not evidence of completion.

Prepare an Apple evidence summary only after testing: actual participant/device counts, specific feedback, resulting changes, new build number and consented gameplay examples. Do not claim this beta resolves guideline 4.3 on its own. Await Apple's clarification before deciding whether substantial gameplay changes or an evidence-backed appeal are appropriate.
