# Theming and Matugen

Adwisp reads a small semantic palette file. It does **not** execute Matugen, watch generated files, or require Matugen at runtime.

## Matugen compatibility and workflow

There is no Matugen version requirement imposed by Adwisp because the mpv script never calls the Matugen executable or its API. The project does not claim that every Matugen release or default output template is compatible, and no particular Matugen version is currently certified.

Use Matugen independently with a custom template (or another palette generator) that writes the six semantic keys below as UTF-8 `key=value` lines. Point Adwisp at that generated file. Matugen generates the file; Adwisp only reads it. If Matugen is not installed or generation fails, Adwisp continues using the last valid palette already loaded, or its built-in palette when no valid custom palette has been loaded.

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

Supported keys are `background`, `surface`, `text`, `muted`, `accent`, and `on_accent`. Values must be six-digit `#RRGGBB` colors. Keys are case-sensitive. Blank lines and lines beginning with `#` or `;` are ignored.

Set `theme_file` in `script-opts/adwisp.conf` to the generated palette path, for example:

```ini
theme_file=/home/you/.config/matugen/adwisp.conf
```

Use an absolute path to avoid ambiguity about mpv working directory. Colors are loaded at script startup.

## Fallback and invalid output behavior

- If `theme_file` is empty, Adwisp uses its built-in palette.
- If a custom file contains valid entries, those entries override built-in values; omitted roles retain built-in values.
- Unknown keys, malformed lines, and values that are not six-digit `#RRGGBB` colors are ignored and produce line-specific warnings. A Matugen template that emits a different schema or color format must be adapted; Adwisp does not guess or translate arbitrary schemes.
- If the file is unreadable or contains no valid palette entries, Adwisp keeps the last successfully loaded palette. If no custom palette has loaded successfully yet, the built-in palette remains active.
- A partial file with at least one valid entry loads those entries and uses built-in values for missing roles.

## Live reload

Run this mpv command after regenerating or editing the palette:

```
/script-message adwisp-reload-theme
```

Or send the script message from another mpv script. Adwisp reparses the configured file and redraws using the new palette; it does not poll the file or run Matugen on redraw.

## Troubleshooting

- **The theme does not change:** Check that `theme_file` points to the generated file, that the path is absolute, and that mpv can read it. Then send `adwisp-reload-theme` or restart mpv.
- **The built-in colors remain active:** Check mpv console for file-open errors. An empty path or a file with no valid entries uses the built-in palette (or retains the last valid palette after a failed reload).
- **Only some colors change:** Confirm that the file uses the six exact, case-sensitive keys and six-digit hex values. Missing roles intentionally use built-in colors.
- **Matugen reports success but Adwisp ignores the output:** Inspect the generated file. Configure a Matugen template that emits the semantic key/value format above; Adwisp does not parse Matugen JSON or arbitrary color-scheme formats.

## Design principles

- Keep semantic color roles separate from specific widgets.
- Cache renderer output and avoid rebuilding unchanged styles.
- Never invoke Matugen on every redraw.
- Avoid idle polling; reload is explicit and event-driven.