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
- Reviewed checkpoint SHA: `9c8ac16ec6a04dd842c18f4ffad4840f30b83d49`
- Reviewed: 2026-11-06
- Range reviewed: `107549915369fa46dab2c2bceab25b2102f820f8` through `9c8ac16ec6a04dd842c18f4ffad4840f30b83d49`
- Result: all eight commits in the range have completed successful CI runs for their exact SHAs.
- Next session: start at the commit after this checkpoint; retain the historical red entries below as resolved records.

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

## Historical red-cross investigation

These failures predate the checkpoint above. They were discovered by inspecting the actual workflow jobs and logs, not inferred from commit badges.

| Failed commit SHA | Run / failed step | Observed failure | Resolution evidence |
|---|---|---|---|
| `2dd1c7aeb02781ef44b81d3161c0ecbb409424f3` | [41148259375](https://github.com/SakibShahariar/adwisp/actions/runs/41148259375), Run unit tests | `tests/test_adwisp.lua:220`: invalid chapter index expected `-1`, got `1`. | Test setup was corrected to send a non-finite chapter index before asserting fallback. Commit `2e4aea4ec1c66f3e85177615ef1b57fe21ea1af5`; [41148464643 green](https://github.com/SakibShahariar/adwisp/actions/runs/41148464643). |
| `8c028036122d391b861a19dc447ae7cf5a4081cb` | [41148388875](https://github.com/SakibShahariar/adwisp/actions/runs/41148388875), Run unit tests | Same chapter-state test failure as the preceding run. | Resolved by the same test correction in `2e4aea4ec1c66f3e85177615ef1b57fe21ea1af5`; [41148464643 green](https://github.com/SakibShahariar/adwisp/actions/runs/41148464643). |
| `19ebc819f772dff8f677542a00f37df1e70adc90` | [41148744549](https://github.com/SakibShahariar/adwisp/actions/runs/41148744549), Run unit tests | Renderer assertion for the active audio-track status label did not match the renderer's shortened output. | Test expectation was aligned with the compact label in `24f8778caf2ed70d768f8d36cd4655c9028a00d7`; [41148805343 green](https://github.com/SakibShahariar/adwisp/actions/runs/41148805343). Later test commits `5c06598a37d84cd07343164050492673dcd1de9a` and `73356b8491af366b268e528957b49865e439530b` also passed ([41148874743](https://github.com/SakibShahariar/adwisp/actions/runs/41148874743), [41148933418](https://github.com/SakibShahariar/adwisp/actions/runs/41148933418)). |
| `d09b382f3b9fdf820eb512387fe87e7ad7082e21` | [41150620693](https://github.com/SakibShahariar/adwisp/actions/runs/41150620693), Check Lua syntax | `adwisp.lua:842`: unexpected symbol near `}`. | Closed the malformed track-state helper with `end` in `35fb09d1a84a766a90b0a1f36bebd0b3b3f95333`; [41150694329 green](https://github.com/SakibShahariar/adwisp/actions/runs/41150694329). |
| `7e7480da0b03c51a868dd2e5d38a0528d45938e0` | [41151178209](https://github.com/SakibShahariar/adwisp/actions/runs/41151178209), Check Lua syntax | `adwisp.lua:1119`: unexpected symbol near `{` (an unresolved `{helper}` placeholder). | Replaced the placeholder with the configurable key-binding helper in `37f4935693bb43ac49251ae173ca6e9c58918264`; [41151287196 green](https://github.com/SakibShahariar/adwisp/actions/runs/41151287196). |

All five historical red entries have a later corrective/test commit with a successful exact-SHA CI run. No unresolved failure from these entries is currently known. The cache-service warnings in these logs did not cause the failed jobs.

## Session history

| Date | Reviewed range / checkpoint | Result summary |
|---|---|---|
| 2026-11-02 | Initial checkpoint: `107549915369fa46dab2c2bceab25b2102f820f8` | Combined status lookup returned no entries; result recorded as unavailable. |
| 2026-11-06 | `107549915369fa46dab2c2bceab25b2102f820f8` through `9c8ac16ec6a04dd842c18f4ffad4840f30b83d49` | All eight commits green. Investigated five older red runs, identified their exact failed steps and later green corrections, and retained them here as resolved historical records. |
