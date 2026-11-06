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
- Reviewed checkpoint SHA: `7595691120ec768be21fe9fcaca4d221118f9ded`
- Reviewed: 2026-11-06
- Range reviewed: `107549915369fa46dab2c2bceab25b2102f820f8` through `7595691120ec768be21fe9fcaca4d221118f9ded`
- Result: all commits through the checkpoint have terminal CI results. The follow-up range contains five green commits and eleven red attempts, all diagnosed and corrected by later commits; the final timeline commit is green.
- Resolved: workflow run [42261670543](https://github.com/SakibShahariar/adwisp/actions/runs/42261670543) for `522dba926fddb34463d38061281b4cad2e8f644d` completed successfully on rerun; the earlier Set up Lua delay was not a code failure.
- Next session: review this ledger update commit and any newer exact-SHA runs; retain all red history.

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
| `376a4c32faf99026cfbfc6cfd0d0694b692b302b` | docs(playlist): document search fallback and CI review | green | [42269452926](https://github.com/SakibShahariar/adwisp/actions/runs/42269452926) | README documents the unsupported-input fallback; CI ledger records the exact-SHA review. |

## Follow-up review after the 2026-11-06 checkpoint (continued)

| Commit SHA | Subject | CI result | Run | Diagnosis / resolution |
|---|---|---|---|---|
| `4f38a92362d52d2d2587d1011ec65bc937f794e3` | feat(tracks): add searchable audio and subtitle menus (#44) | green | [42269802793](https://github.com/SakibShahariar/adwisp/actions/runs/42269802793) | Audio/subtitle filtering, selection mapping, and interaction tests passed. |
| `1229fc2a8cd2d2681949de608067e4571d64f836` | feat(chapters): add searchable chapter selection menu (#44) | red | [42270056155](https://github.com/SakibShahariar/adwisp/actions/runs/42270056155) | Chapter search-clear assertion expected a different displayed timestamp format; corrected in `ccb67bb3efbd090e775992b6591d2257499304fe`. |
| `ccb67bb3efbd090e775992b6591d2257499304fe` | test(chapters): match the displayed timestamp format | red | [42270172395](https://github.com/SakibShahariar/adwisp/actions/runs/42270172395) | After the timestamp expectation was corrected, a later chapter-navigation test had no chapter fixture because the search test had cleared it; restored the fixture in `3f5a377dda8b16e0cdaedab8a7c325dd9bf6d7f2`. |
| `c4ab60a657a261de15a23499ec9264e8f36503a1` | docs: streamline README and add usage guide | red | [42270320356](https://github.com/SakibShahariar/adwisp/actions/runs/42270320356) | Inherited the chapter-navigation fixture failure; the docs changes were included in the full green rerun after the fixture correction. |
| `3f5a377dda8b16e0cdaedab8a7c325dd9bf6d7f2` | test(chapters): restore navigation fixture after search tests (#44) | green | [42270482922](https://github.com/SakibShahariar/adwisp/actions/runs/42270482922) | Re-established chapter metadata/current selection before the chapter-prev/next assertions; full suite passed. |
| `a6f332974e63a9291945b79b9aaf9cd2acf99572` | feat(image): add still-image fit and zoom controls (#47) | green | [42271159763](https://github.com/SakibShahariar/adwisp/actions/runs/42271159763) | Still-image/album-art mode detection, fit/zoom/reset command mapping, and transition tests passed. |

## Follow-up review after the 2026-11-06 checkpoint (continued)

| Commit SHA | Subject | CI result | Run | Diagnosis / resolution |
|---|---|---|---|---|
| `ef98986b0b0936a1beb56b76deb7261ebf8dcfab` | docs(ci): record menu, image, and README verification | green | [42271309768](https://github.com/SakibShahariar/adwisp/actions/runs/42271309768) | Updated the audit ledger with the final menu, README, and image-control CI outcomes. |
| `180e2380a9cc246b00b35e382a160d0b47a7d5a3` | test(input): cover pointer cache invalidation events (#10) | green | [42271481971](https://github.com/SakibShahariar/adwisp/actions/runs/42271481971) | Added mocked invalidation checks for playlist content/count, OSD dimensions, video reconfiguration, and thumbfast metadata; full suite passed. |

## Follow-up review through the persistent playlist panel checkpoint

| Commit SHA | Subject | CI result | Run | Diagnosis / resolution |
|---|---|---|---|---|
| `fb6d0dfc545719ce1361d80d2e7424af866efb48` | docs(ci): record mouse cache verification | green | [42271611608](https://github.com/SakibShahariar/adwisp/actions/runs/42271611608) | Recorded the mouse-cache invalidation matrix and its full-suite result. |
| `de450b521f1373f21ebf54e803914077bd75ab97` | feat(playlist): keep playlist view open while browsing (#34) | red | [42271759081](https://github.com/SakibShahariar/adwisp/actions/runs/42271759081) | Playlist selection test saw the menu-clear OSD command after the selection command; selection cleanup ordering was corrected. |
| `c861f52fd81bc175a8e89cd46ac165cbf09fbffd` | test(playlist): correct persistent view toggle assertions (#34) | red | [42271818682](https://github.com/SakibShahariar/adwisp/actions/runs/42271818682) | The earlier selection-command ordering failure remained; addressed in the following source fix. |
| `36574fdfe92caf14aad99e1491ec8df88f6ef642` | fix(playlist): clear persistent view before selection feedback (#34) | red | [42271930290](https://github.com/SakibShahariar/adwisp/actions/runs/42271930290) | Clearing all menus also injected an OSD clear into audio-track selection; limited persistent-panel clearing to the playlist menu. |
| `b1ad47cddb7d3f1b97b2c7205ed498957356da6b` | fix(menus): preserve track selection feedback when closing menus (#34) | green | [42272201722](https://github.com/SakibShahariar/adwisp/actions/runs/42272201722) | Track-menu selection and persistent playlist-panel cleanup passed the full suite. |
| `1d21cd3a26879ab46910a030d51ae78a060e4e6e` | feat(playlist): render persistent responsive playlist panel (#34) | red | [42272442481](https://github.com/SakibShahariar/adwisp/actions/runs/42272442481) | A legacy playlist paging assertion still inspected show-text commands instead of the new ASS overlay. |
| `5d4532b8a3aaea407c5f8fc6cd3546cc9c617343` | test(playlist): assert rendered panel content and document it (#34) | red | [42272531668](https://github.com/SakibShahariar/adwisp/actions/runs/42272531668) | The next-page assertion still inspected the old command output; switched it to the renderer overlay. |
| `d2e8854a9ceeb4e61bb8fc9f8ce883b0459ebc83` | test(playlist): inspect rendered page after navigation (#34) | red | [42272610212](https://github.com/SakibShahariar/adwisp/actions/runs/42272610212) | Unsupported-input fallback assertion still read show-text instead of the persistent panel overlay. |
| `0aa0a1d561e5d0222e1a9a8ec5481818344438b1` | test(playlist): assert fallback text in persistent panel (#34) | red | [42272731140](https://github.com/SakibShahariar/adwisp/actions/runs/42272731140) | Fallback test opened an empty playlist, so the menu returned before registering the fallback state; seeded a test entry. |
| `9328b3f1fcc40c5eb65a8a93528cf6d6469dde5f` | test(playlist): seed entries for unsupported input fallback (#34) | red | [42272876659](https://github.com/SakibShahariar/adwisp/actions/runs/42272876659) | Hidden-render test assumed a fixed overlay update count despite the new panel tests; converted it to a baseline comparison. |
| `dc280b89caba48ddb451a273c0a9cf41394d22e4` | test(renderer): compare hidden OSD against update baseline (#34) | red | [42273034160](https://github.com/SakibShahariar/adwisp/actions/runs/42273034160) | Baseline was captured before the hidden-OSD section and the OSD was still visible; explicitly hid it and captured the baseline there. |
| `b036d4a2bd21b2ab24d4c5654883bbebe5122081` | test(renderer): capture hidden overlay baseline at assertion scope (#34) | red | [42273233814](https://github.com/SakibShahariar/adwisp/actions/runs/42273233814) | The baseline was correctly scoped but the test still needed to hide the OSD before measuring; fixed in `db2106d9b74af92f14aa62eec42625cd6d0473e3`. |
| `db2106d9b74af92f14aa62eec42625cd6d0473e3` | test(renderer): hide OSD before measuring hidden redraws (#34) | red | [42273301726](https://github.com/SakibShahariar/adwisp/actions/runs/42273301726) | Wheel-scroll test inherited playlist position 1 from earlier tests, so the focused row began at item 2; reset the current position in the fixture. |
| `f7566920c2fae48dcd58a68f33ce025a5fa43c6e` | feat(playlist): add wheel scrolling and compact panel layout (#34) | red | [42273530763](https://github.com/SakibShahariar/adwisp/actions/runs/42273530763) | Same stale playlist-position fixture affected the wheel-down assertion; fixed by `c2725cde08e1672b3f95018ecb819e73181724d8`. |
| `c2725cde08e1672b3f95018ecb819e73181724d8` | test(playlist): reset current position before wheel assertions (#34) | red | [42273665645](https://github.com/SakibShahariar/adwisp/actions/runs/42273665645) | File-loaded rendering assertion expected an absolute overlay update count; converted it to a per-operation baseline. |
| `529b3b2f54d68db90e8b2230188d704e654fb787` | test(renderer): measure file-load render from current baseline (#34) | red | [42273961042](https://github.com/SakibShahariar/adwisp/actions/runs/42273961042) | Unchanged-render cache assertion still expected an absolute count; converted it to a baseline comparison. |
| `7cdc95b8c7049cd97e9abee799fe3656b02576ca` | test(renderer): compare unchanged render against baseline (#34) | green | [42274032730](https://github.com/SakibShahariar/adwisp/actions/runs/42274032730) | Full Lua syntax, Luacheck, and unit-test suite passed with the persistent responsive playlist panel and wheel navigation. |
| `d075bf7dc70f23083ad42c06fa9c404a57b1df1e` | docs(playlist): clarify panel toggle and idle behavior (#34) | green | [42274148294](https://github.com/SakibShahariar/adwisp/actions/runs/42274148294) | Documented the actual Ctrl+Alt+F12 toggle and clarified that the configured global idle-hide timeout still applies. |

## Follow-up review through the recent-history checkpoint

| Commit SHA | Subject | CI result | Run | Diagnosis / resolution |
|---|---|---|---|---|
| `dac568753aa98a501e1f6674ee59685a5fb81995` | docs(ci): record persistent playlist panel verification | green | [42274376106](https://github.com/SakibShahariar/adwisp/actions/runs/42274376106) | Recorded the persistent playlist panel's full green test result and earlier corrected attempts. |
| `3afe8e019a0a69047ebcd5ab3b19477e658c9639` | feat(history): add opt-in local recent-file store (#38) | red | [42274729192](https://github.com/SakibShahariar/adwisp/actions/runs/42274729192) | Luacheck found an unused fixture argument in the new history test; the integration commit inherited the warning. |
| `405e377a04c242c896ebc5b9add9fe1356a243a3` | feat(history): add opt-in recent-files menu (#38) | red | [42275047895](https://github.com/SakibShahariar/adwisp/actions/runs/42275047895) | Same Luacheck warning blocked tests; corrected in the fixture follow-up. |
| `278ba420f758f434f7054b0638552b8ab2d6e69f` | fix(history): sanitize path-like titles and lint fixture (#38) | red | [42275179946](https://github.com/SakibShahariar/adwisp/actions/runs/42275179946) | Fixture edit removed the required `file_info(path)` parameter while leaving an unused `open(path)` parameter; both were corrected in `c90b4e098c5c6455eb41bc9ae938e11905985aca`. |
| `c90b4e098c5c6455eb41bc9ae938e11905985aca` | test(history): correct file fixture arguments (#38) | green | [42275400103](https://github.com/SakibShahariar/adwisp/actions/runs/42275400103) | Luacheck and all unit tests passed after correcting the fake file API signatures. |
| `344175780fc87e1cfc6f06ca779ed6f9fcaff1db` | test(history): cover recent menu and file-loaded integration (#38) | green | [42275525154](https://github.com/SakibShahariar/adwisp/actions/runs/42275525154) | Mocked mpv tests cover recent-panel rendering, wheel selection, reopening, clear actions, local file recording, and network URL rejection. |
| `7595691120ec768be21fe9fcaca4d221118f9ded` | docs(history): document recent menu and script messages (#38) | green | [42275677126](https://github.com/SakibShahariar/adwisp/actions/runs/42275677126) | Documented the recent-history controls, privacy defaults, and script-message API; full CI remained green. |

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

- None at checkpoint `7595691120ec768be21fe9fcaca4d221118f9ded`. All reviewed runs in this range reached a terminal state.

## Session history

| 2026-11-06 | `d075bf7dc70f23083ad42c06fa9c404a57b1df1e` through `7595691120ec768be21fe9fcaca4d221118f9ded` | Four green commits and three red attempts diagnosed and corrected. Added opt-in local recent-file persistence, a recent-items OSD panel, safe clearing, and integration tests. Category B issue #38 still needs real-mpv validation across restarts. |

| 2026-11-06 | `180e2380a9cc246b00b35e382a160d0b47a7d5a3` through `d075bf7dc70f23083ad42c06fa9c404a57b1df1e` | Four green commits and fourteen red attempts diagnosed and corrected. Added a persistent OSD playlist panel with filtering, removal, responsive paging, and wheel scrolling; all menu/renderer tests now pass. Category B issue #34 still needs real-mpv visual validation. |

| 2026-11-06 | `a6f332974e63a9291945b79b9aaf9cd2acf99572` through `180e2380a9cc246b00b35e382a160d0b47a7d5a3` | Two green commits; updated the audit ledger and expanded mouse-cache invalidation coverage. Category B issue #10 now has its automated invalidation matrix verified; real-mpv interaction and CPU measurements remain open. |

| 2026-11-06 | `376a4c32faf99026cfbfc6cfd0d0694b692b302b` through `a6f332974e63a9291945b79b9aaf9cd2acf99572` | Three green commits and three red attempts corrected. Added searchable audio/subtitle/chapter menus, shortened the README to a 70-line landing page with a separate usage guide, and added still-image fit/zoom/reset controls. Full CI passed on the final image-controls commit. |

| Date | Reviewed range / checkpoint | Result summary |
|---|---|---|
| 2026-11-02 | Initial checkpoint: `107549915369fa46dab2c2bceab25b2102f820f8` | Combined status lookup returned no entries; result recorded as unavailable. |
| 2026-11-06 | `107549915369fa46dab2c2bceab25b2102f820f8` through `9c8ac16ec6a04dd842c18f4ffad4840f30b83d49` | All eight commits green. Investigated five older red runs and recorded their later green corrections. |
| 2026-11-06 | `9c8ac16ec6a04dd842c18f4ffad4840f30b83d49` through `400f463b87b6e4c8e0e637a16190193ab3b0492d` | Five commits green; one test-only red was corrected by a later green commit; the ledger commit was initially pending and later passed on rerun. Release workflow now runs BMP tests and checks every core module in the archive. |
| 2026-11-06 | `400f463b87b6e4c8e0e637a16190193ab3b0492d` through `63f0b8acc7e0e942ddcf77f09daaac75e1545b28` | Five commits green; eleven red attempts diagnosed and corrected by later commits. Thumbfast lifecycle, audio-device selection, minimal timeline, and the Lua 5.2 CI setup have final green verification. |
| 2026-11-06 | `63f0b8acc7e0e942ddcf77f09daaac75e1545b28` through `67c19dd3948a8516afb79cebc4baeb6fec0732e6` | Three green commits and two red attempts corrected; playlist search now supports filtering, original-index selection, keyboard navigation, clear/dismiss, and safe fallback when ANY_UNICODE is unsupported. |
| 2026-11-06 | `67c19dd3948a8516afb79cebc4baeb6fec0732e6` through `376a4c32faf99026cfbfc6cfd0d0694b692b302b` | One green documentation/ledger commit; playlist-search compatibility fallback is documented and the ledger checkpoint is current. |
