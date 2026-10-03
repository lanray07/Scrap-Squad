# Campaign verification — 3 October 2026

[Native build and screenshot run](https://github.com/lanray07/Scrap-Squad/actions/runs/37149982000) passed on source commit `34aa70ee6da14977610a7feb95815a03b9a1a022`.

- Unsigned iOS Simulator app compiled with Xcode on GitHub's Mac runner.
- 14 core tests and 12 localization-tool tests passed in CI.
- All 3 UI tests passed; the ten-screen capture tour completed in 41.7 seconds.
- All 10 export PNGs passed 1320 × 2868 dimensions and no-alpha checks.
- Contact sheet and individual image layout reviewed for copy clipping and capture fidelity.
- Raw captures, editable SVGs and SHA-256 provenance are included alongside the exports.

[Download the GitHub screenshot artifact](https://github.com/lanray07/Scrap-Squad/actions/runs/37149982000/artifacts/11283442858).

[Automatic translation run](https://github.com/lanray07/Scrap-Squad/actions/runs/37149076300) also passed: 3,080 machine drafts across ten locales. All drafts pass current-source, placeholder/name and non-empty checks. The latest local test suite passes 13 tests, adding long printf-format coverage after the CI snapshot.

Store description and metadata drafts exist for eleven locales, with App Store field limits validated. Keyword demand and conversion are not measured. Native-language quality review is still required; production app translations are not enabled or falsely marked approved.

This verifies the marketing asset pipeline and current development build, not production readiness or a signed device/TestFlight release. No App Store Connect publishing was performed.
