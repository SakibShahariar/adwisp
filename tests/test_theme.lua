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

local palette, loaded_from = Theme.load(path)
os.remove(path)
assert(loaded_from == "file", "valid palette file should be loaded")
assert(palette.background == "#112233", "background should be parsed")
assert(palette.text == "#F5F0FF", "hex values should be normalized")
assert(palette.accent == "#D0BCFF", "invalid duplicate should not replace valid value")
assert(palette.surface == "#223344", "surface should be parsed")
assert(palette.on_accent == "#381E72", "on_accent should be parsed")
assert(palette.unknown == nil, "unknown keys should be ignored")

local ass = Theme.to_ass(palette)
assert(ass.background == "&H332211&", "ASS color should convert RGB to BGR")
assert(ass.accent == "&HFFBCD0&", "accent should convert RGB to BGR")
assert(Theme.to_ass({ accent = "invalid" }).accent == "&H53769B&",
    "invalid colors should use fallback")

print("All theme tests passed.")
