# Initial economy

Source of truth: `Sources/ScrapCore/Resources/content.json`, authored by `Tools/author_content.py`.

| Resource | Sources | Sinks |
| --- | --- | --- |
| Scrap | 5 per defeated machine; doubled in Scrap Run; daily 60-kill task +200; dock 2/minute/level with zone multiplier | Weapon fusion, weapon levels, city construction |
| Credits | 3 per machine; +250 per boss; weekly three-boss task +900; dock 4/minute/level with zone multiplier | Robot rescue and levels |
| Cores | Starter 3; +1 per successful mission; +2 per weekly task | Roulette consumes one core and two distinct weapons |
| Components | Starter pack; two of a deterministic rotating component on successful runs | Data-driven weapon recipes |

Starting grants are real inventory: 350 scrap, 500 credits, 3 cores, basic weapons and components. No rewards are fabricated from an unmeasured absence.

Upgrade prices use `ceil(base × 1.35^level)`. Robot level base cost is 100 credits, maximum level 50. Weapon level base cost is 80 scrap, maximum level 30. Buildings use individual base costs and maximum level 10. Reboot at zone 6 resets the listed city/robot progression, retains collection and grants +10% damage per reboot.

Offline accumulation requires a built dock and caps at eight hours. Dock rate changes settle income at the old rate before construction; past time cannot be credited at a newly purchased rate. Local wall-clock rollback does not produce negative rewards or move the checkpoint backwards.

Campaign difficulty multiplies enemy health by `1 + zoneIndex × 0.28` and modestly increases swarm health during a run. Boss weakness grants +75% damage. Armor takes incoming damage while passing 45% to the boss; breaking it unlocks full incoming damage. Phase two accelerates telegraphed attacks. This is a starting curve for playtesting, not a validated lifetime economy.
