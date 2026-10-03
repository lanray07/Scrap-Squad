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

Final workflow outcomes, App Store product records and review screenshots are recorded here after verification. Nothing is submitted to App Review or released by this change.
