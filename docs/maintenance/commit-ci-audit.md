# Commit CI Audit Ledger

Persistent repository-specific record of commit-level CI checks and red-cross investigations.

## How to use this ledger

1. Read this file before auditing commit checks.
2. Check only commits newer than the checkpoint, plus older **red**, **pending**, or explicitly unresolved entries.
3. Record exact commit SHAs and observed results; never infer from missing badges or empty API responses.
4. Preserve failures and append diagnosis, fix, rerun, and final-outcome evidence.
5. Advance the checkpoint only after reviewing the range; carry unresolved entries forward.

## Result meanings

| Result | Meaning |
|---|---|
| **green** | Completed successful check/run directly observed. |
| **red** | Completed failing check/run directly observed. |
| **pending** | Check/run exists but is unfinished. |
| **unavailable** | Available evidence did not expose a result; not a pass or failure. |
| **not applicable** | Workflow configuration confirms no relevant check is triggered. |

## Checkpoint

- Repository: `SakibShahariar/adwisp`
- Default branch: `main`
- Reviewed checkpoint SHA: `400f463b87b6e4c8e0e637a16190193ab3b0492d`
- Reviewed: 2026-11-06
- Range reviewed: `107549915369fa46dab2c2bceab25b2102f820f8` through `400f463b87b6e4c8e0e637a16190193ab3b0492d`
- Result: five commits in this range have successful exact-SHA CI runs; one test-only commit failed and was corrected by a later green commit; the documentation-ledger commit remains pending.
- Outstanding: workflow run [42261670543](https://github.com/SakibShahariar/adwisp/actions/runs/42261670543) for `522dba926fddb34463d38061281b4cad2e8f644d` is still in progress at **Set up Lua**. Its logs are not available yet. Treat it as pending, not green.
- Next session: recheck the pending run above before unrelated work; retain all red and pending entries below.

## Reviewed commits

| Commit SHA | Subject | CI result | Run |
|---|---|---|---|
| `107549915369fa46dab2c2bceab25b2102f820f8` | docs: improve maintenance workflow guidance | green | [41400960986](https://github.com/SakibShahariar/adwisp/actions/runs/41400960986) |
| `e09de491df02353d121a64acb7f7afea2bde584b` | docs: add persistent commit CI audit ledger | green | [41456854075](https://github.com/SakibShahariar/adwisp/actions/runs/41456854075) |
| `4102918ae4b9f882c2152bc9dd21112b9a55ceab` | docs: document incremental commit CI auditing | green | [41456860452](https://github.com/SakibShahariar/adwisp/actions/runs/41456860452) |
| `37f785d2f5a83fb2f98ae47ba6eb20d5bc4a062f` | docs: define issue triage categories | green | [41573553602](https://github.com/SakibShahariar/adwisp/actions/runs/41573553602) |
| `0fcf79051d4cbea5f73a452780ac22b2db7b4ab3` | docs(agents): define administrative commit hygiene | green | [41597851576](https://github.com/SakibShahariar/adwisp/actions/runs/41597851576) |
| `1cd6cd2d1100fcae87e63f60394decb2976ef9f2` | docs(agents): clarify acceptance criteria evidence | green | [41864174877](https://github.com/SakibShahariar/adwisp/actions/runs/41864174877) |
| `cbe3bd1273c14abc7d86a6eaf87e4a34e77296ad` | docs(theme): clarify Matugen integration and fallback behavior (#43) | green | [42206649204](https://github.com/SakibShahariar/adwisp/actions/runs/42206649204) |
| `9c8ac16ec6a04dd842c18f4ffad4840f30b83d49` | perf(render): cancel superseded playback timers (#42) | green | [42206955176](https://github.com/SakibShahariar/adwisp/actions/runs/42206955176) |
| `522dba926fddb34463d38061281b4cad2e8f644d` | docs(ci): record historical failure resolutions | pending | [42261670543](https://github.com/SakibShahariar/adwisp/actions/runs/42261670543) |
| `44ee59a6147118560c59017c27122389e12c018e` | perf(input): preserve pointer cache during playback updates (#10) | green | [42261839590](https://github.com/SakibShahariar/adwisp/actions/runs/42261839590) |
| `21ffaa1b7843608d0ac8d9567016eea98be7c431` | test(input): cover playback pointer-cache invalidation (#10) | red; corrected | [42261870546](https://github.com/SakibShahariar/adwisp/actions/runs/42261870546) |
| `2ee79b9248c3a2be280fbb5d7a11bc1200f46846` | test(input): restore fixture duration after cache check (#10) | green | [42261991020](https://github.com/SakibShahariar/adwisp/actions/runs/42261991020) |
| `d27516ae4f85f3d857b03d326b3e14978f662714` | ci(release): run the BMP regression suite (#17) | green | [42262047858](https://github.com/SakibShahariar/adwisp/actions/runs/42262047858) |
| `c423e4e157cac2d633207d47e84f8544416bcdc7` | test(release): verify every packaged core module (#17) | green | [42262262002](https://github.com/SakibShahariar/adwisp/actions/runs/42262262002) |
| `400f463b87b6e4c8e0e637a16190193ab3b0492d` | fix(release): print archive entries on separate lines (#17) | green | [42262292533](https://github.com/SakibShahariar/adwisp/actions/runs/42262292533) |

## Historical red-cross investigation

These failures predate the checkpoint above. They were discovered by inspecting the actual workflow jobs and logs, not inferred from commit badges.

| Failed commit SHA | Run / failed step | Observed failure | Resolution evidence |
|---|---|---|---|
| `2dd1c7aeb02781ef44b81d3161c0ecbb409424f3` | [41148259375](https://github.com/SakibShahariar/adwisp/actions/runs/41148259375), Run unit tests | `tests/test_adwisp.lua:220`: invalid chapter index expected `-1`, got `1`. | Test setup was corrected to send a non-finite chapter index before asserting fallback. Commit `2e4aea4ec1c66f3e85177615ef1b57fe21ea1af5`; [41148464643 green](https://github.com/SakibShahariar/adwisp/actions/runs/41148464643). |
| `8c028036122d391b861a19dc447ae7cf5a4081cb` | [41148388875](https://github.com/SakibShahariar/adwisp/actions/runs/41148388875), Run unit tests | Same chapter-state test failure as the preceding run. | Resolved by the same test correction in `2e4aea4ec1c66f3e85177615ef1b57fe21ea1af5`; [41148464643 green](https://github.com/SakibShahariar/adwisp/actions/runs/41148464643). |
| `19ebc819f772dff8f677542a00f37df1e70adc90` | [41148744549](https://github.com/SakibShahariar/adwisp/actions/runs/41148744549), Run unit tests | Renderer assertion for the active audio-track status label did not match the renderer's shortened output. | Test expectation was aligned with the compact label in `24f8778caf2ed70d768f8d36cd4655c9028a00d7`; [41148805343 green](https://github.com/SakibShahariar/adwisp/actions/runs/41148805343). Later test commits `5c06598a37d84cd07343164050492673dcd1de9a` and `73356b8491af366b268e528957b49865e439530b` also passed ([41148874743](https://github.com/SakibShahariar/adwisp/actions/runs/41148874743), [41148933418](https://github.com/SakibShahariar/adwisp/actions/runs/41148933418)). |
| `d09b382f3b9fdf820eb512387fe87e7ad7082e21` | [41150620693](https://github.com/SakibShahariar/adwisp/actions/runs/41150620693), Check Lua syntax | `adwisp.lua:842`: unexpected symbol near `}`. | Closed the malformed track-state helper with `end` in `35fb09d1a84a766a90b0a1f36bebd0b3b3f95333`; [41150694329 green](https://github.com/SakibShahariar/adwisp/actions/runs/41150694329). |
| `7e7480da0b03c51a868dd2e5d38a0528d45938e0` | [41151178209](https://github.com/SakibShahariar/adwisp/actions/runs/41151178209), Check Lua syntax | `adwisp.lua:1119`: unexpected symbol near `{` (an unresolved `{helper}` placeholder). | Replaced the placeholder with the configurable key-binding helper in `37f4935693bb43ac49251ae173ca6e9c58918264`; [41151287196 green](https://github.com/SakibShahariar/adwisp/actions/runs/41151287196). |

The five pre-session historical red entries have later corrective/test commits with successful exact-SHA CI runs. The additional red entry in this session (`21ffaa1b7843608d0ac8d9567016eea98be7c431`) was caused by a test fixture leaving the duration at 90 seconds; the following commit restored 60 seconds and passed CI. The cache-service warnings in the historical logs did not cause those failures.

## Current pending CI obligations

- Commit: `522dba926fddb34463d38061281b4cad2e8f644d`
- Run: [42261670543](https://github.com/SakibShahariar/adwisp/actions/runs/42261670543)
- Observed state: in progress; the only active step is **Set up Lua**.
- Logs: unavailable while the job is in progress.
- Classification: pending / inconclusive; no code failure is established.
- Next action: recheck this exact run and record its terminal result before treating the commit as verified.

## Session history

| Date | Reviewed range / checkpoint | Result summary |
|---|---|---|
| 2026-11-02 | Initial checkpoint: `107549915369fa46dab2c2bceab25b2102f820f8` | Combined status lookup returned no entries; result recorded as unavailable. |
| 2026-11-06 | `107549915369fa46dab2c2bceab25b2102f820f8` through `9c8ac16ec6a04dd842c18f4ffad4840f30b83d49` | All eight commits green. Investigated five older red runs and recorded their later green corrections. |
| 2026-11-06 | `9c8ac16ec6a04dd842c18f4ffad4840f30b83d49` through `400f463b87b6e4c8e0e637a16190193ab3b0492d` | Five commits green; one test-only red was corrected by a later green commit; one ledger commit remains pending at Set up Lua. Release workflow now runs BMP tests and checks every core module in the archive. |
