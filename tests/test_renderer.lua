package.path = "./?.lua;./?/init.lua;" .. package.path

local Renderer = require "core.renderer"

local width, height = 1280, 720
local overlay = { update_count = 0 }
function overlay:update()
    self.update_count = self.update_count + 1
end

local mp = {
    create_osd_overlay = function(kind)
        assert(kind == "ass-events", "renderer should request ASS overlay")
        return overlay
    end,
    get_osd_size = function()
        return width, height
    end,
}

local state = {
    visible = false,
    paused = false,
    time_pos = 15,
    duration = 60,
    title = "Demo {x}",
    volume = 50.5,
    mute = false,
}

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error((message or "values differ") .. ": expected " .. tostring(expected)
            .. ", got " .. tostring(actual), 2)
    end
end

local function assert_true(value, message)
    if not value then error(message or "expected true", 2) end
end

local renderer = Renderer.new(mp, state)
assert_equal(overlay.z, 20, "overlay should use the configured z-order")

renderer:render()
assert_equal(overlay.update_count, 1, "initial hidden render should clear overlay")
assert_equal(overlay.data, "", "hidden render should leave no OSD data")

renderer:render()
assert_equal(overlay.update_count, 1, "repeated hidden render should be cached")

state.visible = true
renderer:render()
assert_equal(overlay.update_count, 2, "visible render should draw once")
assert_equal(overlay.res_x, 1280, "overlay resolution width should match OSD")
assert_equal(overlay.res_y, 720, "overlay resolution height should match OSD")
assert_true(overlay.data:find("Demo \\{x\\}", 1, true) ~= nil,
    "title braces should be escaped for ASS")

-- Long titles are shortened before ASS escaping so they cannot spill across controls.
state.title = string.rep("A", 200)
renderer:render()
assert_true(overlay.data:find("…", 1, true) ~= nil,
    "long titles should be truncated with an ellipsis")
assert_true(overlay.data:find(string.rep("A", 200), 1, true) == nil,
    "full long title should not be rendered")
state.title = "Demo {x}"
renderer:render()
assert_true(overlay.data:find("25%", 1, true) ~= nil,
    "progress label should reflect current position")
assert_true(overlay.data:find("0:15 / 1:00", 1, true) ~= nil,
    "time label should format current and total time")
assert_true(overlay.data:find("Volume 51%", 1, true) ~= nil,
    "volume label should round to the nearest integer")
assert_true(overlay.data:find("Pause", 1, true) ~= nil,
    "playing state should offer Pause")

renderer:render()
assert_equal(overlay.update_count, 4, "restored title should redraw and then cache")

state.paused = true
state.mute = true
state.time_pos = 90
renderer:render()
assert_equal(overlay.update_count, 5, "state changes should trigger a redraw")
assert_true(overlay.data:find("Play", 1, true) ~= nil,
    "paused state should offer Play")
assert_true(overlay.data:find("Muted", 1, true) ~= nil,
    "muted state should use muted label")
assert_true(overlay.data:find("100%", 1, true) ~= nil,
    "progress should clamp to 100 percent when position exceeds duration")

state.time_pos = -5
state.duration = 0
renderer:render()
assert_equal(overlay.update_count, 6, "time changes should trigger a redraw")
assert_true(overlay.data:find("0%", 1, true) ~= nil,
    "zero duration should avoid division and show zero progress")
assert_true(overlay.data:find("--:-- / 0:00", 1, true) ~= nil,
    "negative current time should use the placeholder")

width, height = 640, 360
renderer:render()
assert_equal(overlay.update_count, 7, "OSD size changes should trigger a redraw")
assert_equal(overlay.res_x, 640, "new overlay width should be applied")
assert_equal(overlay.res_y, 360, "new overlay height should be applied")

width, height = 0, 360
renderer:render()
assert_equal(overlay.update_count, 7, "invalid OSD dimensions should be ignored")

width, height = 640, 360
-- The volume track follows the active palette and emits valid ASS commands.
renderer:set_palette({
    background = "#010203",
    surface = "#040506",
    text = "#070809",
    muted = "#112233",
    accent = "#ABCDEF",
    on_accent = "#FFFFFF",
})
renderer:render()
assert_equal(overlay.update_count, 8, "palette changes should invalidate renderer cache")
assert_true(overlay.data:find("\\an7\\pos(", 1, true) ~= nil,
    "volume track should use single-backslash ASS commands")
assert_true(overlay.data:find("&H332211&", 1, true) ~= nil,
    "volume track should use the palette muted color")
assert_true(overlay.data:find("&HEFCDAB&", 1, true) ~= nil,
    "volume track should use the palette accent color")
assert_true(overlay.data:find("&H6D6259&", 1, true) == nil
    and overlay.data:find("&H9B7653&", 1, true) == nil,
    "volume track should not retain hard-coded fallback colors")

-- Hover highlighting should follow the active palette surface color.
state.hover_target = "playback"
renderer:render()
assert_equal(overlay.update_count, 9, "hover state should redraw the overlay")
assert_true(overlay.data:find("\\1c&H060504&", 1, true) ~= nil,
    "hover highlight should use the palette surface color")

-- Compact layouts reduce text sizes so labels fit short video windows.
height = 180
renderer:render()
assert_true(overlay.data:find("\\fs18", 1, true) ~= nil,
    "compact title should use the smaller font size")
assert_true(overlay.data:find("\\fs22", 1, true) == nil,
    "compact layout should not retain the standard title font size")
assert_true(overlay.data:find("\\fs11", 1, true) ~= nil,
    "compact progress labels should use the smallest font size")

-- Invalid numeric properties should never break rendering or draw invalid values.
state.visible = true
state.time_pos = 0 / 0
state.duration = math.huge
state.volume = 140
state.mute = false
renderer:render()
assert_true(overlay.data:find("--:-- / --:--", 1, true) ~= nil,
    "non-finite playback values should use safe time placeholders")
assert_true(overlay.data:find("Volume 100%", 1, true) ~= nil,
    "rendered volume should clamp to the supported range")
assert_true(overlay.data:find("nan", 1, true) == nil
    and overlay.data:find("inf", 1, true) == nil,
    "non-finite values should not leak into ASS output")

state.visible = false
renderer:render()
assert_equal(overlay.data, "", "hiding renderer should clear visible data")
assert_equal(overlay.update_count, 12, "hiding should update overlay once")

print("All renderer tests passed.")
