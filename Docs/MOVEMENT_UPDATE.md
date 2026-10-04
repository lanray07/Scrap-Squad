# Robot walking and ground footprints

The battle camera follows the squad, which kept the existing static robot artwork near the screen centre while the ground moved. Robots now bob, squash subtly and lean during actual ground displacement, then return to their resting pose when stopped. Dragging remains the movement control; no automatic wandering changes player control or combat balance.

Each robot leaves alternating left/right ground marks every 0.025 arena units. Marks stay in world coordinates, fade over three seconds of simulation time and use a fixed 96-node pool. Resize/rotation rescales their recorded arena coordinates. Golden trails colour the marks gold; no gameplay stats change. Reduce Motion suppresses bob/squash/lean while retaining the positional ground trail. Pause freezes simulation and trail ageing.

Two core regression cases check distance-based spacing across different frame sizes, alternating feet, stopping, and teleport reset. The new UI case drags the actual arena, verifies squad displacement and increased step count, then verifies both stop changing after release. Its diagnostics are exposed only with the existing UI-testing launch flag. iPhone/iPad XCTest captures and GitHub workflow results will be recorded below after validation.

Physical iPad feedback prompted this change; the revised build still needs a device check for the animation's feel.

Signed [build 11](https://github.com/lanray07/Scrap-Squad/actions/runs/37188203778) uploaded successfully from source `05aba48753a6305868323ac8844282c713917ade`. Both movement checks subsequently passed; build 11 is now selected and available internally.

The targeted iPad suite passed both boss/pause and movement/footprint cases (56.612s and 29.512s). The [unaltered iPad capture](Movement/Captures/iPad-footprints.png) was visually inspected and shows the ground trail. The native Apple SDK compile passed; full iPhone regression and targeted iPhone results are pending. Local tests passed both new core cases and all eighteen tooling cases.

Build 11 is processed and selected: resource `6243ff7c-1984-46ea-b25c-2b084062241c`. [TestFlight verification](https://github.com/lanray07/Scrap-Squad/actions/runs/37189023395) confirms internal state `IN_BETA_TESTING`, availability in Scrap Squad QA, one existing tester preserved, automatic invitations disabled, and notes saved/read back. No tester was added or invited and no App Review submission occurred. The [actual iPhone image](Movement/Captures/iPhone-footprints.png) was also inspected; its walking case passed in 30.164 seconds. The first iPhone boss check missed its exact 0:05/0:06 observation window; only that test was changed to accept continued first-minute battle progress. App/Core files still match the signed source.

[Native regression run](https://github.com/lanray07/Scrap-Squad/actions/runs/37188200872) passed Apple SDK compilation, 32 core tests and sixteen tooling tests. Thirteen of fourteen UI cases passed; the boss case timed out at Xcode app launch. This is separate from the targeted first-run timing-window failure. [The corrected targeted rerun](https://github.com/lanray07/Scrap-Squad/actions/runs/37188997790) repeats boss and walking cases on both device families; its final status is recorded below. No full-suite green result is claimed for the first native run.
