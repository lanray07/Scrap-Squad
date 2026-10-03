# Original art assets

Generated using the built-in imagegen tool on 3 October 2026. No competitor imagery was used. Both selected images are copied into this repository; the app does not depend on the generator’s private output directory.

| Asset | Purpose |
| --- | --- |
| `App/Resources/RobotAtlas.png` | Transparent 4×2 robot sheet, used by native character cards and SpriteKit squad sprites |
| `Art/AppIcon-source.png` | Original full-bleed BOLT app icon. The Mac build uses `sips` to prepare the required 1024px catalog image |

Atlas order: BOLT, TANK, ZIP, PATCH across the top; NOVA, BOOMER, GLITCH, MAGNET across the bottom. Each runtime texture uses one quarter of the width and half the height. The atlas is inspected, but per-cell silhouette cropping, alpha edges and small-scale readability still require device review. There are no frame-by-frame character animation states yet.

## Atlas generation prompt

Use case: stylized-concept. Asset type: transparent native mobile game sprite atlas for original Scrap Squad: Merge & Survive. Create ONE landscape PNG sprite sheet, precisely a 4-column by 2-row grid of eight equally sized cells, transparent background with no grid lines, no lettering, no names or captions. Exactly one full-body original toy-like robot centered within each cell, each robot entirely inside its cell with generous 15% empty padding, no overlap. Premium stylized 3D game render, charming expressive cyan eyes in dark visor, improvised salvaged machinery, bold readable silhouettes, soft studio lighting, each facing camera in a three-quarter slightly top-down view with feet visible, no shadows beyond cell. Top row left to right: BOLT small round mustard yellow cheerful robot with single antenna and rivet blaster; TANK broad heavy blue-grey robot with thick arms and treads and oversized cannon; ZIP slim mint-green fast robot on spring legs with electric prongs; PATCH coral-pink rounded medic robot with a white plus symbol on chest and repair tool. Bottom row left to right: NOVA spherical lavender energy robot with luminous chest core and small laser arm; BOOMER chunky orange explosives robot with twin small rocket tubes; GLITCH narrow cyan asymmetrical hacker robot with angular antenna and glowing visor; MAGNET olive green round salvage robot with horseshoe magnet backpack and claw hands. Consistent camera, scale, material, visual identity, glossy painted metal with subtle scratches and dark mechanical joints. Family-friendly original characters. No franchise resemblance, no watermark. This is a usable game sprite atlas, not a poster or UI concept. Actual transparent alpha background.

## App icon generation prompt

Create a native iOS mobile game app icon for Scrap Squad: Merge & Survive, using the mustard yellow BOLT robot in the top-left of the referenced sprite atlas as the exact character identity. Only that single cheerful round golden robot, close-up portrait, expressive cyan happy eyes inside a dark visor, single gold-tipped antenna, salvaged metal with subtle scratches, oversized rivet blaster visible at lower left. Premium stylized 3D toy robot, extremely readable at tiny icon sizes. Square 1024x1024 image, full-bleed dark teal background with subtle warm workshop lighting. Center character with room for the antenna. No lettering, no other robots, no border, no rounded corners (iOS applies its own mask), no transparency, no watermark. Keep original character silhouette and color from top-left reference, friendly energy and strong contrast.

The icon request used the atlas as an identity reference. The tool produced a larger square source; resizing is part of build packaging. Background/environment assets, enemies, weapon-specific effects, production music and animation clips remain an explicit art backlog.
