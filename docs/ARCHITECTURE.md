# Architecture

## Current prototype

`adwisp.lua` is the mpv entry point. It reads script options, observes playback properties, updates shared state, and routes render requests to the renderer. Project-local modules are loaded relative to the script directory.

- `core/state.lua`: defaults for the shared playback state.
- `core/renderer.lua`: ASS OSD overlay creation, time formatting, drawing, and duplicate-frame suppression.
- `adwisp.lua`: mpv property observers, events, keyboard bindings, and script messages.

The state module intentionally contains defaults only for now. Property observation remains in the entry point so the mpv integration lifecycle is explicit.

## Intended modules

As the project grows, split responsibilities into small modules:

- **State:** normalized playback state and property observers.
- **Theme:** built-in palette, Matugen palette parsing, reload notifications.
- **Layout:** responsive measurements based on mpv's OSD size.
- **Controls:** seek, pause, volume, playlist and fullscreen actions.
- **Preferences:** settings UI and persisted options.
- **Thumbnail adapter:** optional communication with thumbfast; no duplicate thumbnail extraction pipeline.

## Rendering and performance rules

1. No idle polling or unconditional frame timers.
2. Observe mpv properties and render only when relevant state changes.
3. Keep rendering and mpv commands separate from state defaults.
4. Cache reusable theme data and assets once those systems exist.
5. Keep caches bounded and release per-file resources on `end-file`.
6. Request thumbnail work lazily through thumbfast.
7. Benchmark idle and active playback against stock mpv and uosc, recording mpv version, resolution, idle CPU usage and redraw frequency.

## Current limitations

The prototype is an early OSD experiment, not a complete player UI. The displayed labels are not yet mouse-hit-tested controls. The preferences UI, Matugen parsing/live reload, thumbnail previews, and performance benchmarks remain planned. The renderer has not yet been validated across mpv versions and operating systems; report issues with mpv version and logs.
