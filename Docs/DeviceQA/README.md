# Compact iPhone and iPad verification

Verified on 4 October 2026 through [GitHub's Xcode runner](https://github.com/lanray07/Scrap-Squad/actions/runs/37170958846), test source `49afe23`. The app source is unchanged from signed build 7; this update changes tests, tooling and documentation.

| Simulator | Runtime | UI cases passed | UI test time | Portrait display | Landscape display |
| --- | --- | --- | --- | --- | --- |
| iPhone SE, third generation | iOS 26.2 | 2 / 2 | 101.675 seconds | 750 × 1334 | 1334 × 750 |
| iPad Pro 13-inch | iOS 26.2 | 2 / 2 | 91.441 seconds | 2064 × 2752 | 2752 × 2064 |

Both devices completed onboarding, Hall of Scrap navigation, Daily Circuit deployment, earned Overdrive activation, retreat/results, genuine share-card preview, retry with an advancing combat clock and saved 2/3 mastery progress. A separate case rotated the city to landscape, opened mastery, deployed a challenge, used pause/retreat controls and rotated back to portrait for results. The initial run exposed test scrolling/timing assumptions and a timed upgrade interrupting Pause; the rerun handles those transitions without granting charge or bypassing gameplay.

Ten genuine PNG captures per device are stored in [iPhone-SE](iPhone-SE/capture-provenance.json) and [iPad-Pro](iPad-Pro/capture-provenance.json). Each provenance record contains the workflow, test, source filename, display dimensions, orientation and SHA-256. The original PNG bytes are preserved. Apple encodes landscape display orientation in EXIF; viewers must honor it. Tests use [Apple's full-screen screenshot API](https://developer.apple.com/documentation/xcuiautomation/xcuiscreen) to avoid cropping a rotated application's bounding box, and assert landscape display dimensions. These are QA captures, not replacements for the already uploaded premium store campaign.

Selected inspected views:

- [Compact landscape combat](iPhone-SE/Layout-02-landscape-combat.png)
- [Compact landscape pause controls](iPhone-SE/Layout-03-landscape-pause.png)
- [Compact run card](iPhone-SE/Premium-04-share-card.png)
- [Compact saved mastery](iPhone-SE/Premium-05-saved-records.png)
- [iPad landscape combat](iPad-Pro/Layout-02-landscape-combat.png)
- [iPad landscape pause controls](iPad-Pro/Layout-03-landscape-pause.png)

The 375-key English localization audit and all 13 tooling tests also passed locally. The earlier full native validation remains the evidence for 22 core tests and purchase/restore/refund coverage; this matrix runs only the two replay/layout cases on each device.

These checks do not certify physical-device frame rate, battery, thermal behavior, listening quality, VoiceOver, enlarged Dynamic Type, split view, reviewed translations or live Apple sandbox purchases. The small landscape arena has less movement space; normalized arena geometry and combat/progression balance still need physical-device playtests. Build 7 remains attached in App Store Connect. No review submission or release occurred.
