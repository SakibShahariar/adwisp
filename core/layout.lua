-- Adwisp layout calculations.
-- Pure geometry: no mpv dependency, so hit-testing can share these values later.

local Layout = {}

function Layout.compute(width, height)
    if type(width) ~= "number" or type(height) ~= "number"
        or width ~= width or height ~= height
        or width == math.huge or width == -math.huge
        or height == math.huge or height == -math.huge
        or width <= 0 or height <= 0 then
        return nil
    end

    -- OSD dimensions are pixel counts; normalize fractional inputs before geometry.
    width = math.floor(width)
    height = math.floor(height)
    if width < 1 or height < 1 then return nil end

    local panel_width = math.min(560, math.max(1, width - 32))
    local compact = height < 240
    local panel_height = math.min(156, math.max(1, height - (compact and 16 or 32)))
    local x = math.floor((width - panel_width) / 2)
    local bottom_margin = compact and 8 or 42
    local y = math.max(compact and 8 or 16,
        math.floor(height - panel_height - bottom_margin))
    local padding = math.min(22, math.floor(panel_width * 0.06))
    local inner_x = x + padding
    local inner_width = math.max(1, panel_width - padding * 2)

    -- Keep both controls inside the panel even in narrow mpv windows.
    local control_gap = math.min(16, math.max(6, math.floor(inner_width * 0.06)))
    local playback_width = math.min(96,
        math.max(1, math.floor((inner_width - control_gap) * 0.45)))
    local volume_width = math.min(120,
        math.max(1, inner_width - playback_width - control_gap))
    local control_y = y + (compact and 34 or 51)
    local bar_y = y + (compact and 78 or math.min(104, math.floor(panel_height * 0.67)))
    local bar_x = inner_x
    local bar_width = inner_width
    local label_y = bar_y + (compact and 14 or 22)
    local labels_have_room = bar_width >= 164
    local progress_label = {
        x = bar_x, y = label_y, width = 36, visible = labels_have_room,
    }
    local time_label = {
        x = labels_have_room and (bar_x + bar_width - 120) or bar_x,
        y = label_y,
        width = labels_have_room and 120 or bar_width,
        visible = bar_width >= 40,
        compact = not labels_have_room,
        current_only = bar_width < 120,
        font_size = labels_have_room and 15 or 11,
    }

    local volume_x = inner_x + playback_width + control_gap
    local volume_track = {
        x = volume_x, y = control_y + 25, width = volume_width, height = 4,
    }
    local volume_hit = {
        x = volume_x, y = volume_track.y - 2, width = volume_width, height = 8,
    }

    return {
        width = width,
        height = height,
        compact = compact,
        panel = { x = x, y = y, width = panel_width, height = panel_height },
        title = { x = inner_x, y = y + (compact and 10 or 18), width = inner_width },
        playback = { x = inner_x, y = control_y, width = playback_width, height = compact and 24 or 32 },
        volume = {
            x = volume_x,
            y = control_y,
            width = volume_width,
            height = 32,
            track = volume_track,
            hit = volume_hit,
        },
        timeline = {
            x = bar_x, y = bar_y, width = bar_width, height = 6,
            hit_x = bar_x, hit_y = bar_y - 10, hit_width = bar_width, hit_height = 26,
        },
        progress_label = progress_label,
        time_label = time_label,
        playlist = { x = inner_x, y = y + (compact and 116 or 132), width = inner_width, height = 20 },
    }
end

return Layout
