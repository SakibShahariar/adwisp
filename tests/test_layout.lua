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
    assert_true(layout.title.width > 0, "title should expose available width")
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

local function test_layout_rectangles()
    local layout = Layout.compute(1920, 1080)
    local panel = layout.panel
    local timeline = layout.timeline
    assert_true(timeline.x >= panel.x, "timeline should begin inside panel")
    assert_true(timeline.x + timeline.width <= panel.x + panel.width,
        "timeline should end inside panel")
    assert_true(layout.playback.x >= panel.x, "playback should begin inside panel")

    local function assert_volume_geometry(candidate, label)
        local volume = candidate.volume
        local track = volume.track
        local hit = volume.hit
        assert_true(track.x == volume.x and track.width == volume.width,
            label .. " volume track should share the control's horizontal geometry")
        assert_true(track.y == volume.y + 25 and track.height == 4,
            label .. " volume track should use its canonical vertical geometry")
        assert_true(hit.x == track.x and hit.width == track.width,
            label .. " volume hit area should match the track width")
        assert_true(hit.y <= track.y and hit.y + hit.height >= track.y + track.height,
            label .. " volume hit area should cover the visible track")
        assert_true(hit.y >= volume.y and hit.y + hit.height <= volume.y + volume.height,
            label .. " volume hit area should remain inside its control")
        assert_true(hit.y + hit.height <= candidate.timeline.hit_y,
            label .. " volume hit area should not overlap the timeline hit area")
    end

    assert_volume_geometry(layout, "standard")
    assert_volume_geometry(Layout.compute(640, 180), "compact")
end

local function test_configurable_vertical_position()
    local default = Layout.compute(1280, 720)
    assert_equal(default.panel.y, 522, "default bottom placement should remain unchanged")

    local top = Layout.compute(1280, 720, {
        osd_position = "top",
        osd_margin = 24,
    })
    assert_equal(top.position, "top", "top placement should be retained")
    assert_equal(top.panel.y, 24, "top placement should use the configured margin")

    local bottom = Layout.compute(1280, 720, {
        osd_position = "bottom",
        osd_margin = 60,
    })
    assert_equal(bottom.panel.y, 504, "bottom placement should use the configured margin")

    local custom = Layout.compute(1280, 720, {
        osd_position = "custom",
        osd_custom_offset = 180,
    })
    assert_equal(custom.position, "custom", "custom placement should be retained")
    assert_equal(custom.panel.y, 180, "custom offset should be measured from the top")

    local clamped = Layout.compute(320, 240, {
        osd_position = "custom",
        osd_custom_offset = 9999,
    })
    assert_equal(clamped.panel.y + clamped.panel.height, 240,
        "custom placement should clamp to the visible OSD bounds")

    local invalid = Layout.compute(1280, 720, {
        osd_position = "diagonal",
        osd_margin = -10,
    })
    assert_equal(invalid.position, "bottom",
        "invalid position should safely fall back to bottom")
    assert_equal(invalid.panel.y, default.panel.y,
        "invalid margin should retain the default responsive margin")
end

