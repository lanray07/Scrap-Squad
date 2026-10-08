# iPhone Duo screenshot exports

Prepared 8 October 2026 for Scrap Squad version 1.0. `inner/` contains ten 2007×2853 portrait images; `outer/` contains ten 1398×2034 alternatives. Both conform to Apple's published Duo image dimensions. Each gallery contains the same ten campaign topics: bosses, workshop, squad, fusion, blueprints, city, daily challenge, overdrive, mastery and sharing.

These are **Duo-sized marketing layouts around existing genuine iPad simulator captures**, with the full original UI scaled proportionally. They are not captures from an iPhone Duo simulator or evidence of Duo device testing. The manifest records original capture hashes and final file hashes. No gameplay content was invented, stretched, repainted or removed. Headlines use the existing English storefront campaign.

The main version's English (U.K.) iPhone Duo slot receives the ten inner-display images in numbered order. Other language storefronts can inherit this English gallery, consistent with the game's English UI. The outer set is an alternative, not an additional ten images for the same ten-image slot. No app binary or review submission is changed.

Generate using Node.js with `sharp`: `node Tools/render_duo_screenshots.cjs`.

Apple specifications: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/
