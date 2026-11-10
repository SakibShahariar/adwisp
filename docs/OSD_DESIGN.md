# OSD design principles

Adwisp is an mpv Lua script rendered through ASS OSD. This document defines how the interface should apply GNOME Human Interface Guidelines (HIG) and the GTK4/libadwaita visual language without pretending that ASS is GTK.

## Design intent

The OSD should feel like a coherent GNOME media interface: calm, legible, purposeful, and consistent. It should keep playback controls easy to discover while allowing the video to remain the primary content.

Use the current GNOME HIG and relevant Libadwaita patterns as design references. When a native pattern cannot be reproduced faithfully in ASS, preserve its interaction principle rather than imitating a widget superficially.

## Pattern mapping

| GNOME / Libadwaita principle | Adwisp OSD application |
| --- | --- |
| Clear page and content hierarchy | Distinct media title/status, primary playback controls, timeline, and secondary actions |
| Consistent spacing scale | Shared spacing tokens in layout calculations; align related controls and preserve deliberate grouping |
| Familiar button affordances | Consistent dimensions and states for playback, playlist, and auxiliary actions |
| Slider behavior | A readable timeline with a generous stable hit target, clear elapsed/remaining time, and visible progress |
| Popovers and menus | Anchored, bounded selection panels with clear headings, selected states, keyboard navigation, and dismissal |
| Surface hierarchy | Semantic background/surface roles; restrained separation and no arbitrary per-widget colors |
| Typography hierarchy | Readable title, secondary metadata, and control labels with consistent font scaling |
| Keyboard accessibility | Visible focus, logical navigation, activation, and no mouse-only functionality |
| Responsive behavior | Reflow or simplify nonessential content before allowing overlap or clipping |
| Motion restraint | Short, purposeful transitions; no polling or animation that causes needless redraws |

## Layout hierarchy

1. **Media identity:** Show the title and only status information useful in the current playback state.
2. **Primary transport:** Make play/pause and seek/navigation the most discoverable actions.
3. **Timeline:** Give progress and seeking a dedicated row. Keep time labels legible and the hit region stable when the visual track changes.
4. **Volume and secondary actions:** Keep these visually grouped but subordinate to transport and timeline.
5. **Secondary panels:** Playlist, track, chapter, library, and settings surfaces should share a consistent panel grammar and selection behavior.

Do not force every status item or action into the main row. Prioritize by frequency and context; put less frequent actions in a secondary panel.

## Semantic color contract

- All renderer colors must come from the active semantic palette.
- Matugen-generated palette files are the intended dynamic color source when configured.
- Use semantic roles (`background`, `surface`, `text`, `muted`, `accent`, `on_accent`) rather than embedding hex values in individual controls.
- Built-in colors are fallback values only; they must not override a valid user-generated palette.
- Validate contrast for text and focus/selection states. Do not silently rewrite user colors.
- Do not treat palette changes as a substitute for correcting layout, hierarchy, typography, or interaction.

## ASS and mpv constraints

- ASS OSD is not a native GTK widget tree. Native Adwaita widgets, platform accessibility semantics, and GTK layout containers cannot be assumed.
- Use shared geometry from `core/layout.lua` for drawing and hit-testing; avoid duplicated coordinates.
- Keep drawing in `core/renderer.lua` and interaction/state ownership in their existing modules.
- Keep hit targets generous and stable even when visual elements are compact.
- Escape user-provided and translated text before inserting it into ASS.
- Preserve mpv keyboard bindings, script-message APIs, localization, and existing playback behavior.
- Avoid file polling, per-frame layout churn, and unnecessary OSD updates.

## Validation

Automated tests should cover geometry, bounds, hit targets, focus/selection output, semantic palette use, and compact layouts. These tests cannot prove that the OSD looks or feels correct.

Before calling the redesign complete, inspect it in real mpv with small, standard, and large window sizes; windowed and fullscreen playback; mouse and keyboard-only interaction; long titles and dense status metadata; playlist and track menus; and Matugen-generated palettes, including contrasting light and dark outputs where available.

Record the mpv version and remaining visual/interaction issues. Keep manual-validation criteria open until this inspection is actually performed.