local function test_dense_compact_layout_stays_inside_panel()
    for _, height in ipairs({ 120, 128, 140, 152, 159 }) do
        for _, width in ipairs({ 200, 320, 640 }) do
            local candidate = Layout.compute(width, height)
            local panel = candidate.panel
            local panel_right = panel.x + panel.width
            local panel_bottom = panel.y + panel.height

            local function inside(rect, label)
                assert_true(rect.x >= panel.x and rect.y >= panel.y
                    and rect.x + rect.width <= panel_right
                    and rect.y + rect.height <= panel_bottom,
                    label .. " should stay inside the panel at " .. width .. "x" .. height)
            end

            assert_true(candidate.compact,
                "dense layout should remain compact at height " .. height)
            assert_true(panel.x >= 0 and panel.y >= 0
                and panel_right <= width and panel_bottom <= height,
                "panel should stay inside the OSD at " .. width .. "x" .. height)
            inside({ x = candidate.title.x, y = candidate.title.y, width = candidate.title.width, height = 1 }, "title")
            inside(candidate.playback, "playback control")
            inside(candidate.volume, "volume control")
            inside(candidate.volume.track, "volume track")
            inside(candidate.volume.hit, "volume hit target")
            inside(candidate.timeline, "timeline")
            inside({
                x = candidate.timeline.hit_x,
                y = candidate.timeline.hit_y,
                width = candidate.timeline.hit_width,
                height = candidate.timeline.hit_height,
            }, "timeline hit target")
            inside(candidate.playlist, "playlist")

            assert_true(candidate.title.y < candidate.playback.y,
                "title should precede controls at " .. width .. "x" .. height)
            assert_true(candidate.playback.y + candidate.playback.height
                <= candidate.timeline.y,
                "playback should not overlap timeline at " .. width .. "x" .. height)
            assert_true(candidate.volume.hit.y + candidate.volume.hit.height
                <= candidate.timeline.hit_y,
                "volume and timeline hit targets should not overlap at "
                    .. width .. "x" .. height)
            assert_true(candidate.progress_label.y + 11 <= candidate.playlist.y,
                "timeline labels should precede playlist at " .. width .. "x" .. height)
        end
    end
end

test_standard_layout()
test_small_layout()
test_narrow_layout_controls_stay_inside_panel()
test_compact_layout_fits_short_windows()
test_invalid_dimensions()
test_fractional_dimensions_are_normalized()
local function test_timeline_labels_do_not_overlap()
    for _, width in ipairs({ 120, 160, 200, 240, 320, 640 }) do
        local candidate = Layout.compute(width, 720)
        local timeline = candidate.timeline
        local progress = candidate.progress_label
        local time = candidate.time_label

        if timeline.width >= 164 then
            assert_true(progress.visible and time.visible,
                "wide timelines should show both time labels at width " .. width)
            assert_true(progress.x + progress.width + 8 <= time.x,
                "wide timeline labels should have a reserved gap at width " .. width)
        else
            assert_true(not progress.visible,
                "narrow timelines should hide the progress label at width " .. width)
            assert_true(time.x == timeline.x,
                "narrow timeline time should start at the timeline edge at width " .. width)
            assert_true(time.visible == (timeline.width >= 40),
                "time should only be shown when its minimum width is available at width " .. width)
        end

        if timeline.width >= 120 and timeline.width < 164 then
            assert_true(time.compact and not time.current_only,
                "medium timelines should use compact elapsed/total text at width " .. width)
        elseif timeline.width < 120 then
            assert_true(time.current_only,
                "very narrow timelines should retain elapsed time only at width " .. width)
        end
    end

    local compact = Layout.compute(200, 180)
    assert_true(compact.compact and not compact.progress_label.visible,
        "compact narrow windows should hide the progress label")
    assert_true(compact.time_label.visible and compact.time_label.compact
        and not compact.time_label.current_only,
        "compact narrow windows should retain elapsed time where it fits")
end

