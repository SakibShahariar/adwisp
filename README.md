# Adwisp

**A GTK4/libadwaita-inspired interface for mpv, written in Lua.**

Adwisp is an experimental mpv script exploring a cohesive desktop-player interface inspired by GTK4 and libadwaita. It draws its controls with mpv's ASS OSD overlay; it is **not** a native GTK wrapper and is not based on uosc.

> **Project status: experimental prototype.** The current implementation includes an OSD control bar, keyboard and mouse actions, a semantic palette loader, and an optional thumbfast adapter. Runtime behavior—especially mouse interaction, rendering across mpv versions, and thumbnail previews—still needs broader manual validation. A preferences window is planned, not implemented.

## Current features

- OSD interface with media title, playback timeline, time labels, volume display, and playlist navigation.
- Keyboard controls for showing/dismissing the interface, seeking, and play/pause.
- Mouse clicks for timeline seeking, play/pause, volume level, and previous/next playlist navigation.
- Event-driven updates from mpv properties, with duplicate-render suppression.
- Semantic theme palette with a built-in fallback and explicit reload message.
- Optional seek-preview requests through [thumbfast](https://github.com/po5/thumbfast); Adwisp does not generate thumbnails itself.

These features are still under active development. Automated tests and CI checks are useful safeguards, but do not replace testing in a real mpv session.

## Requirements

- [mpv](https://mpv.io/) with Lua scripting support.
- Optional: [thumbfast](https://github.com/po5/thumbfast) for timeline thumbnail previews.
- Optional: [Matugen](https://github.com/InioX/matugen) if you want to generate your own palette. Adwisp reads a palette file; it does not run Matugen.

## Installation

Adwisp is currently installed manually; a package or release installer is not yet provided.

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
| `Ctrl` + `Up` / `Ctrl` + `Down` | Increase / decrease volume by `volume_step` |
| `q` | Dismiss the interface |
| Mouse click on timeline | Seek to the clicked position |
| Mouse click on playback control | Toggle pause |
| Mouse click on volume bar | Set volume and unmute |
| Mouse click on left/right playlist control | Previous / next playlist item |

Mouse and OSD behavior can vary with mpv configuration and platform; please report issues with your mpv version and relevant logs.

## Configuration

Adwisp uses mpv's standard script options. Edit `script-opts/adwisp.conf` in your mpv configuration directory:

```ini
# Seek distance in seconds for Left / Right
seek_step=5

# Volume change per Ctrl+Up / Ctrl+Down press
volume_step=5

# Set to no to disable the optional thumbfast preview adapter
thumbnail_preview=yes

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

Supported roles are `background`, `surface`, `text`, `muted`, `accent`, and `on_accent`; values must be six-digit `#RRGGBB` colors. Missing or invalid entries fall back to the built-in palette. See [Theming and Matugen](docs/THEMING.md) for details.

After regenerating the palette, ask mpv to reload it without restarting:

```text
/script-message adwisp-reload-theme
```

### Thumbnail previews

Install [thumbfast](https://github.com/po5/thumbfast) as an mpv script and leave `thumbnail_preview=yes`. Adwisp sends preview requests while the pointer is over the timeline and asks thumbfast to clear the preview when appropriate. If thumbfast is absent or unavailable, previews are not provided. This integration still needs manual validation in a real mpv session.

## Development

The project is modular Lua. See [Architecture](docs/ARCHITECTURE.md) for design boundaries and performance principles.

Before opening a pull request, run the repository's CI checks locally where the required tools are installed. CI checks Lua syntax, runs Luacheck, and executes the automated tests. Keep changes event-driven: avoid idle polling, unnecessary redraws, and unbounded caches.

Please include the mpv version, operating system, steps to reproduce, and relevant logs in bug reports. Commit messages should follow [Conventional Commits](https://www.conventionalcommits.org/), for example `feat(controls): add playback controls` or `docs(readme): refresh setup guide`.

## Roadmap

- [x] Modular Lua entry point and shared playback state
- [x] Event-driven property observers and OSD rendering
- [x] Keyboard controls and initial mouse actions
- [x] Semantic palette loading and explicit theme reload
- [x] Initial thumbfast preview adapter
- [ ] Validate controls, OSD behavior, and thumbfast integration in real mpv sessions
- [ ] Improve volume interaction and responsive control behavior
- [ ] Preferences/settings interface
- [ ] Accessibility, localization, and configurable shortcuts
- [ ] Benchmark idle CPU use and redraw behavior against stock mpv and uosc
- [ ] Packaging, screenshots, and release workflow

## License

MIT. See [LICENSE](LICENSE).
