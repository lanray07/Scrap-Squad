# Build 15 device and sandbox acceptance

Version 1.0 build 15 is processed and available to the internal **Scrap Squad QA** group. One existing tester is present; this update preserved membership and did not add or invite anyone. An App Store Connect administrator can select their own existing team account in TestFlight → Internal Testing → Scrap Squad QA → Add Testers, then install through TestFlight on their device. External beta review is not required for internal testing. Never share a password or Apple verification code with this repository.

## Record the actual device result

For each test, record device model, OS version, build, date, result and any reproduction steps. A simulator pass does not count as a physical-device pass. Do not mark a row passed before observing it.

| Check | Device procedure | Current evidence |
| --- | --- | --- |
| Signature Collection | Preview battle/victory poses, purchase/equip/remove each skin and Prism, restart, restore and refund. Component owners must not see a bundle buy button; bundle owners must not be offered components again. Check locked robots stay locked and combat stats unchanged. | Three StoreKit preview/purchase cases pass on each iPhone/iPad simulator; live Apple sandbox and physical acceptance pending |
| Combat excitement | Dash after steering in each direction; try a last-moment boss dodge; complete each of the three two-module recipes; clear/fail each event and check bonus scrap once at results. Rotate and pause during dash, event and artillery countdowns. Retry must clear evolution. | Eight new core tests and all four new cases pass on iPad and iPhone simulators (iPhone event case passed on corrected rerun); physical acceptance pending |
| Wave progression | Survival/Arena past 150 seconds should show Wave 8. Boss Rush must require three defeated bosses; taking longer than two minutes must not award an early victory. Upgrade choices and Pause must freeze progress. | Seven deterministic engine tests pass; physical acceptance pending |
| Full player path | Fresh install → tutorial → mission → three upgrade choices → boss → rewards → Workshop → fusion → equip → blueprint → city upgrade → relaunch. Verify currency and ownership persist. | Individual core/UI paths verified; physical end-to-end pending |
| Touch and orientation | Drag the squad to all arena boundaries, rotate portrait/landscape during battle, pause and results. Check ability and Overdrive controls remain reachable. On iPad try supported multitasking window sizes. | Compact/iPad rotation simulator checks passed; physical and multitasking pending |
| Accessibility | Enable VoiceOver and the largest text size. Navigate onboarding, city, Settings, Workshop, Shop, journal, results and share preview. Check labels, order, focus, readable values and reachable buttons. Enable Reduce Motion and reduced flashes; inspect combat warnings. | Automated audit and enlarged-text results recorded separately; manual assistive testing pending |
| Lifecycle | Background an active battle, lock/unlock and return. Combat must remain paused until Resume. Check music stops in the background and restarts appropriately. Force quit after a completed run and verify its record and rewards remain. | Automated background pause test recorded separately; device interruption checks pending |
| Sound | Listen to city, battle and boss loops on speaker and headphones. Adjust each volume slider, check silent switch, pause/background and incoming audio interruption behavior. | Original bundled assets; physical listening pending |
| Performance | Run a 15-minute Survival session on the oldest available supported device and iPad, using missiles, drones, lightning and dense waves. Record stutter, temperature, battery before/after, crashes and memory warnings. Use device Instruments for frame time, CPU, memory and energy when a Mac is available. | Bounded core stress simulation recorded separately; physical FPS/energy pending |
| Progression and balance | Complete each campaign biome and sample all seven modes. Record time to first fusion, boss success/failure, upgrade clarity and whether warnings leave enough reaction time. Replay the same code/loadout on the same build. | Core campaign/determinism tests; human difficulty and progression feedback pending |

## Apple sandbox purchases

TestFlight purchases use Apple's sandbox and do not charge testers. Verify that the purchase confirmation identifies the test environment. If it appears to be a production charge, cancel and check that the installed app came from TestFlight. See [Apple's TestFlight purchase testing guidance](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testing-subscriptions-and-in-app-purchases-in-testflight).

1. Open Shop online and confirm real Apple product names and localized prices load for the seven products across Classic packs and Signature collection.
2. Cancel a purchase; no ownership or cosmetic should be granted.
3. On a clean test account, purchase the Signature bundle or its separate components; overlap protection prevents buying both. Test the two Classic packs too. Equip every included finish, Prism, gold trails and badge where available. Gameplay stats must remain unchanged.
4. Relaunch and verify ownership and selected cosmetics. Go offline and verify previously verified ownership remains usable; reconnect and refresh.
5. Use Restore Purchases on another device signed into the same testing account. Verify the actually purchased products return, bundled components remain owned and no duplicate charge is requested.
6. With a dedicated Sandbox Apple Account configured according to Apple's documentation, test interrupted purchases and pending/Ask to Buy where supported. Pending transactions must not grant ownership; a subsequently verified completed transaction must deliver it.
7. Test refund/revocation using the appropriate Apple sandbox controls when available. Refresh/relaunch and verify revoked cosmetics return to the original finish and unavailable toggles are disabled.

The local StoreKit configuration has passed purchase, persistence, restore and refund UI tests. Local approval/decline and interrupted-delivery scenarios are covered too. Those results do not certify live Apple sandbox approvals, cross-device restore or service outages. Never put sandbox account credentials or transaction receipts in public issues, captures or workflow artifacts.

## Completion gate

The refreshed store galleries and automated release evidence are saved separately in the release report. Physical acceptance, live sandbox results and language-quality review remain pending until real results are recorded. Larger master-prompt features still listed in [RELEASE.md](RELEASE.md) are future product work, not completed features. App Review submission and public release are separate actions.
