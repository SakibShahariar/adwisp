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

local function inside(rect, panel, label)
    local rect_height = rect.height or 1
    assert_true(rect.x >= panel.x and rect.y >= panel.y
        and rect.x + rect.width <= panel.x + panel.width
        and rect.y + rect_height <= panel.y + panel.height,
        label .. " should stay inside the scrim")
end

local function test_standard_layout()
    local layout = Layout.compute(1280, 720)
    assert_true(layout ~= nil, "layout should exist for valid dimensions")
    assert_equal(layout.panel.x, 0, "scrim should span the full width")
    assert_equal(layout.panel.width, 1280, "scrim should span the full width")
    assert_equal(layout.panel.y + layout.panel.height, 720,
        "scrim should sit at the bottom of the OSD")
    assert_true(layout.panel.height >= 92 and layout.panel.height <= 168,
        "scrim height should be clamped")
    inside(layout.thumbnail, layout.panel, "thumbnail")
    inside(layout.title, layout.panel, "title")
    inside(layout.timeline, layout.panel, "timeline")
    inside(layout.volume, layout.panel, "volume")
    inside(layout.transport.play, layout.panel, "play button")
    assert_true(layout.timeline.hit_width >= layout.timeline.width,
        "timeline hit target should cover the visual timeline")
    assert_true(layout.transport.prev.x < layout.transport.play.x
        and layout.transport.play.x < layout.transport.next.x,
        "transport should be ordered prev, play, next")
end

local function test_small_and_narrow_layouts()
    for _, size in ipairs({ { 320, 240 }, { 400, 320 }, { 640, 360 }, { 1920, 1080 } }) do
        local width, height = size[1], size[2]
        local layout = Layout.compute(width, height)
        assert_true(layout ~= nil, "layout should exist at " .. width .. "x" .. height)
        assert_true(layout.panel.width == width, "scrim should span the OSD width")
        assert_true(layout.panel.y >= 0
            and layout.panel.y + layout.panel.height <= height,
            "scrim should stay inside the OSD at " .. width .. "x" .. height)
        inside(layout.timeline, layout.panel, "timeline")
        inside(layout.transport.play, layout.panel, "play button")
        inside(layout.volume, layout.panel, "volume")
        inside(layout.volume.track, layout.panel, "volume track")
        inside(layout.volume.hit, layout.panel, "volume hit target")
        inside(layout.fullscreen, layout.panel, "fullscreen icon")
        inside(layout.settings, layout.panel, "settings icon")
        assert_true(layout.transport.play.width > 0, "play button should keep a positive size")
        assert_true(layout.volume.track.width > 0, "volume track should keep a positive width")
    end
end

local function test_timeline_and_volume_hit_targets()
    local layout = Layout.compute(1280, 720)
    local timeline = layout.timeline
    assert_true(timeline.hit_y <= timeline.y and timeline.hit_y + timeline.hit_height
        >= timeline.y + timeline.height, "timeline hit area should cover the line")
    local track = layout.volume.track
    local hit = layout.volume.hit
    assert_true(hit.x == track.x and hit.width == track.width,
        "volume hit area should match the track width")
    assert_true(hit.y <= track.y and hit.y + hit.height >= track.y + track.height,
        "volume hit area should cover the track")
    assert_true(hit.y >= layout.volume.y
        and hit.y + hit.height <= layout.volume.y + layout.volume.height,
        "volume hit area should stay inside the volume control")
end

local function test_invalid_dimensions()
    assert_equal(Layout.compute(0, 720), nil, "zero width should be rejected")
    assert_equal(Layout.compute(1280, 0), nil, "zero height should be rejected")
    assert_equal(Layout.compute(-1, 720), nil, "negative width should be rejected")
    assert_equal(Layout.compute("1280", 720), nil, "non-numeric width should be rejected")
    assert_equal(Layout.compute(0 / 0, 720), nil, "NaN width should be rejected")
    assert_equal(Layout.compute(1280, math.huge), nil, "infinite height should be rejected")
    assert_equal(Layout.compute(-math.huge, 720), nil, "negative infinite width should be rejected")
    local tiny = Layout.compute(1, 1)
    assert_true(tiny ~= nil, "positive tiny dimensions should still produce a layout")
    assert_true(tiny.panel.width >= 1 and tiny.panel.height >= 1,
        "tiny dimensions should preserve non-zero panel geometry")
end

local function test_fractional_dimensions_are_normalized()
    local layout = Layout.compute(640.9, 360.7)
    assert_true(layout ~= nil, "fractional dimensions should remain valid")
    assert_equal(layout.width, 640, "layout width should be normalized to whole pixels")
    assert_equal(layout.height, 360, "layout height should be normalized to whole pixels")
    assert_equal(layout.panel.x, math.floor(layout.panel.x),
        "panel coordinates should remain integer pixel positions")
end

local function test_minimal_timeline_geometry()
    local full = Layout.compute(1280, 720)
    local collapsed = Layout.compute(1280, 720, { minimal_timeline = true })
    local expanded = Layout.compute(1280, 720, {
        minimal_timeline = true, timeline_expanded = true,
    })
    assert_equal(full.timeline.height, 4, "default timeline should be a thin line")
    assert_equal(collapsed.timeline.height, 2, "minimal timeline should collapse")
    assert_true(collapsed.timeline.minimal, "minimal timeline should be marked")
    assert_true(not collapsed.progress_label.visible and not collapsed.time_label.visible,
        "collapsed timeline should hide labels")
    assert_equal(expanded.timeline.height, 4, "expansion should restore the timeline height")
    assert_true(expanded.progress_label.visible and expanded.time_label.visible,
        "expansion should restore labels")
    assert_equal(expanded.timeline.hit_y, collapsed.timeline.hit_y,
        "expansion should not move the hit target")
    for _, size in ipairs({ { 320, 240 }, { 640, 360 }, { 1280, 720 } }) do
        local compact_layout = Layout.compute(size[1], size[2], { minimal_timeline = true })
        assert_equal(compact_layout.timeline.height, 2,
            "minimal timeline should stay thin at " .. size[1] .. "x" .. size[2])
        inside(compact_layout.timeline, compact_layout.panel, "minimal timeline")
    end
end

test_standard_layout()
test_small_and_narrow_layouts()
test_timeline_and_volume_hit_targets()
test_invalid_dimensions()
test_fractional_dimensions_are_normalized()
test_minimal_timeline_geometry()

print("All layout tests passed.")
