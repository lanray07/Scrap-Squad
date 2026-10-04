# Wave review — build 11 engine

These historical findings are now fixed in the engine. See [wave fix verification](WAVE_FIX.md) for regression tests and delivery status.

Five deterministic tests exercised the actual BattleEngine. Two passed and three exposed defects. The [reproduction source](WaveReview/WaveReviewTests.swift) and [results](WaveReview/results.log) are saved. Production gameplay was unchanged during this review.

## Confirmed findings

1. **Boss Rush can award victory after one boss.** The general timed-run completion branch also applies to Boss Rush. At 120.05 simulation seconds, a fixture with exactly one defeated boss entered `victory`, despite the three-boss rule and player-facing text. Exclude Boss Rush from timed-run victory, or define an explicit timeout outcome that cannot award a three-boss victory.
2. **Endless modes stop advancing at Wave 6.** `wave` is capped at six for every mode. Survival and Arena remained fighting at 150 seconds but displayed six instead of eight. Timed modes can retain their six-wave cap; endless numbering should continue while preserving the spawn-rate lower bound.
3. **Boss spawning can exceed the 80-enemy limit.** Regular spawning checks the count, but the scheduled boss appends unconditionally. The test observed 81 live enemies around the 65-second boss arrival. Reserve a slot or prioritize boss admission while preserving the total limit.

## Passing behavior

- Normal waves progressed from one through six at twenty-second simulation intervals. Spawning continued and identical seeds produced identical enemy-ID sequences.
- Upgrade choice froze the timer, wave and enemy count; selecting an upgrade resumed combat.
- Waves are timed pressure phases and allow overlapping enemy groups. They do not wait for the previous group to be cleared.

## Reproduction and scope

Tests use seed 42 and bundled content through the actual engine. High health keeps fixtures alive, zero damage retains enemies to expose capacity and elapsed-time defects, and a strong but very slow weapon isolates exactly one Boss Rush kill. These fixtures are not production balance proposals. The upgrade-pause case uses unmodified content.

Command: `swift test --scratch-path C:/Users/User/ScrapSquadMovementBuild --filter waveReview`. The five-case execution took 1.365 seconds: two passed and three failed, with four expectation failures because both endless modes were checked. Review reproductions are archived outside the normal test target so expected failures do not break release CI.

To repeat, copy the reproduction file into `Tests/ScrapCoreTests`, run the command, then move it back. Convert the three findings into permanent passing regressions when implementing fixes. This engine review does not certify device difficulty or frame performance.
