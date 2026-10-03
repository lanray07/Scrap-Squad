# Cosmetic purchases

The user approved these suggested products on 3 October 2026. The app remains free; no subscription, consumable currency, power, robot unlock, progression or offline reward advantage is sold.

| Product | Product ID | UK base price | Included content |
| --- | --- | --- | --- |
| Founder’s Pack | `com.ScrapSquad.app.founder` | £2.99 once | Founder’s Gold BOLT finish, golden weapon trails, Founder badge in Squad |
| Robot Style Pack | `com.ScrapSquad.app.styles` | £1.99 once | Aurora BOLT, Cobalt TANK and Rose PATCH finishes |

Both are non-consumables. All content ships in the app. Finishes recolor the original robot art and add custom trim/decal accents; battle sprites use matching colors and decals. Robot availability still follows earned gameplay unlocks. Owners choose finishes in Shop and can return to the original appearance. The two Founder extras have independent switches. Reduced-motion and particle settings continue to apply.

StoreKit supplies localized names, descriptions and prices; the app does not use a hardcoded live price or offer a product Apple failed to return. Transaction signatures and product types are checked before ownership is granted. Pending/cancelled/unverified purchases grant nothing. StoreKit current entitlements restore ownership across launches. Refund/revocation removes access and clears the relevant selected cosmetics. Cosmetic preferences are saved separately from game progression. Restore purchases is an explicit user action using `AppStore.sync()`.

`localizations.json` records the eleven product display-name/description translations. The publisher's existing tax category is inherited, and Family Sharing remains off. Availability follows the app's 173 regions, excluding mainland China and Vietnam; automatic future-region expansion is off. A recurring Club remains a future proposal requiring ongoing content; it is not created or offered.

`UITests/Cosmetics.storekit` is a local Apple StoreKit test fixture, copied only into the UI-test bundle and referenced by the development run scheme. It is not used to supply fake products or entitlements to the distribution app. UI tests exercise purchases, selecting/removing finishes, persisted ownership/selections, restore and refund removal, and produce genuine review screenshots. The simulator test script uses installed iOS 26.2 and ad-hoc signing; the iOS 26.5 CLI runtime failed with the [Apple-reported StoreKitTest configuration regression](https://developer.apple.com/forums/thread/826971). Real App Store sandbox validation remains separate from local StoreKit testing.

## Verified outcomes

- [Native CI](https://github.com/lanray07/Scrap-Squad/actions/runs/37156023763): Apple SDK build, 16 core tests, 13 tooling tests and five UI tests passed. Both StoreKit test cases passed with genuine £2.99/£1.99 shop captures. Screenshot hashes, source attachment names, device and test identifiers are in `capture-provenance.json`.
- [Signed release run 5](https://github.com/lanray07/Scrap-Squad/actions/runs/37155902457): version 1.0 build 5 uploaded and processed. Release app source is the same as the tested source; later commits adapt only the simulator test setup and publishing tools/docs.
- [Metadata setup](https://github.com/lanray07/Scrap-Squad/actions/runs/37156476283) and [completion](https://github.com/lanray07/Scrap-Squad/actions/runs/37156627354): both product records, eleven localizations, exact UK base prices, 173 regions and review notes saved. Both actual review screenshots uploaded and processed. Build 5 attached and verified through Apple's API; `complete-status.json` records the results.
- App Store Connect's existing Paid Apps agreement is Active. No agreement, bank account or tax form was changed. The public privacy policy explains Apple-managed purchases and on-device transaction verification. The app declares UserDefaults reason `CA92.1` for its own preferences.

The app and both products remain in preparation, not submitted, approved or released. Complete real-device App Store sandbox/TestFlight checks before submission, including pending/Ask to Buy, cancellation and cross-device restore. The local tests do not certify Apple's live purchase environment.
