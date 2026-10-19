# Architecture

## Current prototype

`adwisp.lua` is the entry point loaded by mpv. It observes playback properties with `mp.observe_property`, stores the latest values in a small state table, and redraws an ASS OSD overlay when an observed value changes. There is no periodic polling loop.

## Intended modules

As the project grows, split responsibilities into small modules:

- **State:** normalized playback state and property observers.
- **Theme:** built-in palette, Matugen palette parsing, reload notifications.
- **Layout:** responsive measurements based on mpv's OSD size.
- **Controls:** seek, pause, volume, playlist and fullscreen actions.
- **Preferences:** settings UI and persisted options.
- **Thumbnail adapter:** optional communication with thumbfast; no duplicate thumbnail extraction pipeline.

## Performance rules

1. No idle polling or unconditional frame timers.
2. Observe properties and invalidate only the affected UI where practical.
3. Cache parsed theme data and reusable assets.
4. Keep caches bounded and release per-file resources on `end-file`.
5. Request thumbnail work lazily and asynchronously through thumbfast.
6. Benchmark idle and active playback, including high-resolution video and long playlists.
7. Compare like-for-like against stock mpv and uosc, recording mpv version, resolution, idle CPU usage and redraw frequency.

## Current limitations

The prototype is not yet a full player interface. The visible controls are illustrative OSD text and are not mouse-hit-tested widgets. The preferences UI, Matugen file parsing/reload, and thumbfast integration remain planned work.
