# Usage

This guide covers Adwisp's keyboard and mouse controls, configuration, and script-message interface.

## Controls

### Keyboard

| Input | Action |
| --- | --- |
| `g` | Toggle the interface |
| `q` | Dismiss the interface |
| `Escape` | Close an open selection menu; otherwise dismiss the interface |
| `Left` / `Right` | Seek by `seek_step` seconds |
| `Space` | Toggle playback pause |
| `m` | Toggle mute |
| `Ctrl+Left` / `Ctrl+Right` | Previous / next playlist item |
| `Ctrl+Page Up` / `Ctrl+Page Down` | Previous / next chapter |
| `Ctrl+Alt+F3` | Open the recent-files menu (requires opt-in history) |
| `Ctrl+Alt+Shift+F3` | Clear local recent-file history |
| `Ctrl+Alt+F8` | Open the searchable chapter menu |
| `Ctrl+Alt+F5` | Cycle audio tracks |
| `Ctrl+Alt+F6` | Cycle subtitle tracks, including Off |
| `Ctrl+Alt+F9` | Open the audio-output device menu |
| `Ctrl+Alt+F10` | Open the audio track menu |
| `Ctrl+Alt+F11` | Open the subtitle track menu |
| `Ctrl+Alt+F12` | Open the playlist menu |
| `Ctrl+Alt+Up` / `Ctrl+Alt+Down` | Adjust playback speed |
| `Ctrl+Alt+Backspace` | Reset playback speed to 1× |
| `Ctrl+Alt+L` | Toggle infinite file looping |
| `Ctrl+Alt+A` | Cycle A-B loop points: set A, set B, clear |
| `Ctrl+Alt+S` | Take an mpv screenshot |
| `Ctrl+Alt+F7` | Export the visible thumbfast preview as BMP |
| `Ctrl+Alt+Home` | Fit a still image to the window |
| `Ctrl+Alt+KP_Add` / `Ctrl+Alt+KP_Subtract` | Zoom a still image in / out |
| `Ctrl+Alt+Backspace` | Reset a still image to fit; otherwise reset playback speed |
| `Ctrl+Up` / `Ctrl+Down` | Adjust volume |

Still-image controls are available only when mpv marks the selected video track as an image or album-art track. Zoom steps use mpv's logarithmic video-zoom setting; fit/reset clears zoom and pan and restores normal window scaling.

The chapter, audio-track, subtitle-track, and playlist menus support numbered selection with `Ctrl+Alt+1–9`. Playlist items can also be removed with `Ctrl+Alt+Shift+1–9`. While a menu is open, type to filter its entries; use Up/Down and Enter to navigate and select. Search uses Unicode 15.1 default full case folding for case-insensitive matching, including multi-character folds such as German ß matching ss; it does not normalize canonically equivalent Unicode sequences. Chapter search matches titles and timestamps; track search matches displayed language, title, and codec; playlist search matches title and filename. Use Ctrl+Backspace to clear a search. If text input is unsupported by the mpv build, numbered selection remains available.

The playlist panel stays open while you browse; press Ctrl+Alt+F12 again or Esc to close it. Playlist changes and media transitions close the panel so it cannot display stale entries. The panel is drawn in Adwisp's OSD overlay, reduces the number of visible rows for shorter windows, and supports mouse-wheel scrolling. The global idle-hide timeout still applies when enabled.

The chapter, audio, subtitle, and playlist menus can be paged with `Ctrl+Alt+Page Up` and `Ctrl+Alt+Page Down` when additional results exist.

### Focus and mouse

- `Tab` / `Shift+Tab` moves keyboard focus between playback, volume, and playlist controls.
- `Enter` activates the focused control.
- Left/Right adjusts volume or moves through the playlist when those controls are focused; otherwise, they seek.
- Hovering or focusing the timeline expands it when `minimal_timeline=yes`.
- Click the timeline to seek, the playback control to pause/resume, or the volume bar to set volume.
- Drag the timeline or volume bar for continuous adjustment.
- Click the left/right playlist controls to move between items.

Keyboard focus uses the active theme accent.

The audio-output menu reads mpv's `audio-device-list` and `audio-device` properties. Its selected marker represents the configured/requested target, not necessarily the physical endpoint currently in use. Available device names depend on the active audio backend.

Mouse and OSD behavior can vary with mpv configuration and platform. Include your mpv version and relevant logs when reporting issues.

## Configuration

Adwisp uses mpv's standard script options. Edit `script-opts/adwisp.conf` in your mpv configuration directory. The full option list is in `script-opts/adwisp.conf`.

Core bindings can be remapped independently. Duplicate Adwisp bindings are detected; the later action falls back to its default.

Set `control_zones=split` to place the title and playback-status row in a separate top panel while keeping playback, volume, timeline, and playlist controls in the bottom panel. Split mode is opt-in and currently requires `osd_position=bottom`; compact or too-short windows automatically retain the original single-panel layout. `top_zone_margin` controls the top panel offset.

