# Wave progression fix

Survival and Arena now continue numbering waves beyond six. Boss Rush stays active until three bosses are defeated, the squad dies or the player retreats. Scheduled bosses reserve one of the 80 enemy places, keeping the total within the limit without deleting enemies or granting free kills. Timed modes retain their two-minute deadline and six-wave cap; the minimum spawn interval remains 0.35 seconds.

The original engine failed three deterministic regressions. The corrected engine passes all seven wave tests, including a real three-boss victory, no spawning after victory, upgrade-choice freezing, deterministic spawning and the timed-mode deadline. All 39 core tests and 18 tooling tests pass locally.

Historical failure output and current passing output are in [WaveFix](WaveFix). Native Apple SDK validation and signed build delivery are pending.
