-- Adwisp layout calculations.
-- Pure geometry, shared by rendering and mouse hit-testing.
--
-- Geometry follows the GTK-style player concept: a translucent bottom scrim
-- carrying a media row, a full-width timeline, and a centered transport with
-- volume and utility icons on the right.

local Layout = {}

local function finite(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

function Layout.compute(width, height, options)
    if not finite(width) or not finite(height) or width <= 0 or height <= 0 then
        return nil
    end

    width = math.floor(width)
    height = math.floor(height)
    if width < 1 or height < 1 then return nil end

    local layout_options = type(options) == "table" and options or {}
    local option_scale = layout_options.ui_scale
    if type(option_scale) ~= "number" or option_scale ~= option_scale or option_scale <= 0 then
        option_scale = 1
    end
    local ui_scale = math.max(0.5, math.min(4, option_scale))
        * (layout_options.fullscreen == true and 1.3 or 1)
    local function scaled(value) return math.floor(value * ui_scale + 0.5) end
    local minimal_timeline = layout_options.minimal_timeline == true
        and layout_options.timeline_expanded ~= true
    local compact = height < 300 or width < 640
    local dense = height < 220 or width < 400

    local scrim_height = scaled(math.floor(clamp(height * 0.36, 130, 220)))
    local pad = clamp(math.floor(width * 0.022), 10, 32)
    local x = 0
    local y = height - scrim_height
    local right = width - pad

    local top_bar = { x = pad, y = 8,
        width = math.max(1, width - pad * 2), height = scaled(dense and 32 or 40) }

    local thumbnail = { x = pad, y = y + 12,
        width = dense and 30 or 40, height = dense and 24 or 30 }
    if dense then thumbnail.width, thumbnail.height = 30, 24 end

    local title_x = thumbnail.x + thumbnail.width + 10
    local title = { x = title_x, y = y + (dense and 12 or 14),
        width = math.max(1, math.floor(width * 0.52) - title_x) }
    local status = { x = right - 150, y = title.y, width = 150 }

    local bar_y = y + math.floor(scrim_height * 0.32)
    local timeline = {
        x = pad, y = bar_y, width = math.max(1, right - pad),
        height = minimal_timeline and 2
            or (layout_options.timeline_expanded == true and scaled(10) or scaled(4)),
        minimal = minimal_timeline,
        hit_x = pad, hit_y = bar_y - 12,
        hit_width = math.max(1, right - pad), hit_height = 28,
    }
    local progress_label = { x = pad, y = bar_y + 14, width = 52,
        visible = not minimal_timeline and not dense }
    local time_label = {
        x = pad + (progress_label.visible and 60 or 0), y = bar_y + 14,
        width = 180, visible = not minimal_timeline,
        compact = false, current_only = false, font_size = dense and 14 or 16,
    }

    local cy = y + math.floor(scrim_height * 0.70)
    local center_x = math.floor(width / 2)
    local play_size = math.min(scaled(dense and 40 or 56), math.floor(scrim_height * 0.34))
    local nav_size = scaled(dense and 30 or 40)
    local nav_offset = dense and 56 or 84
    local prev = { x = center_x - nav_offset - math.floor(nav_size / 2),
        y = cy - math.floor(nav_size / 2), width = nav_size, height = nav_size }
    local play = { x = center_x - math.floor(play_size / 2),
        y = cy - math.floor(play_size / 2), width = play_size, height = play_size }
    local next = { x = center_x + nav_offset - math.floor(nav_size / 2),
        y = cy - math.floor(nav_size / 2), width = nav_size, height = nav_size }
    local transport = { prev = prev, play = play, next = next }
    local playlist = { x = prev.x, y = prev.y,
        width = next.x + next.width - prev.x, height = nav_size }

    local utility_size = scaled(dense and 20 or 24)
    local settings = { x = right - utility_size, y = cy - math.floor(utility_size / 2),
        width = utility_size, height = utility_size }
    local fullscreen = { x = settings.x - utility_size - 12, y = settings.y,
        width = utility_size, height = utility_size }
    local volume_x = dense and pad or math.max(
        center_x + 120, fullscreen.x - 150)
    volume_x = math.min(volume_x, math.max(pad, right - 60))
    local volume_width = math.max(1, math.min(scaled(dense and 56 or 72), right - volume_x))
    local volume_icon = scaled(18)
    local track = { x = volume_x + volume_icon + 4, y = cy - 2,
        width = math.max(1, volume_width - volume_icon - 4), height = 4 }
    local volume = { x = volume_x, y = cy - 16, width = volume_width, height = 32,
        track = track,
        hit = { x = track.x, y = cy - 14, width = track.width, height = 28 } }

    return {
        width = width,
        height = height,
        compact = compact,
        dense = dense,
        position = "bottom",
        panel = { x = x, y = y, width = width, height = scrim_height },
        top_bar = top_bar,
        top_zone = nil,
        title = title,
        status = status,
        divider_y = bar_y - 12,
        thumbnail = thumbnail,
        transport = transport,
        playback = play,
        playlist = playlist,
        volume = volume,
        fullscreen = fullscreen,
        settings = settings,
        timeline = timeline,
        progress_label = progress_label,
        time_label = time_label,
    }
end

return Layout
