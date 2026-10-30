# Real-mpv Integration Checklist

Use this checklist to validate Adwisp in an actual mpv session before a release. It complements the mocked Lua tests and CI; it does not claim that any test environment has already passed.

## Test record

Record these details for every run so results can be compared:

| Field | Value |
| --- | --- |
| Adwisp commit SHA | |
| mpv version (`mpv --version`) | |
| OS and version | |
| Window system / compositor (Wayland, X11, etc.) | |
| Display resolution and scaling | |
| mpv configuration used | |
| thumbfast version / installed or absent | |
| Theme file: fallback, valid, partial-invalid, or invalid | |
| Date and tester | |

Use **PASS**, **FAIL**, **BLOCKED**, or **NOT RUN** for each case. For failures, record exact reproduction steps, expected and actual behavior, relevant mpv log excerpts, and the related GitHub issue.

## Preparation

- [ ] Install Adwisp from the exact commit being tested, preserving the `adwisp.lua` and `core/` directory structure.
- [ ] Keep mpv's console or a log file available. For example, start mpv with `--log-file=adwisp-mpv.log` and the test media file.
- [ ] Prepare a short local video, a longer video, and a playlist containing at least two entries.
- [ ] Test once without thumbfast and, when available, once with the supported thumbfast script installed.
- [ ] Keep the same media, display settings, and mpv configuration when comparing two Adwisp commits.

## Core test cases

### Startup and media lifecycle

- [ ] Start mpv with no media and confirm Adwisp loads without Lua errors.
- [ ] Open a media file. Confirm the OSD appears and the displayed title matches the current file.
- [ ] Switch directly to another file. Confirm the title, playback state, timeline, and interaction state reflect the new file.
- [ ] Reach end-of-file and open another file. Confirm the OSD is cleared or refreshed appropriately and no previous drag remains active.
- [ ] Close mpv while the OSD is visible and while a thumbnail preview is active. Record whether the overlay and thumbfast state are cleaned up; shutdown cleanup is tracked separately in [issue #24](https://github.com/SakibShahariar/adwisp/issues/24).

### Playback and seeking

- [ ] Toggle pause and resume with Space and the visible playback control.
- [ ] Seek backward and forward with Left and Right; verify the configured `seek_step`.
- [ ] Click the timeline near the beginning, middle, and end. Confirm the seek position matches the pointer.
- [ ] Drag the timeline, move the pointer after release, and confirm seeking stops after release.
- [ ] Verify the elapsed/remaining-time and progress labels remain readable at normal and narrow OSD widths.

### Volume and mute

- [ ] Toggle mute with `m` and confirm the muted state is visible.
- [ ] Change volume with Ctrl+Up and Ctrl+Down. Confirm the configured step is applied and volume changes unmute playback.
- [ ] Click several positions on the visible volume track, including both ends. Confirm the displayed volume matches the pointer.
- [ ] Drag the volume track and confirm the value follows the pointer continuously, then stops after release.
- [ ] Click the volume label above the track and confirm it does not change the volume.
- [ ] Repeat volume interaction in compact mode and confirm the hit area follows the visible track.

### Playlist navigation

- [ ] Load a single-item playlist. Confirm previous/next controls are hidden and mouse plus keyboard navigation do not issue playlist commands.
- [ ] Load a playlist with at least two entries. Confirm the current position and total are displayed.
- [ ] Navigate with Ctrl+Left, Ctrl+Right, and the visible playlist controls. Confirm the current-item indicator updates.
- [ ] Change the playlist while the OSD is visible and confirm controls appear or disappear with the item count.

### Window size, fullscreen, and display scaling

- [ ] Resize mpv through normal, narrow, and short window dimensions.
- [ ] Test a compact-height window (below 240 pixels) and confirm controls, volume track, timeline, labels, and playlist remain within the panel.
- [ ] Toggle fullscreen and restore the window. Confirm the OSD geometry and mouse hit areas follow the new OSD dimensions.
- [ ] Repeat at the display scaling settings available on the test system.
- [ ] Confirm timeline labels do not overlap; note the smallest width at which both progress and elapsed/total labels remain visible.

### Theme loading and reload

- [ ] Start with no custom theme and confirm the built-in palette is used.
- [ ] Load a valid palette and run `/script-message adwisp-reload-theme`. Confirm the new colors are applied.
- [ ] Load a partially invalid palette. Confirm valid entries apply, missing roles use fallback colors, and invalid lines produce line-specific warnings.
- [ ] Reload an entirely invalid palette and confirm the last valid palette remains active.
- [ ] Reload with a missing or unreadable file and confirm the last valid palette remains active and the error is actionable.

### thumbfast integration

- [ ] Run without thumbfast. Confirm playback, seeking, and OSD interaction work without Lua errors.
- [ ] With thumbfast installed, hover the timeline and confirm a preview is requested.
- [ ] Move the pointer away from the timeline and confirm the preview is cleared.
- [ ] Hide the OSD, change media, and close mpv while a preview is active. Record whether stale previews remain.
- [ ] Repeat after restarting mpv or thumbfast if the integration appears stale.

## Results

Copy this table for each test run:

| Case | Result | Observed behavior / log reference | Related issue |
| --- | --- | --- | --- |
| Startup and media lifecycle | NOT RUN | | |
| Playback and seeking | NOT RUN | | |
| Volume and mute | NOT RUN | | |
| Playlist navigation | NOT RUN | | |
| Window size / fullscreen / scaling | NOT RUN | | |
| Theme loading and reload | NOT RUN | | |
| thumbfast integration | NOT RUN | | |

Do not mark a case PASS based only on source inspection or mocked tests. Attach the mpv version, environment record, reproduction steps, and relevant log excerpts to any issue created from a failure.

## Known limitations to account for

- Adwisp draws an ASS OSD; it is GTK/libadwaita-inspired, not a native GTK interface. Rendering and input behavior can vary by mpv version, operating system, and window system.
- thumbfast is optional and owns thumbnail generation; Adwisp only sends preview requests.
- A preferences interface and broad cross-version runtime validation are not yet complete.
- Shutdown cleanup and performance benchmarking remain tracked work; do not treat an untested manual case as passing.
