# iOS Salvage Operation — resubmission candidate

This is a substantive gameplay update prepared in response to Apple's guideline
4.3 feedback. It is not an assurance of approval. Keep the current rejected binary
out of a new submission; use the tested salvage candidate and its recorded validation scope.

## What changed

Battle now presents a dedicated **Launch salvage operation** entry. The former
Scrap Run mode becomes an objective-driven operation on iOS, with its own enemy
pacing rather than survival wave events:

1. Move to the disabled scout marked RESCUE SCOUT. Once rescued it follows the
   squad at escort speed. Moving too far ahead leaves the scout behind.
2. Select Emitter, Plating or Drive in the targeting strip. Automatic weapon
   hits damage that enemy subsystem. Its colored bar depletes and it drops a
   matching part. Broken emitters halve subsequent attacks; broken drives slow
   enemies; broken plating removes armor and ballistic shield mitigation.
3. Move over the colored parts to collect them before they expire. Recover at
   least three parts, including two of one kind for a rebuild.
4. Open Field rebuild. Combat and mission timers pause. Select a real squad
   member and install a rig using two matching parts:
   - Emitter: +30% squad damage, -10% movement.
   - Plating: -25% incoming damage, -15% firing rate.
   - Drive: +20% movement, -10% squad damage.
   Each robot carries one rig. Replacements consume new parts without refunds;
   effects stack across squad members. The arena adds visible barrels, a shield
   shell or skates over the existing robot art, including premium finishes.
5. Escort the scout into the extraction beacon and keep the area clear for
   twelve seconds. Both squad and scout must be present. Enemy occupation or
   leaving the zone drains progress. Successful extraction ends the operation
   and grants a single 100-scrap bonus through normal idempotent reward settlement.

The operation has the normal two-minute deadline; missing the extraction is a
failed operation. Regular campaign, survival, boss fights, crafting and paid
cosmetics remain available. All parts/rigs are run-local, earned through play,
and confer no permanent cosmetic entitlement. Results, journal entries and run
cards record recovered parts, rebuild count and extraction outcome.

## Compatibility and release isolation

- SwiftCore salvage is opt-in and only permitted for Scrap Run without a challenge
  code. Existing versioned SQS1 challenges and other modes retain their rules.
- Old saves decode without the optional salvage journal report. Existing squad,
  inventories, premium ownership and cosmetic rendering are retained.
- No Android, backend, signing, pricing, IAP SKU, premium art, music or sound asset
  changes are part of this update. Do not trigger an Amazon build or publication.
- The new strings are English source strings in the existing localization catalog.
  Unreviewed translations are not represented as supported app languages.

## Verification record - build 19, 23 October 2026

- Runtime source: `d4c093f27a4f6c00bf86c8dcfedf3dbf954ac262`.
- 56 Swift tests passed. A new out-of-arena drop test failed before the fix and
  passed after clamping drops to the reachable arena boundary; proximity is still required.
- 19 Python tooling checks and the English catalog audit (446 keys) passed.
- Dedicated salvage simulator QA passed: two tests each on iPhone and iPad,
  including actual collection, earned rebuilding, pause/rotation/retry and layout.
- Final build 19 full native regression passed: 23 UI tests, iOS compilation
  and premium screenshot export; see the linked workflow for diagnostics.
- Signed version 1.0 (19) archived, uploaded and processed by Apple successfully.
  Apple build ID: `9d64d969-ed76-401e-8884-d15601b297f0`.
- Installed through actual TestFlight update on the physical iPad (iPadOS 26.7).
  Assigned to the existing internal Scrap Squad QA group. No tester notification sent.
- Selected build 19 in the App Store draft. The review walkthrough and five-page
  build 19 evidence PDF are saved. No Update Review / App Review resubmission sent.
