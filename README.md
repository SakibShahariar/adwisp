# Adwisp

**A GTK4/libadwaita-inspired interface for mpv, written in Lua.**

Adwisp is an experimental mpv script exploring a cohesive desktop-player interface inspired by GTK4 and libadwaita. It draws its controls with mpv's ASS OSD overlay; it is **not** a native GTK wrapper and is not based on uosc.

> **Project status: experimental prototype.** The current implementation includes an OSD control bar, keyboard and mouse actions, a semantic palette loader, and an optional thumbfast adapter. Runtime behavior—especially mouse interaction, rendering across mpv versions, and thumbnail previews—still needs broader manual validation. A preferences window is planned, not implemented.

## Current features

- OSD interface with media title, playback timeline, time labels, volume display, and playlist navigation with current-item position.
- Keyboard controls for showing/dismissing the interface, seeking, and play/pause.
- Mouse clicks and dragging for timeline seeking and volume adjustment, plus play/pause and previous/next playlist navigation.
- Hover feedback for interactive controls; active drag state is cancelled when the UI is dismissed or a file ends.
- Event-driven updates from mpv properties, with duplicate-render suppression.
- A theme-aware buffering indicator driven by mpv's cache-pause and buffering-progress properties.
- Chapter navigation shortcuts, clickable timeline chapter markers, and the current chapter title when the media provides chapter metadata.
- Audio/subtitle track cycling with the active track's language, title, and codec shown when available.
- Optional event-driven idle hiding with a short ASS opacity fade; disabled by default.
- Semantic theme palette with a built-in fallback and explicit reload message.
- Optional seek-preview requests through [thumbfast](https://github.com/po5/thumbfast), with a timestamp label beside the preview; Adwisp can export the active preview as a BMP image.

These features are still under active development. Automated tests and CI checks are useful safeguards, but do not replace testing in a real mpv session.

## Requirements

- [mpv](https://mpv.io/) with Lua scripting support.
- Optional: [thumbfast](https://github.com/po5/thumbfast) for timeline thumbnail previews.
- Optional: [Matugen](https://github.com/InioX/matugen) if you want to generate your own palette. Adwisp reads a palette file; it does not run Matugen.

## Installation

Tagged releases include a ready-to-extract ZIP archive. Download `adwisp-vX.Y.Z.zip` from the [GitHub Releases](https://github.com/SakibShahariar/adwisp/releases) page and extract its contents into your mpv configuration directory (for example, `~/.config/mpv/`). The archive contains `scripts/adwisp/` and `script-opts/` in the expected layout.

To install from source instead:

1. Create a script directory, for example `~/.config/mpv/scripts/adwisp/`.
2. Copy `adwisp.lua` and the complete `core/` directory into that directory. Keep the directory structure intact:
   ```text
   mpv/
   ├── scripts/
   │   └── adwisp/
   │       ├── adwisp.lua
   │       └── core/
   │           ├── layout.lua
   │           ├── renderer.lua
   │           ├── state.lua
   │           └── theme.lua
   └── script-opts/
       └── adwisp.conf
   ```
3. Copy `script-opts/adwisp.conf` from this repository to your mpv configuration's `script-opts/` directory (create the directory if needed).
4. Restart mpv and open a media file. Adwisp logs a startup message; press `g` to toggle the interface.

Typical mpv configuration directories:

- Linux: `~/.config/mpv/`
- Windows: `%APPDATA%/mpv/`
- macOS: `~/.config/mpv/`

## Controls

| Input | Action |
| --- | --- |
| `g` | Toggle the Adwisp interface |
| `Left` / `Right` | Seek backward / forward by `seek_step` seconds |
| `Space` | Toggle playback pause |
| `m` | Toggle mute |
| `Ctrl` + `Left` / `Ctrl` + `Right` | Previous / next playlist item |
| `Ctrl` + `Page Up` / `Ctrl` + `Page Down` | Previous / next chapter when available |
| `Ctrl` + `Alt` + `F8` | Show chapter titles and timestamps |
| `Ctrl` + `Alt` + `F9` | Open the audio-output device menu; select with `Ctrl+Alt+1–9` |
| `Ctrl` + `Alt` + `F5` | Cycle audio tracks |
| `Ctrl` + `Alt` + `F6` | Cycle subtitle tracks (including Off) |
| `Ctrl` + `Alt` + `F10` | Open the audio track menu; select with `Ctrl+Alt+1–9` |
| `Ctrl` + `Alt` + `F11` | Open the subtitle track menu; select with `Ctrl+Alt+1–9` |
| `Ctrl` + `Alt` + `F12` | Open the playlist view; select with `Ctrl+Alt+1–9`, remove with `Ctrl+Alt+Shift+1–9` |

When the playlist menu is open, type to filter by title or filename; use Up/Down and Enter to select, Ctrl+Backspace to clear the search, and Esc to close. If text input is unsupported by the mpv build, the existing numbered controls remain available. Audio and subtitle track menus also accept search over their displayed language, title, and codec labels.
| `Ctrl` + `Alt` + `Page Up/Down` | Previous / next playlist page |
| `Ctrl` + `Up` / `Ctrl` + `Down` | Increase / decrease volume by `volume_step`; volume changes also unmute |
| `Ctrl` + `Alt` + `Up` / `Ctrl` + `Alt` + `Down` | Increase / decrease playback speed by `speed_step` |
| `Ctrl` + `Alt` + `Backspace` | Reset playback speed to 1× |
| `Ctrl` + `Alt` + `L` | Toggle infinite looping of the current file |
| `Ctrl` + `Alt` + `A` | Cycle A-B loop points: set A, set B, clear |
| `Ctrl` + `Alt` + `S` | Take a screenshot using mpv |
| `Ctrl` + `Alt` + `F7` | Export the current thumbfast preview as a BMP image |

| `Tab` / `Shift+Tab` | Move keyboard focus between playback, volume, and playlist controls |
| `Enter` | Activate the focused control |
| `Left` / `Right` while volume or playlist is focused | Adjust volume or move through the playlist |
| `q` | Dismiss the interface |
| `Escape` | Close an open selection menu; otherwise dismiss the interface |
| Mouse click on timeline | Seek to the clicked position |
| Mouse click on playback control | Toggle pause |
| Mouse click on volume bar | Set volume and unmute |
| Drag volume bar | Adjust volume continuously while dragging |
| Drag timeline | Seek continuously while dragging |
| Mouse click on left/right playlist control | Previous / next playlist item |

Keyboard focus is visible with the active theme accent. With no control focused, Left/Right retain their normal seek behavior. In minimal-timeline mode, hovering or keyboard-focusing the timeline expands it; Left/Right seek while it is focused.

The audio-output menu uses mpv's `audio-device-list` and `audio-device` properties. Its selected marker identifies the configured/requested target, not a guaranteed physical endpoint currently in use; mpv does not expose that endpoint through `audio-device`. Available names and descriptions depend on the active audio backend.

Mouse and OSD behavior can vary with mpv configuration and platform; please report issues with your mpv version and relevant logs.

## Script-message API

Other mpv scripts and external controllers can send these messages to Adwisp.
Each message takes **no arguments**; unexpected arguments are rejected with a
warning and do not change the interface state.

| Message | Action |
| --- | --- |
| `adwisp-show` | Show the OSD |
| `adwisp-hide` | Hide the OSD and clear active interaction/preview state |
| `adwisp-toggle` | Toggle OSD visibility |
| `adwisp-reload-theme` | Reload the configured theme |
| `adwisp-query` | Print a JSON snapshot of the current UI/playback state to mpv's log |

From another mpv Lua script, target Adwisp directly:

```lua
mp.commandv("script-message-to", "adwisp", "adwisp-show")
mp.commandv("script-message-to", "adwisp", "adwisp-query")
```

From mpv's command line, broadcast a message to scripts:

```sh
mpv --script-message adwisp-show
```

The query response includes visibility, pause state, playback position and
duration, volume and mute state, playlist position/count, and cache-buffering
state/progress. It is an explicit response and is printed even when
`log_level=quiet`. Other informational and debug messages still follow the
configured logging level.

## Configuration

Adwisp uses mpv's standard script options. Edit `script-opts/adwisp.conf` in your mpv configuration directory. Core bindings can be remapped independently; duplicate Adwisp bindings are detected and the later action falls back to its default.

```ini
# Seek distance in seconds for Left / Right
seek_step=5

# Volume change per Ctrl+Up / Ctrl+Down press
volume_step=5
# Playback-speed change per Ctrl+Alt+Up / Ctrl+Alt+Down press
speed_step=0.1

# Core keyboard bindings
toggle_key=g
dismiss_key=q
dismiss_escape_key=ESC
seek_back_key=LEFT
seek_forward_key=RIGHT
volume_up_key=CTRL+UP
volume_down_key=CTRL+DOWN
mute_toggle_key=m
playlist_prev_key=CTRL+LEFT
playlist_next_key=CTRL+RIGHT

# Loop, A-B repeat, and screenshot key bindings
loop_toggle_key=CTRL+ALT+L
ab_loop_key=CTRL+ALT+A
screenshot_key=CTRL+ALT+S

# Set to no to disable the optional thumbfast preview adapter
thumbnail_preview=yes

# Existing directory and filename prefix for exported BMP previews
thumbnail_export_directory=~~/
thumbnail_export_prefix=adwisp-thumbnail

# Playback-position OSD rebuild interval in seconds (0.05–0.5)
time_pos_render_interval=0.15

# Collapse the timeline to a progress-only line until hovered or focused
minimal_timeline=no

# OSD placement: bottom, top, or custom
osd_position=bottom

# Edge margin in pixels; -1 keeps the responsive default
osd_margin=-1

# Top-origin vertical offset in pixels when osd_position=custom
osd_custom_offset=120

# Font family and scale (scale is clamped to 0.75–1.25)
font_family=Sans
font_scale=1.0

# Auto-hide after this many seconds of inactivity; 0 disables it
idle_hide_timeout=0
# Fade duration in seconds (0.05–1.0)
fade_duration=0.25

# Logging verbosity: quiet, info, or debug
log_level=info

# Optional absolute path to a semantic palette file
theme_file=
```

### Theme palette

Set `theme_file` to an absolute path to a UTF-8 key/value file. For example:

```ini
background=#1d1a20
surface=#29252d
text=#f5eff7
muted=#cac3cf
accent=#d0bcff
on_accent=#381e72
```

Supported roles are `background`, `surface`, `text`, `muted`, `accent`, and `on_accent`; values must be six-digit `#RRGGBB` colors. Keys are case-sensitive. Unknown keys, malformed entries, and invalid colors produce line-specific warnings; valid entries still load while missing roles use the fallback. If a file cannot be read or contains no valid entries, the last successfully loaded palette remains active. See [Theming and Matugen](docs/THEMING.md) for details.

After regenerating the palette, ask mpv to reload it without restarting:

```text
/script-message adwisp-reload-theme
```

### Script messages

See the [Script-message API](#script-message-api) section for the complete message list and usage examples.

### Thumbnail previews

Install [thumbfast](https://github.com/po5/thumbfast) as an mpv script and leave `thumbnail_preview=yes`. Adwisp sends preview requests while the pointer is over the timeline and asks thumbfast to clear the preview when appropriate. Press `Ctrl+Alt+F7` while a preview is visible to export it as a BMP file. The configured export directory must already exist. If thumbfast is absent or unavailable, previews and export are unavailable. This integration still needs manual validation in a real mpv session.

## Development

The project is modular Lua. See [Architecture](docs/ARCHITECTURE.md) for design boundaries and performance principles.

Before opening a pull request, run the repository's CI checks locally where the required tools are installed. CI checks Lua syntax, runs Luacheck, and executes the automated tests. Keep changes event-driven: avoid idle polling, unnecessary redraws, and unbounded caches. Before a release, also complete the [real-mpv integration checklist](docs/MPV_TESTING.md) and record the environment and results.

Please include the mpv version, operating system, steps to reproduce, and relevant logs in bug reports. Commit messages should follow [Conventional Commits](https://www.conventionalcommits.org/), for example `feat(controls): add playback controls` or `docs(readme): refresh setup guide`.

## Roadmap

- [x] Modular Lua entry point and shared playback state
- [x] Event-driven property observers and OSD rendering
- [x] Keyboard controls and initial mouse actions
- [x] Semantic palette loading and explicit theme reload
- [x] Initial thumbfast preview adapter
- [ ] Validate controls, OSD behavior, and thumbfast integration in real mpv sessions
- [x] Improve volume interaction and responsive control behavior
- [ ] Preferences/settings interface
- [ ] Accessibility, localization, and configurable shortcuts
- [ ] Benchmark idle CPU use and redraw behavior against stock mpv and uosc
- [ ] Packaging, screenshots, and release workflow

## License

MIT. See [LICENSE](LICENSE).
