# Adwisp

**A GTK4/libadwaita-inspired interface for mpv, written in Lua.**

Adwisp is an experimental mpv script that draws a desktop-player-style interface with mpv's ASS OSD. It is not a native GTK application and does not depend on uosc.

> [!WARNING]
> Adwisp is an experimental prototype. Automated tests cover core logic, but mouse interaction, rendering across mpv versions, and optional thumbnail previews still need broader real-world testing. A preferences window is planned, not implemented.

## Features

- Playback controls, timeline, time labels, volume, and playlist navigation.
- Keyboard and mouse interaction, including timeline and volume dragging.
- Keyboard focus and navigation for playback controls.
- Persistent, searchable playlist panel with wheel scrolling, paging, and item removal.
- Optional local recent-file history, disabled by default.
- UTF-8 locale-file overrides and theme contrast warnings.
- Searchable chapter, audio-track, and subtitle-track menus.
- Still-image fit, zoom, and reset controls using mpv's native video properties.
- Event-driven updates, buffering feedback, and optional idle hiding.
- Semantic color palettes, with optional Matugen palette generation and thumbfast preview integrations.

## Requirements

- mpv with Lua scripting support. Project: https://mpv.io/
- Optional thumbfast for timeline previews. Project: https://github.com/po5/thumbfast
- Optional Matugen palette generation. Project: https://github.com/InioX/matugen. Adwisp only reads the resulting palette file.

## Installation

Download the ZIP asset when a release is published: https://github.com/SakibShahariar/adwisp/releases. Extract it into your mpv configuration directory. The archive provides the `scripts/adwisp/` and `script-opts/` layout.

To install from source, copy:

- `adwisp.lua` and the complete `core/` directory to `~/.config/mpv/scripts/adwisp/`.
- `script-opts/adwisp.conf` to `~/.config/mpv/script-opts/adwisp.conf`.

Restart mpv and open a media file. Press `g` to show or hide Adwisp (the default binding).

## Quick controls

| Key | Action |
| --- | --- |
| `g` | Toggle the interface |
| `q` / `Esc` | Dismiss the interface |
| `Left` / `Right` | Seek |
| `Space` | Play or pause |
| `m` | Toggle mute |
| `Ctrl+Left` / `Ctrl+Right` | Previous or next playlist item |
| `Ctrl+Alt+F3` | Open recent files (opt-in history) |
| `Ctrl+Alt+Shift+F3` | Clear recent-file history |
| `Ctrl+Alt+F12` | Toggle the playlist panel |
| `Ctrl+Up` / `Ctrl+Down` | Adjust volume |

Full keyboard/mouse reference, configuration options, and script-message API: `docs/USAGE.md`.

## Documentation

- [Usage and controls](docs/USAGE.md)
- [Theming and Matugen](docs/THEMING.md)
- [Architecture](docs/ARCHITECTURE.md)
- [OSD design principles (GNOME HIG and Libadwaita)](docs/OSD_DESIGN.md)
- [Real-mpv testing checklist](docs/MPV_TESTING.md)

## Development

Adwisp is modular Lua. CI checks Lua syntax, runs Luacheck, and executes the automated test suite. Architecture details: `docs/ARCHITECTURE.md`. Before a release, complete `docs/MPV_TESTING.md`.

When reporting a bug, include your mpv version, operating system, reproduction steps, and relevant logs.

## Roadmap

Current priorities are real-mpv validation, a preferences interface, accessibility/localization polish, performance measurements, and release polish. Implementation status: https://github.com/SakibShahariar/adwisp/issues.

## License

MIT License. See the `LICENSE` file.
