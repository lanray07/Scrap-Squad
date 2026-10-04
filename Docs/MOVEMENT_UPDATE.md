# Robot walking and ground footprints — build 11

Build 11 is uploaded, processed, selected and available in the existing **Scrap Squad QA** TestFlight group. Update through TestFlight, then drag inside the arena. The camera follows the squad; robots now bob, subtly squash and lean during movement, and leave an alternating trail on the ground. They return to a resting pose when you release your finger. This is procedural motion of the existing robot art, rather than new individually rigged leg animation. Combat balance and drag controls are unchanged.

## Behavior

Footprints follow actual displacement every 0.025 arena units, rather than input or frame rate. They stay in arena coordinates, rescale with the scene and fade over three seconds of simulation time. A fixed pool of 96 nodes bounds the trail's memory and node count. Pause freezes simulation and trail ageing; stationary robots and teleport resets produce no new steps. Golden trails colour the marks gold. Reduce Motion suppresses bob/squash/lean while retaining the positional trail.

[Actual iPad capture](Movement/Captures/iPad-footprints.png) and [actual iPhone capture](Movement/Captures/iPhone-footprints.png) were visually inspected. Source hashes and test provenance are saved beside them. The signed app's source is `05aba48753a6305868323ac8844282c713917ade`; subsequent changes are tests, release tooling and documentation.

## Verification

- Two new local Swift regression cases passed for frame-size-independent spacing, alternating feet, stopping and teleport reset.
- [Native Xcode validation](https://github.com/lanray07/Scrap-Squad/actions/runs/37188200872) passed Apple SDK compilation, 32 core tests and sixteen tooling tests. Thirteen of fourteen UI cases passed; the boss case hit an Xcode application-launch timeout.
- [Initial targeted checks](https://github.com/lanray07/Scrap-Squad/actions/runs/37188201808) passed walking on both families and boss/pause on iPad. The iPhone boss test missed its old exact 0:05/0:06 clock window. Only the test predicate was changed to accept continued first-minute progress.
- [Corrected targeted verification](https://github.com/lanray07/Scrap-Squad/actions/runs/37188997790) passed both boss/pause and movement cases on both families. The movement test confirms actual horizontal squad displacement, increased step count, then stable position/count after release. Combined with the thirteen native passes, all fourteen unique iPhone UI cases have passing evidence on unchanged app code. The initial native run remains recorded as thirteen/fourteen, without claiming a single full-suite green run.
- All eighteen current Python tooling tests passed locally, including notification-disable confirmation and idempotent internal build attachment.

## Distribution

[Signed build 11 upload](https://github.com/lanray07/Scrap-Squad/actions/runs/37188203778) succeeded. [Apple attachment](https://github.com/lanray07/Scrap-Squad/actions/runs/37188979347) confirms build resource `6243ff7c-1984-46ea-b25c-2b084062241c` is processed and selected.

[TestFlight verification](https://github.com/lanray07/Scrap-Squad/actions/runs/37189023395) confirms `IN_BETA_TESTING`, group availability and exact saved notes. The existing tester was preserved; no account was added or invited. Automatic invitations are disabled on this build. No App Review submission or public release occurred. Store galleries retain their genuine build-10 source manifests; the cosmetic movement change does not change their advertised feature counts.

Your iPad feedback prompted this change. Physical-device feel, FPS, heat/battery and manual assistive checks on the revised build still need device observation. See the [device checklist](TESTFLIGHT_QA.md) and [recorded verification](Movement/verification.json).
