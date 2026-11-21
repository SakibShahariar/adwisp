# OSD design specification

Adwisp draws its interface with mpv's ASS overlay. It is **inspired by** GTK4 and
libadwaita, not built with them. This document maps the relevant GNOME HIG ideas
to what ASS can actually render, and records the deliberate limitations.

## Principles

| HIG / libadwaita pattern | Adwisp implementation | ASS limitation |
| --- | --- | --- |
| Elevated, rounded surfaces | Layered rounded rectangles: offset shadow, hairline border, panel body | Flat 2D shapes; no real blur or window shadow |
| Header / title hierarchy | Title at 26px bold, status chips right-aligned, 1px divider | Single font family per run; font availability varies by system |
| Button groups | Circular prev/next buttons and a pill-shaped primary play/pause button | Icons are vector paths, not themed icon assets |
| Sliders | Rounded track, filled portion, and a 12px knob for volume and timeline | No native widget states; hit targets are separate rectangles |
| Focus and hover | Accent outline for keyboard focus, subtle surface fill for hover | Focus ring is a drawn outline, not the platform focus indicator |
| Disabled / unavailable state | Playlist navigation is hidden entirely for single-item playlists | Text-based labels remain for accessibility and localization |
| 8px spacing grid | Header, control, timeline, and label bands use consistent gaps | Pixel rounding is applied to every coordinate |

## Layout bands

The primary layout mirrors the GTK-style player concept: a translucent bottom
scrim spanning the full OSD width, with four bands of information.

```
+--------------------------------------------------------------+
|                         video                                |
|                                                              |
|  [thumb] Title                                   status       |  media row
|  --------------------------o---------------------------------  |  timeline
|  0:15 / 1:00                                                  |  labels
|                    <   ( play )   >        speaker --o-- []  |  transport
+--------------------------------------------------------------+
```

- The scrim is a stacked set of translucent bands forming a soft gradient.
- The timeline is a thin full-width line with a circular knob.
- Prev/play/next are symbolic glyphs; only play has a filled accent circle.
- Volume, fullscreen, and settings icons sit on the right of the transport row.
- Short and narrow OSDs shrink the scrim and hide secondary labels, keeping the
  timeline and transport inside the visible area.

## Color roles

Colors come from `core/theme.lua` semantic roles: `background`, `surface`,
`text`, `muted`, `accent`, and `on_accent`. Matugen palettes map onto these
roles at runtime; the built-in palette is only a fallback and mirrors
a dark navy style with a blue accent, matching the project's GTK player concept. The default text
font is Adwaita Sans, with `font_family`/`font_scale` available as overrides.
The renderer never hard-codes a new static palette for individual widgets.

## Interaction and accessibility

- Every visible control has a matching hit rectangle from `core/layout.lua`.
- Keyboard focus cycles through playback, volume, playlist, and timeline.
- Text labels (play/pause, volume, progress, time, playlist position) remain in
  the output so localization and screen-reader-adjacent tooling keep working.
- Motion is limited to the existing opacity fade; no new timers or polling are
  introduced by the visual design.

## Known limitations

- Rendering varies with mpv version, libass build, font availability, display
  scaling, and window system. Validate visually in real mpv before release.
- Icons are hand-built vector approximations and may not match a specific
  libadwaita icon set pixel for pixel.
- The ASS overlay cannot provide true window elevation, native focus rings, or
  platform accessibility metadata.
