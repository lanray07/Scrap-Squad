# iOS Salvage Operation — resubmission candidate

This is a substantive gameplay update prepared in response to Apple's guideline
4.3 feedback. It is not an assurance of approval. Keep the current rejected binary
out of a new submission; select the tested salvage build after physical acceptance.

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

## Verification record

Initial real-combat testing exposed excessive survival-style swarm pressure during
extraction. Mission-specific spawn pacing replaced the survival bursts and unrelated
events; the unchanged starter squad completion test then passed.

- Local Swift suite: 55 tests passed, including component damage/drop behavior,
  expiry/proximity, rebuild spending/replacement/trade-offs, escort/contestation,
  full real-combat extraction with no premium content, reward idempotency, old
  highlight decoding, challenge isolation and existing combat/cosmetic checks.
- Python tooling: 19 tests passed. English catalog audit passed (446 keys).
- Apple SDK compilation and iPhone/iPad simulator evidence: pending CI completion.
- Physical iPhone/iPad beta feedback on this new loop: not yet collected.
- Signed TestFlight build and final screenshot selection: pending native checks.

Do not claim external beta feedback, device performance measurements or a specific
competitor comparison without actual evidence. Retain the workflow URLs, source
commit and genuine XCTest screenshots alongside the final candidate record.

## Physical acceptance before App Review

Play a complete operation with a normal existing save on an iPhone and an iPad.
Confirm rescue/navigation, collecting each part type, unaffordable/affordable rig
controls, the visible rig and its combat trade-off, background/foreground during
rebuilding, extraction contested/clear/leaving behavior, defeat, retry, result
claim once, journal/share card, audio/motion preferences and premium finish
retention. Check the smallest supported display and large Dynamic Type as well.

Record tester, build/device, observed result, concrete feedback and fixes. Actual
human feedback is a separate release gate from automated QA.

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
