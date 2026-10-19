# Adwisp

**A GTK-inspired, Matugen-powered Lua interface for mpv.**

Adwisp is an mpv Lua script project aiming to give mpv a cohesive, modern desktop-player interface inspired by GTK4 and libadwaita. It draws its interface inside mpv; it is **not** a GTK wrapper and is not based on uosc.

> **Status: early scaffold.** The current code is a small, experimental OSD prototype. The complete player UI and preferences window remain planned. The current prototype includes an initial thumbfast seek-preview adapter and explicit theme reload; these integrations need real-mpv validation.

## Goals

- A polished, libadwaita-inspired playback UI rendered through mpv's OSD overlay.
- Playback controls, seek bar, time display, volume, playlist navigation, and keyboard accessibility.
- A preferences experience for common settings, so users do not need to hand-edit configuration files.
- Matugen-compatible colors with a clear fallback theme.
- Optional thumbnail previews using the existing [thumbfast](https://github.com/po5/thumbfast) script rather than implementing a second thumbnail generator.
- Event-driven updates and bounded work: observe mpv properties, avoid idle polling, and cache expensive resources.
- Measure performance against stock mpv and uosc as the UI grows.

## Requirements

- mpv with Lua scripting enabled.
- Optional: [Matugen](https://github.com/InioX/matugen) and a generated color palette.
- Optional: [thumbfast](https://github.com/po5/thumbfast) for seek-preview thumbnails.

## Install (development)

1. Copy `adwisp.lua` **and the entire `core/` directory** into your mpv scripts directory (keep the directory structure):
   - Linux: `~/.config/mpv/scripts/`
   - Windows: `%APPDATA%/mpv/scripts/`
   - macOS: `~/.config/mpv/scripts/`
2. Start or restart mpv.
3. Press `g` to toggle the prototype overlay. Press `Left` / `Right` to seek while the overlay is visible, or `q` to dismiss it.

The prototype intentionally uses mpv's ASS OSD overlay, not native GTK widgets. The entry point delegates playback-state defaults to `core/state.lua`, geometry to `core/layout.lua`, and drawing to `core/renderer.lua`. The layout module is pure Lua so rendering and future mouse hit-testing can share the same rectangles. Packaging and configuration options will evolve as the project develops.

## Configuration

The current prototype supports only `seek_step` through mpv's standard `script-opts` mechanism. Create `script-opts/adwisp.conf` in your mpv config directory:

```ini
# Seek step in seconds
seek_step=5

```

Set optional `theme_file=/absolute/path/to/palette.conf` to load a Matugen-compatible `key=value` palette. Run `/script-message adwisp-reload-theme` after regenerating it to reload colors without restarting mpv. The preferences UI is on the roadmap. To enable seek previews, install `thumbfast.lua` in mpv’s scripts directory; Adwisp requests thumbnails when hovering the timeline and clears them when the pointer leaves. Previews are silently unavailable when thumbfast is not installed. Set `thumbnail_preview=no` in `script-opts/adwisp.conf` to disable the integration.

## Roadmap

- [x] Establish repository and basic Lua entry point
- [x] Event-driven playback property observers
- [x] Minimal OSD prototype and keyboard controls
- [x] Initial separation of playback state and ASS rendering
- [x] Pure layout geometry foundation
- [ ] Mouse hit-testing and responsive control bar
- [ ] Playback controls, playlist and volume UI
- [ ] Preferences/settings interface
- [ ] Matugen palette parser and reliable live reload
- [x] Initial thumbfast seek-preview integration (needs real-mpv validation)
- [ ] Accessibility, localization, and configurable shortcuts
- [ ] Benchmark idle CPU use and redraw behavior against stock mpv and uosc
- [ ] Packaging, screenshots, and release workflow

## Contributing

Issues and focused pull requests are welcome. Please include mpv version, operating system, and relevant logs when reporting bugs. Pull request commits must follow [Conventional Commits](https://www.conventionalcommits.org/), for example `feat(renderer): add playback controls` or `fix(input): handle seek clicks`; a GitHub Actions check validates commit messages. The CI workflow runs Lua syntax checks, Luacheck, and layout unit tests on pushes and pull requests. Avoid adding per-frame polling or unbounded caches; performance is a core design goal.

## License

MIT. See [LICENSE](LICENSE).