- [Signed build 19](https://github.com/lanray07/Scrap-Squad/actions/runs/39920264734)
- [iPhone/iPad salvage QA](https://github.com/lanray07/Scrap-Squad/actions/runs/39920269818)
- [Full native validation](https://github.com/lanray07/Scrap-Squad/actions/runs/39920267601)
- Amazon branch remains `e5d461e77911122ab36d0cbeb34bee9bda506882`.
  Protected premium art, signature rendering, audio, cosmetics and store configuration
  have no diff against the iOS base. No Amazon build or publication was triggered.

## Physical iPad acceptance

Automated touch controls exercised the actual TestFlight game with a normal existing
advanced save, four robots and Plasma Storm. No QA fixture, profile reset or direct
salvage inventory grant was used. This is device testing, not independent human beta feedback.

Two complete operations succeeded:

- Build 18: three recovered parts, an emitter rig on TANK, scout extracted at 1:10,
  36 kills, 12,600 score and the 100-scrap extraction bonus.
- Build 19: three recovered emitter parts, explicitly selected NOVA and installed
  its emitter (three parts to one), scout extracted at 0:42, 20 kills, 2,620 score
  and the 100-scrap extraction bonus.

Verified empty inventory controls disabled, installed control disabled, scout following,
paused rotation (clock stayed 0:31), extraction leaving/drain (17% to 0%) and return,
background/resume (paused at 0:11), retry resetting parts/rigs, journal and run-card
preview. Saved currency was identical across restart and the TestFlight update:
12,770 scrap / 22,887 credits / 19 cores before claiming further normal offline rewards.

Device testing found two issues, both fixed in build 19:

1. The landscape welcome reward sheet clipped controls. It now scrolls at full height;
   the actual corrected panel and claim button were checked on the device.
2. Enemies outside the playable area could leave unreachable parts. Drops now clamp
   to reachable boundaries, with red/green regression coverage and device boundary collection.

Genuine unchanged captures and SHA-256 provenance remain in
`output/ipad-physical-check/review-manifest.json`; the reviewer PDF is
`output/pdf/Scrap-Squad-iOS-Build19-Review.pdf`. The temporary signed USB control
helper and its temporary GitHub device secret were removed after testing. Game build
19 remains installed.

Physical iPhone testing, independent human beta feedback, new StoreKit transactions,
and performance measurements are not claimed. Starter-squad completion is covered by
core tests; the physical missions used the owner's advanced save. Before submission,
consider independent playtesting on the smallest supported device and accessibility settings.

## Proposed reply to App Review (send after candidate acceptance)

Thank you for the additional explanation. We have made substantial gameplay
changes to Scrap Squad rather than resubmitting the unchanged version.

The new Salvage Operation connects combat to robot reconstruction: players focus
fire on enemy emitters, plating or drives, recover the corresponding parts by
moving through the arena, and spend those parts to rebuild individual squad
members during the run. Each rig visibly changes the robot and applies a specific
benefit and drawback. Players must also rescue a disabled scout, escort it to an
extraction beacon, and defend the beacon before the mission deadline. This is an
objective-driven operation with its own pacing, not an additional cosmetic pack.

The review path is Battle > Launch salvage operation. Follow the RESCUE SCOUT
marker, recover parts, open Field rebuild, select a robot and install a rig, then
escort the scout to EXTRACT. Core gameplay needs no sign-in or purchase. Premium
appearance purchases are separate from the earned, temporary rebuild system.

We will provide the selected build number, genuine gameplay captures and the
completed test record with this submission. We understand that implementation
provenance alone does not establish distinctness under guideline 4.3, and offer
this changed gameplay for your assessment.

## Store description addition (draft)

SALVAGE. REBUILD. EXTRACT.
Break enemy systems to recover emitters, plating and drives. Turn those parts into
visible robot rigs with meaningful combat trade-offs. Rescue a stranded scout,
escort it across the arena and hold the extraction beacon before time runs out.
Every operation is a new build; your premium robot finishes stay yours.
