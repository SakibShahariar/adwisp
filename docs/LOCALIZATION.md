# Localization

Adwisp uses English strings by default. To translate the interface, copy [the template](../locales/template.conf), keep each key unchanged, and replace the value after `=` with your translation.

Set the resulting file in `script-opts/adwisp.conf`:

```ini
locale_file=/absolute/path/to/adwisp-locale.conf
```

Locale files must be UTF-8. Blank lines and lines beginning with `#` or `;` are ignored. Values are single-line and limited to 256 bytes; the file is limited to 64 KiB. Missing, malformed, or oversized entries fall back to the built-in English string. Keep printf placeholders such as `%s` and `%d%%` in the translated value.

The template covers the OSD status labels, playlist/recent-file panels, track and chapter menus, and audio-device menu. If a string is not listed, it remains in English. Contributions of additional locale files are welcome.
