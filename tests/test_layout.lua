package.path = "./?.lua;./?/init.lua;" .. package.path

local Layout = require "core.layout"

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error((message or "values differ") .. ": expected " .. tostring(expected)
            .. ", got " .. tostring(actual), 2)
    end
end

local function assert_true(value, message)
    if not value then error(message or "expected true", 2) end
end

local function test_standard_layout()
    local layout = Layout.compute(1280, 720)
    assert_true(layout ~= nil, "layout should exist for valid dimensions")
    assert_equal(layout.panel.width, 560, "panel should respect max width")
    assert_equal(layout.panel.height, 156, "panel should use standard height")
    assert_equal(layout.panel.x, 360, "panel should be horizontally centered")
    assert_equal(layout.panel.y, 522, "panel should sit above bottom margin")
    assert_true(layout.timeline.width > 0, "timeline width should be positive")
    assert_true(layout.timeline.hit_width >= layout.timeline.width,
        "timeline hit target should cover the visual timeline")
end

local function test_small_layout()
    local layout = Layout.compute(320, 240)
    assert_true(layout ~= nil, "small valid dimensions should be supported")
    assert_true(layout.panel.width <= 288, "panel should fit within horizontal margins")
    assert_true(layout.panel.height <= 156, "panel should not exceed standard height")
    assert_true(layout.timeline.width > 0, "small timeline width should stay positive")
end

local function test_narrow_layout_controls_stay_inside_panel()
    for _, width in ipairs({ 200, 240, 320, 420 }) do
        local layout = Layout.compute(width, 360)
        local panel_right = layout.panel.x + layout.panel.width
        local playback_right = layout.playback.x + layout.playback.width
        local volume_right = layout.volume.x + layout.volume.width
        assert_true(layout.playback.x >= layout.panel.x,
            "playback should remain inside panel at width " .. width)
        assert_true(playback_right <= layout.volume.x,
            "playback and volume should not overlap at width " .. width)
        assert_true(volume_right <= panel_right,
            "volume should remain inside panel at width " .. width)
        assert_true(layout.volume.width > 0,
            "volume control should retain positive width at width " .. width)
    end
end

local function test_compact_layout_fits_short_windows()
    for _, height in ipairs({ 160, 180, 220, 239 }) do
        local layout = Layout.compute(640, height)
        local panel_bottom = layout.panel.y + layout.panel.height
        assert_true(layout.compact, "short windows should select compact layout at height " .. height)
        assert_true(layout.panel.y >= 0 and panel_bottom <= height,
            "panel should fit vertically at height " .. height)
        assert_true(layout.title.y < layout.playback.y,
            "title should precede controls at height " .. height)
        assert_true(layout.playback.y + layout.playback.height <= layout.timeline.y,
            "controls should not overlap timeline at height " .. height)
        assert_true(layout.progress_label.y < layout.playlist.y,
            "progress labels should precede playlist at height " .. height)
        assert_true(layout.playlist.y + layout.playlist.height <= panel_bottom,
            "playlist should remain inside panel at height " .. height)
    end
    assert_true(not Layout.compute(640, 240).compact,
        "standard layout should be retained at the compact threshold")
end

local function test_invalid_dimensions()
    assert_equal(Layout.compute(0, 720), nil, "zero width should be rejected")
    assert_equal(Layout.compute(1280, 0), nil, "zero height should be rejected")
    assert_equal(Layout.compute(-1, 720), nil, "negative width should be rejected")
    assert_equal(Layout.compute("1280", 720), nil, "non-numeric width should be rejected")
end

local function test_layout_rectangles()
    local layout = Layout.compute(1920, 1080)
    local panel = layout.panel
    local timeline = layout.timeline
    assert_true(timeline.x >= panel.x, "timeline should begin inside panel")
    assert_true(timeline.x + timeline.width <= panel.x + panel.width,
        "timeline should end inside panel")
    assert_true(layout.playback.x >= panel.x, "playback should begin inside panel")
end

test_standard_layout()
test_small_layout()
test_narrow_layout_controls_stay_inside_panel()
test_compact_layout_fits_short_windows()
test_invalid_dimensions()
test_layout_rectangles()

print("All layout tests passed.")
