# Combat excitement update

Three run-only evolutions now unlock through actual upgrade choices. The opening choice introduces Fire Core, Tesla Coil or Explosive Payload; the next offer guarantees an available partner for that path. Recipe progress and effects are described on the choice cards. One evolution can be earned per run, and retry starts without it.

| Evolution | Recipe | Actual attack |
| --- | --- | --- |
| Fire Vortex | Fire Core + Overclock Module | Three orbiting fire areas burn nearby enemies; damage pulses every 0.45 seconds |
| Storm Cage | Tesla Coil + splitting module | An electric ring damages and slows enemies every 0.85 seconds |
| Siege Barrage | Explosive Payload + Critical Processor | Up to three marked artillery strikes per volley, with a 0.65-second delay and 1.8-second volley interval |

Dash moves in the last steering direction, or upward before the first movement. It travels up to 0.264 world units over 0.22 seconds, respects arena bounds and has a four-second cooldown. Damage is blocked while dashing. Escaping a warning that had at most 0.30 seconds remaining earns one perfect dodge when that warning actually resolves outside the squad's position, granting +30% damage for three seconds. A dash into an arena boundary with no useful travel is refused without consuming cooldown.

Wave events start at 28 seconds, then at 30-second intervals. The seed determines a rotating order of elite ambush, scrap storm and treasure carrier, using a separate random stream. Boss Rush retains its dedicated three-boss encounter. Events use the existing 80-enemy and 48-warning caps. Defeat the marked elite squad within twelve seconds for 60 scrap; survive an eight-second scrap storm for 40; destroy a fleeing carrier within twelve seconds for 40. Expired carriers disappear without granting kills or rewards. Bonuses are credited by the existing idempotent run-claim path.

Dash, warning deadlines, event countdowns, evolution pulses and artillery all use simulation time, which freezes during upgrade selection and pause. Effects preserve the existing particle, shake, sound and haptic preferences. Evolved attack areas stay visible because their geometry is gameplay information. Recipe/status/result copy uses nineteen new English catalog keys. New optional run-history fields retain compatibility with older saves and include evolution/perfect dodges on share cards.

Eight new core tests cover unlocks and real damage for all three evolutions, delayed artillery, a real boss perfect dodge, dash bounds/cooldown, paused timers, all three event types, actual elite/carrier rewards, duplicate-claim protection, deterministic replay and older run decoding. Four UI cases use normal content and normal event/upgrade timing; an explicitly opted-in test fixture supplies extra robot health and seed 42 without granting evolutions or event rewards.

Native Apple SDK verification, iPhone/iPad UI captures and signed delivery are pending. Physical-device balance, sound and performance acceptance remain necessary. Additional boss parts, robot roles and branching encounters are future work; this update implements the three priorities proposed for the first combat pass.