local function test_minimal_timeline_geometry()
    local full = Layout.compute(1280, 720)
    local collapsed = Layout.compute(1280, 720, { minimal_timeline = true })
    local expanded = Layout.compute(1280, 720, {
        minimal_timeline = true,
        timeline_expanded = true,
    })

    assert_equal(full.timeline.height, 6,
        "default timeline should retain its full visual height")
    assert_true(not full.timeline.minimal,
        "default timeline should not be marked minimal")
    assert_equal(collapsed.timeline.height, 2,
        "minimal timeline should collapse to a thin progress indicator")
    assert_true(collapsed.timeline.minimal,
        "collapsed timeline should identify its minimal state")
    assert_true(not collapsed.progress_label.visible and not collapsed.time_label.visible,
        "collapsed timeline should hide time and percentage labels")
    assert_equal(collapsed.timeline.hit_y, full.timeline.hit_y,
        "collapsed and full timelines should share the same hit region")
    assert_equal(collapsed.timeline.hit_height, full.timeline.hit_height,
        "collapsed and full timelines should retain the same hit target height")
    assert_equal(expanded.timeline.height, 6,
        "hover/focus expansion should restore the full timeline height")
    assert_true(not expanded.timeline.minimal
        and expanded.progress_label.visible and expanded.time_label.visible,
        "expanded timeline should restore labels and normal geometry")
    assert_equal(expanded.timeline.hit_y, collapsed.timeline.hit_y,
        "expansion should not move the hit target")

    for _, size in ipairs({
        { 120, 120 }, { 160, 180 }, { 320, 240 }, { 640, 360 }, { 1280, 720 },
    }) do
        local width, height = size[1], size[2]
        local compact_layout = Layout.compute(width, height, { minimal_timeline = true })
        local expanded_layout = Layout.compute(width, height, {
            minimal_timeline = true,
            timeline_expanded = true,
        })
        assert_equal(compact_layout.timeline.height, 2,
            "minimal timeline should remain thin at " .. width .. "x" .. height)
        assert_equal(expanded_layout.timeline.height, 6,
            "expanded timeline should restore its height at " .. width .. "x" .. height)
        assert_equal(compact_layout.timeline.x, expanded_layout.timeline.x,
            "expansion should preserve horizontal position at " .. width .. "x" .. height)
        assert_equal(compact_layout.timeline.width, expanded_layout.timeline.width,
            "expansion should preserve width at " .. width .. "x" .. height)
        assert_equal(compact_layout.timeline.hit_y, expanded_layout.timeline.hit_y,
            "expansion should preserve hit-test origin at " .. width .. "x" .. height)
        assert_equal(compact_layout.timeline.hit_height, expanded_layout.timeline.hit_height,
            "expansion should preserve hit target height at " .. width .. "x" .. height)
        assert_true(compact_layout.timeline.hit_x >= compact_layout.panel.x
            and compact_layout.timeline.hit_x + compact_layout.timeline.hit_width
                <= compact_layout.panel.x + compact_layout.panel.width,
            "minimal timeline hit target should remain inside the panel at "
                .. width .. "x" .. height)
    end
end

local function test_standard_timeline_labels_clear_playlist_row()
    for _, size in ipairs({
        { 320, 320 }, { 640, 360 }, { 1280, 720 }, { 1920, 1080 },
    }) do
        local width, height = size[1], size[2]
        local candidate = Layout.compute(width, height)
        assert_true(candidate.progress_label.y + 11 <= candidate.playlist.y,
            "timeline labels should clear playlist navigation at "
                .. width .. "x" .. height)
        assert_true(candidate.playlist.y + candidate.playlist.height
            <= candidate.panel.y + candidate.panel.height,
            "playlist navigation should remain inside the panel at "
                .. width .. "x" .. height)
    end
end

local function test_split_zone_geometry()
    local split = Layout.compute(1280, 720, {
        control_zones = "split", osd_position = "bottom",
        osd_margin = 42, top_zone_margin = 24,
    })
    assert_true(split.top_zone ~= nil, "split mode should create a separate top zone")
    assert_equal(split.top_zone.y, 24, "top zone should use its own margin")
    assert_true(split.top_zone.y + split.top_zone.height < split.panel.y,
        "top and bottom zones should not overlap")
    assert_true(split.title.y >= split.top_zone.y
        and split.title.y < split.top_zone.y + split.top_zone.height,
        "title should move into the top zone")
    assert_true(split.playback.y >= split.panel.y and split.timeline.y >= split.panel.y,
        "playback controls should remain in the bottom zone")
    assert_true(split.playlist.y >= split.top_zone.y
        and split.playlist.y + split.playlist.height <= split.top_zone.y + split.top_zone.height,
        "secondary playlist navigation should move into the top zone")

    local compact = Layout.compute(640, 220, { control_zones = "split" })
    assert_equal(compact.top_zone, nil, "compact windows should retain the single-zone fallback")
    local top_position = Layout.compute(1280, 720, {
        control_zones = "split", osd_position = "top",
    })
    assert_equal(top_position.top_zone, nil, "top-positioned panels should retain the single-zone fallback")
