-- Adwisp layout: geometry derived from docs/MOCKUP_SPEC.md.
-- Pure geometry shared by rendering and hit-testing; integer pixels only.

local Layout = {}

local function finite(v)
    return type(v) == "number" and v == v
        and v ~= math.huge and v ~= -math.huge
end

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

function Layout.compute(width, height, options)
    if not finite(width) or not finite(height) or width <= 0 or height <= 0 then
        return nil
    end
    width, height = math.floor(width), math.floor(height)
    if width < 1 or height < 1 then return nil end

    local o = type(options) == "table" and options or {}
    local scale = o.ui_scale
    if not finite(scale) or scale <= 0 then scale = 1 end
    scale = clamp(scale, 0.5, 4)
    if o.fullscreen == true then scale = scale * 1.3 end
    local function s(v) return math.floor(v * scale + 0.5) end

    local compact = width < 760 or height < 500
    local pad = s(24)

    -- Bottom control area: 180px at base scale, clamped to fit the OSD.
    local panel_height = math.min(s(180), math.max(s(96), height - s(48)))
    local panel_y = height - panel_height

    -- Title bar
    local title_bar = { x = 0, y = 0, width = width, height = s(48) }
    local hamburger = { x = pad, y = s(12), width = s(24), height = s(24) }
    local wc_btn = s(22)
    local wc_gap = s(6)
    local wc_width = wc_btn * 3 + wc_gap * 2
    local window_controls = { x = width - pad - wc_width - s(8),
        y = math.floor((title_bar.height - wc_btn) / 2),
        width = wc_width, height = wc_btn, button = wc_btn, gap = wc_gap }

    -- Media row
    local thumb_size = s(40)
    local media_y = panel_y + s(16)
    local thumbnail = { x = pad, y = media_y, width = thumb_size, height = thumb_size }
    local title = { x = pad + thumb_size + s(12), y = media_y + s(4),
        width = math.max(1, math.floor(width * 0.55) - (pad + thumb_size + s(12))) }
    local media_actions = { x = width - pad - s(64), y = media_y + s(8),
        width = s(64), height = s(24) }

    -- Timeline
    local bar_y = panel_y + s(68)
    local timeline = {
        x = pad, y = bar_y, width = math.max(1, width - pad * 2),
        height = (o.minimal_timeline and o.timeline_expanded ~= true) and s(2) or s(5),
        minimal = o.minimal_timeline == true and o.timeline_expanded ~= true,
        minimal = o.minimal_timeline == true,
        hit_x = pad, hit_y = bar_y - s(12),
        hit_width = math.max(1, width - pad * 2), hit_height = s(28),
    }

    -- Control row
    local control_y = panel_y + s(108)
    local play_size = s(56)
    local nav_size = s(32)
    local center_x = math.floor(width / 2)
    local play = { x = center_x - math.floor(play_size / 2), y = control_y - s(4),
        width = play_size, height = play_size }
    local prev = { x = play.x - s(48) - nav_size, y = control_y + s(4),
        width = nav_size, height = nav_size }
    local next = { x = play.x + play.width + s(48), y = prev.y,
        width = nav_size, height = nav_size }
    local repeat_left = { x = prev.x - s(48) - nav_size, y = prev.y,
        width = nav_size, height = nav_size }
    local repeat_right = { x = next.x + next.width + s(48), y = prev.y,
        width = nav_size, height = nav_size }

    local time_label = { x = pad, y = control_y + s(8), width = s(180),
        visible = not (o.minimal_timeline == true and o.timeline_expanded ~= true), compact = false, current_only = false,
        font_size = s(14) }
    local progress_label = { x = pad, y = bar_y - s(22), width = s(52),
        visible = not (o.minimal_timeline == true and o.timeline_expanded ~= true) }

    -- Right utilities: volume, fullscreen, settings
    local utility_size = s(24)
    local settings = { x = width - pad - utility_size, y = control_y + s(8),
        width = utility_size, height = utility_size }
    local fullscreen = { x = settings.x - utility_size - s(16), y = settings.y,
        width = utility_size, height = utility_size }
    local volume_width = s(120)
    local volume_x = fullscreen.x - volume_width - s(24)
    local track = { x = volume_x + s(26), y = control_y + s(18),
        width = volume_width - s(26), height = s(4) }
    local volume = { x = volume_x, y = control_y + s(4), width = volume_width,
        height = s(32), track = track,
        hit = { x = track.x, y = track.y - s(10),
            width = track.width, height = s(24) } }

    return {
        width = width, height = height, compact = compact,
        scale = scale,
        panel = { x = 0, y = panel_y, width = width, height = panel_height },
        title_bar = title_bar,
        hamburger = hamburger,
        window_controls = window_controls,
        thumbnail = thumbnail,
        title = title,
        media_actions = media_actions,
        timeline = timeline,
        progress_label = progress_label,
        time_label = time_label,
        volume = volume,
        fullscreen = fullscreen,
        settings = settings,
        transport = {
            prev = prev, play = play, next = next,
            repeat_left = repeat_left, repeat_right = repeat_right,
        },
        playback = play,
        playlist = { x = prev.x, y = prev.y,
            width = next.x + next.width - prev.x, height = nav_size },
    }
end

return Layout
