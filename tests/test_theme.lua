package.path = "./?.lua;./?/init.lua;" .. package.path

local Theme = require "core.theme"

local fallback, source = Theme.load("")
assert(source == "fallback", "empty path should use fallback palette")
assert(fallback.accent == "#9B7653", "fallback accent should be available")

local path = os.tmpname()
local file = assert(io.open(path, "w"))
file:write([[
# Matugen-like palette
background=#112233
surface=#223344
text=#f5f0ff
muted=#AABBCC
accent=#D0BCFF
on_accent=#381E72
unknown=#000000
accent=not-a-color
]])
file:close()

local palette, loaded_from, load_error, diagnostics = Theme.load(path)
os.remove(path)
assert(loaded_from == "file", "valid palette file should be loaded")
assert(palette.background == "#112233", "background should be parsed")
assert(palette.text == "#F5F0FF", "hex values should be normalized")
assert(palette.accent == "#D0BCFF", "invalid duplicate should not replace valid value")
assert(palette.surface == "#223344", "surface should be parsed")
assert(palette.on_accent == "#381E72", "on_accent should be parsed")
assert(palette.unknown == nil, "unknown keys should be ignored")
assert(load_error == nil, "partially valid palette should load without a fatal error")
assert(#diagnostics == 2, "invalid entries should produce line-specific diagnostics")
assert(diagnostics[1]:find("unknown palette key 'unknown'", 1, true) ~= nil,
    "unknown keys should be identified in diagnostics")
assert(diagnostics[2]:find("invalid color for 'accent'", 1, true) ~= nil,
    "malformed colors should identify their palette key")

local ass = Theme.to_ass(palette)
assert(ass.background == "&H332211&", "ASS color should convert RGB to BGR")
assert(ass.accent == "&HFFBCD0&", "accent should convert RGB to BGR")
assert(Theme.to_ass({ accent = "invalid" }).accent == "&H53769B&",
    "invalid colors should use fallback")
assert(Theme.to_ass({ accent = "#GG0000" }).accent == "&H53769B&",
    "non-hex palette colors should use fallback")
assert(Theme.to_ass({ accent = "#12345" }).accent == "&H53769B&",
    "short palette colors should use fallback")

-- Entirely invalid files should be rejected with actionable diagnostics.
local invalid_path = os.tmpname()
local invalid_file = assert(io.open(invalid_path, "w"))
invalid_file:write("not a palette entry\nunknown=#000000\naccent=invalid\n")
invalid_file:close()
local invalid_palette, invalid_source, invalid_error, invalid_diagnostics = Theme.load(invalid_path)
assert(invalid_palette == nil, "files without valid colors should not replace the active palette")
assert(invalid_source == "invalid", "invalid content should be distinguished from file errors")
assert(invalid_error == "no valid palette entries found",
    "invalid-only files should explain why they were rejected")
assert(#invalid_diagnostics == 3, "every malformed entry should be reported")
os.remove(invalid_path)

local missing_palette, missing_source, missing_error = Theme.load(invalid_path)
assert(missing_palette == nil, "missing files should not produce a replacement palette")
assert(missing_source == "error", "file access failures should be distinguished from invalid content")
assert(type(missing_error) == "string" and missing_error ~= "",
    "file access failures should include the operating-system error")

local black_white = Theme.contrast_ratio("#FFFFFF", "#000000")
assert(math.abs(black_white - 21) < 0.001,
    "white on black should meet the maximum WCAG contrast ratio")
assert(Theme.contrast_ratio("#777777", "#FFFFFF") < 4.5,
    "low-contrast text should be detectable")
local fallback_contrast = Theme.contrast_report(Theme.fallback)
assert(fallback_contrast.text_background >= 4.5,
    "fallback text should meet normal-text contrast")
assert(fallback_contrast.on_accent >= 3,
    "fallback accent labels should meet large-text contrast")

print("All theme tests passed.")
