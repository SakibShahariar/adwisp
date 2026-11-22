# Main window spec (derived from the design mockup)

All measurements are for a 1920x1080 OSD; scale by `ui_scale` at runtime.

## Title bar (top, full width, height 48)
- Hamburger icon at x=24, vertically centered
- "mpv" centered horizontally, font 20 bold
- Window controls at right: minimize, maximize, close (close uses accent fill)

## Video area
- Full-bleed: the video fills the window; no letterboxing (`panscan=1` in mpv.conf)

## Bottom control area (height 180, anchored to bottom)
Three bands, top to bottom:

1. **Media row** (y = top + 16, height 40):
   - Rounded thumbnail placeholder at x=24, 40x40
   - Media title to its right at x=76, font 15
   - At right: fullscreen icon and "..." menu icon

2. **Timeline** (y = top + 68, height 5):
   - x=24 to width-24, muted track, accent fill to current position
   - 12px circular knob at the playhead

3. **Control row** (y = top + 108, height 48):
   - Time label "current / total" at x=24, font 14
   - Centered group: loop icon, prev, **accent-filled circular play/pause (56px)**, next, loop icon
   - Right group: speaker icon + volume slider (120px), fullscreen, settings gear

## Scrim
Dark surface behind the control area. ASS alpha: `&H00&` = opaque, `&HFF&` = transparent.
Gradient from `&H50&` (31% opaque) at the top edge to `&H0A&` (96% opaque) at the bottom.

## Colors
All from the active semantic palette: `background`, `surface`, `text`, `muted`, `accent`,
`on_accent`. No fixed per-widget colors.