| Option | Purpose | Default |
| --- | --- | --- |
| `seek_step` | Seek distance in seconds | `5` |
| `volume_step` | Volume change per shortcut | `5` |
| `speed_step` | Playback-speed change per shortcut | `0.1` |
| `thumbnail_preview` | Enable the thumbfast adapter | `yes` |
| `minimal_timeline` | Collapse the timeline until hovered/focused | `no` |
| `osd_position` | OSD placement: bottom, top, or custom | `bottom` |
| `control_zones` | `single` keeps the original panel; `split` separates title/status from playback controls | `single` |
| `top_zone_margin` | Top-edge margin for the optional split title/status zone | `24` |
| `top_zone_visibility` / `bottom_zone_visibility` | `always` keeps a split zone visible; `hover` shows it only while hovered or keyboard-focused | `always` / `always` |
| `font_family` / `font_scale` | Font and relative scale | `Sans` / `1.0` |
| `idle_hide_timeout` | Hide after inactivity; 0 disables it | `0` |
| `fade_duration` | OSD fade duration in seconds | `0.25` |
| `log_level` | Logging verbosity: quiet, info, or debug | `info` |
| `theme_file` | Absolute path to a semantic palette file | empty |
| `recent_history` | Persist a local recently played list; off by default | `no` |
| `recent_history_limit` | Maximum recent local files to retain | `20` |
| `recent_history_file` | Local JSON history file path | `~~/adwisp-recent.json` |

### Localization and accessibility

Set `locale_file=/path/to/adwisp-locale.conf` to override the built-in English UI strings. Locale files are UTF-8 `key=value` files; missing or invalid entries fall back to English. Start from `locales/template.conf` and see `docs/LOCALIZATION.md` for the supported keys.

Keyboard navigation is available without a mouse: Tab/Shift+Tab moves focus, Enter activates the focused control, and the playlist/track/chapter menus support arrow-key navigation. Adwisp also exposes the focused control and image-viewer state through `adwisp-query`. Custom themes are checked for text/background contrast; low-contrast combinations produce warnings rather than silently changing the user's palette.

### Recently played history

Recent history is disabled by default. Set `recent_history=yes` to keep a local JSON list of recently opened files. Only local paths are recorded; network URLs are ignored. The menu displays media titles rather than full paths. History is stored in the configured file, is never sent to a service, and can be cleared with `Ctrl+Alt+Shift+F3` or the `adwisp-clear-recent` script message. The panel supports mouse-wheel and Up/Down selection, Enter to reopen an item, and page navigation for longer lists.

### Theme palette

Set `theme_file` to an absolute path to a UTF-8 key/value file:

```ini
background=#1d1a20
surface=#29252d
text=#f5eff7
muted=#cac3cf
accent=#d0bcff
on_accent=#381e72
```

Supported roles are `background`, `surface`, `text`, `muted`, `accent`, and `on_accent`. Values must be six-digit `#RRGGBB` colors; keys are case-sensitive. Invalid entries produce line-specific warnings. Valid entries still load, while missing roles use the fallback palette. See `docs/THEMING.md` for details.

After regenerating a palette, reload it without restarting mpv:

```text
/script-message adwisp-reload-theme
```

### Thumbnail previews

Install thumbfast as an mpv script and keep `thumbnail_preview=yes`. Project page: https://github.com/po5/thumbfast. Adwisp requests previews while the pointer is over the timeline and asks thumbfast to clear them when appropriate.

Press `Ctrl+Alt+F7` while a preview is visible to export it as a BMP image. The configured export directory must already exist. Preview and export features are unavailable when thumbfast is absent. This integration still needs manual validation in a real mpv session.

## Script-message API

Other mpv scripts and external controllers can send these messages to Adwisp. Each message takes no arguments; unexpected arguments are rejected with a warning and do not change the interface state.

| Message | Action |
| --- | --- |
| `adwisp-show` | Show the OSD |
| `adwisp-hide` | Hide the OSD and clear active interaction/preview state |
| `adwisp-toggle` | Toggle OSD visibility |
| `adwisp-reload-theme` | Reload the configured theme |
| `adwisp-recent` | Open the recent-files panel (requires opt-in history) |
| `adwisp-clear-recent` | Clear the local recent-file history |
| `adwisp-query` | Print a JSON snapshot of the current UI/playback state to mpv's log |

From another mpv Lua script:

```lua
mp.commandv("script-message-to", "adwisp", "adwisp-show")
mp.commandv("script-message-to", "adwisp", "adwisp-query")
```

From mpv's command line:

```sh
mpv --script-message adwisp-show
```

The query response includes visibility, pause state, playback position and duration, volume and mute state, playlist position/count, cache-buffering state/progress, keyboard focus target, and image-viewer mode/zoom. It is printed even when `log_level=quiet`; other informational and debug messages still follow the configured logging level.