end

test_standard_timeline_labels_clear_playlist_row()
local function test_width_adaptive_layout()
    local narrow = Layout.compute(320, 720)
    local threshold = Layout.compute(464, 720)
    local wide = Layout.compute(1280, 720)

    assert_true(narrow.compact,
        "narrow tall windows should select the compact arrangement")
    assert_true(not threshold.compact,
        "layouts with at least 420px of panel width should use the standard arrangement")
    assert_true(not wide.compact,
        "wide desktop windows should retain the standard arrangement")

    for _, size in ipairs({ { 200, 720 }, { 320, 720 }, { 400, 900 },
        { 464, 720 }, { 640, 360 }, { 1280, 720 } }) do
        local candidate = Layout.compute(size[1], size[2])
        local panel = candidate.panel
        local right = panel.x + panel.width
        local bottom = panel.y + panel.height
        assert_true(candidate.title.x >= panel.x
            and candidate.title.x + candidate.title.width <= right,
            "title should fit panel at " .. size[1] .. "x" .. size[2])
        assert_true(candidate.playback.x >= panel.x
            and candidate.playback.x + candidate.playback.width <= right,
            "playback should fit panel at " .. size[1] .. "x" .. size[2])
        assert_true(candidate.playback.y + candidate.playback.height <= candidate.timeline.y,
            "controls should precede timeline at " .. size[1] .. "x" .. size[2])
        assert_true(candidate.playlist.y + candidate.playlist.height <= bottom,
            "playlist should fit panel at " .. size[1] .. "x" .. size[2])
    end
end

local function test_split_zone_matrix()
    for _, size in ipairs({
        { 320, 320 }, { 640, 360 }, { 1280, 720 }, { 1920, 1080 },
    }) do
        local width, height = size[1], size[2]
        local candidate = Layout.compute(width, height, {
            control_zones = "split", osd_position = "bottom",
        })
        if candidate.compact then
            assert_true(candidate.top_zone == nil,
                "split zones should collapse in compact layouts at " .. width .. "x" .. height)
        else
            assert_true(candidate.top_zone ~= nil,
                "split zones should fit at " .. width .. "x" .. height)
        end
        if candidate.top_zone then
        local top = candidate.top_zone
        local bottom = candidate.panel
        assert_true(top.x >= 0 and top.y >= 0
            and top.x + top.width <= width and top.y + top.height <= height,
            "top zone should remain within OSD bounds at " .. width .. "x" .. height)
        assert_true(bottom.x >= 0 and bottom.y >= 0
            and bottom.x + bottom.width <= width and bottom.y + bottom.height <= height,
            "bottom zone should remain within OSD bounds at " .. width .. "x" .. height)
        assert_true(top.y + top.height < bottom.y,
            "zones should retain a gap at " .. width .. "x" .. height)
        assert_true(candidate.playback.y >= bottom.y
            and candidate.timeline.y >= bottom.y,
            "main controls should stay in bottom zone at " .. width .. "x" .. height)
        assert_true(candidate.playlist.y >= top.y
            and candidate.playlist.y + candidate.playlist.height <= top.y + top.height,
            "playlist navigation should stay in top zone at " .. width .. "x" .. height)
        end
    end
end

test_split_zone_geometry()
test_width_adaptive_layout()
test_split_zone_matrix()
test_layout_rectangles()
test_timeline_labels_do_not_overlap()
test_minimal_timeline_geometry()
test_configurable_vertical_position()
test_dense_compact_layout_stays_inside_panel()

print("All layout tests passed.")
