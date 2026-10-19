# Theming and Matugen

Adwisp supports a small semantic palette file compatible with common Matugen-generated key/value output. It does not invoke Matugen itself.

## Palette file

Create a UTF-8 text file wherever you keep generated themes:

```ini
background=#1d1a20
surface=#29252d
text=#f5eff7
muted=#cac3cf
accent=#d0bcff
on_accent=#381e72
```

Supported keys are `background`, `surface`, `text`, `muted`, `accent`, and `on_accent`. Values must be six-digit `#RRGGBB` colors. Missing or invalid entries use the built-in fallback palette; unknown keys are ignored.

Set `theme_file` in `script-opts/adwisp.conf` to the palette's path, for example:

```ini
theme_file=/home/you/.config/matugen/adwisp.conf
```

Use an absolute path to avoid ambiguity about mpv's working directory. Colors are loaded at script startup.

## Live reload

Run this mpv command after regenerating the palette:

```
/script-message adwisp-reload-theme
```

Or send the script message from another mpv script. Adwisp reparses the file and redraws using the new palette; it does not poll the file or run Matugen on redraw. If the file cannot be opened, the fallback palette remains active.

## Design principles

- Keep semantic color roles separate from specific widgets.
- Cache renderer output and avoid rebuilding unchanged styles.
- Never invoke Matugen on every redraw.
- Avoid idle polling; reload is explicit and event-driven.
