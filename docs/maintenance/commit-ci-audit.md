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
- Reviewed checkpoint SHA: `67c19dd3948a8516afb79cebc4baeb6fec0732e6`
- Reviewed: 2026-11-06
- Range reviewed: `107549915369fa46dab2c2bceab25b2102f820f8` through `67c19dd3948a8516afb79cebc4baeb6fec0732e6`
- Result: all commits through the checkpoint have terminal CI results. The follow-up range contains five green commits and eleven red attempts, all diagnosed and corrected by later commits; the final timeline commit is green.
- Resolved: workflow run [42261670543](https://github.com/SakibShahariar/adwisp/actions/runs/42261670543) for `522dba926fddb34463d38061281b4cad2e8f644d` completed successfully on rerun; the earlier Set up Lua delay was not a code failure.
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
| `522dba926fddb34463d38061281b4cad2e8f644d` | docs(ci): record historical failure resolutions | green (successful rerun) | [42261670543](https://github.com/SakibShahariar/adwisp/actions/runs/42261670543) |
| `44ee59a6147118560c59017c27122389e12c018e` | perf(input): preserve pointer cache during playback updates (#10) | green | [42261839590](https://github.com/SakibShahariar/adwisp/actions/runs/42261839590) |
| `21ffaa1b7843608d0ac8d9567016eea98be7c431` | test(input): cover playback pointer-cache invalidation (#10) | red; corrected | [42261870546](https://github.com/SakibShahariar/adwisp/actions/runs/42261870546) |
| `2ee79b9248c3a2be280fbb5d7a11bc1200f46846` | test(input): restore fixture duration after cache check (#10) | green | [42261991020](https://github.com/SakibShahariar/adwisp/actions/runs/42261991020) |
| `d27516ae4f85f3d857b03d326b3e14978f662714` | ci(release): run the BMP regression suite (#17) | green | [42262047858](https://github.com/SakibShahariar/adwisp/actions/runs/42262047858) |
| `c423e4e157cac2d633207d47e84f8544416bcdc7` | test(release): verify every packaged core module (#17) | green | [42262262002](https://github.com/SakibShahariar/adwisp/actions/runs/42262262002) |
| `400f463b87b6e4c8e0e637a16190193ab3b0492d` | fix(release): print archive entries on separate lines (#17) | green | [42262292533](https://github.com/SakibShahariar/adwisp/actions/runs/42262292533) |

## Follow-up review after the 2026-11-06 checkpoint

All commits below were reviewed against their exact-SHA workflow run. Failed attempts are retained; the correction column records the later commit/run that established the final green state.

| Commit SHA | Subject | CI result | Run | Diagnosis / resolution |
|---|---|---|---|---|
| `19127e7a7ec740fe7c1a8095596e4989e461bdad` | docs(ci): checkpoint Adwisp maintenance verification | green | [42262585925](https://github.com/SakibShahariar/adwisp/actions/runs/42262585925) | Ledger checkpoint commit passed. |
| `64123199b0aa52766eab841cafe377a0138b65f4` | test(thumbfast): cover lifecycle invalidation (#11) | red | [42265160731](https://github.com/SakibShahariar/adwisp/actions/runs/42265160731) | Fixture pointer remained outside the timeline; corrected by `1e593551341d9006f5e0ed5443293efacaadec3a`, green [42265403428](https://github.com/SakibShahariar/adwisp/actions/runs/42265403428). |
| `25669e324d4a93610e617dcbb9691f9f33afbe69` | test(shutdown): cover missing thumbfast adapter (#24) | red | [42265220602](https://github.com/SakibShahariar/adwisp/actions/runs/42265220602) | Same invalid-message fixture setup failure; pointer correction landed in `1e593551341d9006f5e0ed5443293efacaadec3a`. |
| `1e593551341d9006f5e0ed5443293efacaadec3a` | test(thumbfast): position pointer for lifecycle cases (#11) | green | [42265403428](https://github.com/SakibShahariar/adwisp/actions/runs/42265403428) | Corrected preview fixture coordinates. |
| `3f59679ed32df1ac4def18a6e374c9ae8acd0a39` | test(thumbfast): cover OSD dismissal cleanup (#11) | red | [42265517461](https://github.com/SakibShahariar/adwisp/actions/runs/42265517461) | Dismissal fixture attempted to preview while the OSD was hidden; corrected by showing the OSD and positioning the pointer in `97749c25151b3b9c7e29582459c711cd5d641944`. |
| `85b8e7250aaae1cb1a8e6a4c91990309327866ef` | feat(audio): add output device selection menu (#46) | red | [42265843878](https://github.com/SakibShahariar/adwisp/actions/runs/42265843878) | Inherited the dismissal-fixture failure; corrected in the same follow-up. |
| `97749c25151b3b9c7e29582459c711cd5d641944` | test(thumbfast): show OSD before dismissal fixture (#11) | green | [42265904895](https://github.com/SakibShahariar/adwisp/actions/runs/42265904895) | Verified thumbfast lifecycle/shutdown tests and audio-device implementation. |
| `24dd86511c086025f73a394abe6ffc7db7b19e9a` | docs(audio): clarify configured output device state (#46) | green | [42266098458](https://github.com/SakibShahariar/adwisp/actions/runs/42266098458) | Documented configured-target versus actual backend endpoint limitation. |
| `428dc7fb5d697490add2930ba650594af80bfcb3` | feat(timeline): add optional minimal progress mode (#45) | red | [42266619196](https://github.com/SakibShahariar/adwisp/actions/runs/42266619196) | New interaction path triggered an extra layout render in default mode; redraws were gated to minimal mode. |
| `76c4a1ed00b9934076b0b3344dc1015c493e0cb9` | test(timeline): keep renderer counters stable (#45) | red | [42266719540](https://github.com/SakibShahariar/adwisp/actions/runs/42266719540) | Same default-mode cache regression; follow-up cache/render fixes are in `80e625e4a843c38b78afeca2d5c2710f47897fa4` and `70e547672bec5ccd7ffffaac01df5a0b0d6ca643`. |
| `80e625e4a843c38b78afeca2d5c2710f47897fa4` | fix(timeline): preserve default layout cache (#45) | red | [42266782626](https://github.com/SakibShahariar/adwisp/actions/runs/42266782626) | Cache state was preserved, but click/drag redraws still ran outside minimal mode; corrected in `70e547672bec5ccd7ffffaac01df5a0b0d6ca643`. |
| `5865c61900ba7200618783b086b54a05769ae451` | test(timeline): cover minimal geometry across window sizes (#45) | red | [42266882229](https://github.com/SakibShahariar/adwisp/actions/runs/42266882229) | Same default-mode cache regression; corrected in `70e547672bec5ccd7ffffaac01df5a0b0d6ca643`. |
| `825f79de31b768a4c2aa67209336ba0296b65336` | ci: use runner Lua 5.2 packages for stable setup | red | [42266996199](https://github.com/SakibShahariar/adwisp/actions/runs/42266996199) | LuaRocks could not locate Lua headers; explicit `LUA_INCDIR=/usr/include/lua5.2` and `--lua-dir=/usr` added in `b9281577b6a69036ea3b57b3ee0964f2f9a977a2`. |
| `70e547672bec5ccd7ffffaac01df5a0b0d6ca643` | fix(timeline): avoid redraws outside minimal mode (#45) | red | [42267061183](https://github.com/SakibShahariar/adwisp/actions/runs/42267061183) | Code fix was present, but the same Lua header setup failure prevented checks; verified in the later green run. |
| `b9281577b6a69036ea3b57b3ee0964f2f9a977a2` | ci: point LuaRocks at Lua 5.2 headers | red | [42267158185](https://github.com/SakibShahariar/adwisp/actions/runs/42267158185) | Static checks passed; focus test retained a prior playback focus target and expected the wrong cycle position. Test now resets focus before navigation. |
| `63f0b8acc7e0e942ddcf77f09daaac75e1545b28` | test(timeline): reset focus before navigation assertions (#45) | green | [42267262610](https://github.com/SakibShahariar/adwisp/actions/runs/42267262610) | Final timeline implementation, layout matrix, renderer, interaction tests, and updated Lua 5.2 CI setup all passed. |
| `6130a83dc9d7c2d875b72c2779f7e6677cf6283a` | feat(menu): add reusable filtering model (#44) | green | [42267790730](https://github.com/SakibShahariar/adwisp/actions/runs/42267790730) | Added pure multi-token filtering and original-index mapping tests to CI and release workflows. |
| `00d4db7ba03713b9e18a59478110861474fb4334` | feat(playlist): add type-to-filter menu search (#44) | red | [42268734304](https://github.com/SakibShahariar/adwisp/actions/runs/42268734304) | Search-clear test expected a space between current/focus markers; corrected in the following test commit. |
| `b5bbe6c140e92ca6c3a56162e01f750d35b3dc0b` | test(playlist): cover active search selection feedback (#44) | red | [42268807469](https://github.com/SakibShahariar/adwisp/actions/runs/42268807469) | Playlist fixture leaked four items into later tests; reset playlist state in `ce8fc5a27d1adb2cbc931315c9b204e41fa14851`. |
| `ce8fc5a27d1adb2cbc931315c9b204e41fa14851` | test(playlist): isolate search fixture from later cases (#44) | green | [42269006477](https://github.com/SakibShahariar/adwisp/actions/runs/42269006477) | Reset playlist fixtures after search tests; full suite passed. |
| `67c19dd3948a8516afb79cebc4baeb6fec0732e6` | fix(playlist): guard unsupported text-input bindings (#44) | green | [42269143393](https://github.com/SakibShahariar/adwisp/actions/runs/42269143393) | Unsupported `ANY_UNICODE` bindings are caught; playlist menu retains fallback controls. |

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

- None at checkpoint `67c19dd3948a8516afb79cebc4baeb6fec0732e6`. All reviewed runs in this range reached a terminal state.

## Session history

| Date | Reviewed range / checkpoint | Result summary |
|---|---|---|
| 2026-11-02 | Initial checkpoint: `107549915369fa46dab2c2bceab25b2102f820f8` | Combined status lookup returned no entries; result recorded as unavailable. |
| 2026-11-06 | `107549915369fa46dab2c2bceab25b2102f820f8` through `9c8ac16ec6a04dd842c18f4ffad4840f30b83d49` | All eight commits green. Investigated five older red runs and recorded their later green corrections. |
| 2026-11-06 | `9c8ac16ec6a04dd842c18f4ffad4840f30b83d49` through `400f463b87b6e4c8e0e637a16190193ab3b0492d` | Five commits green; one test-only red was corrected by a later green commit; the ledger commit was initially pending and later passed on rerun. Release workflow now runs BMP tests and checks every core module in the archive. |
| 2026-11-06 | `400f463b87b6e4c8e0e637a16190193ab3b0492d` through `63f0b8acc7e0e942ddcf77f09daaac75e1545b28` | Five commits green; eleven red attempts diagnosed and corrected by later commits. Thumbfast lifecycle, audio-device selection, minimal timeline, and the Lua 5.2 CI setup have final green verification. |
| 2026-11-06 | `63f0b8acc7e0e942ddcf77f09daaac75e1545b28` through `67c19dd3948a8516afb79cebc4baeb6fec0732e6` | Three green commits and two red attempts corrected; playlist search now supports filtering, original-index selection, keyboard navigation, clear/dismiss, and safe fallback when ANY_UNICODE is unsupported. |
