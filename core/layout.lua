-- Adwisp layout calculations.
-- Pure geometry: no mpv dependency, so hit-testing can share these values.
--
-- The grid follows GNOME HIG spacing (multiples of 8 where possible): a header
-- band, a separated control band, then the timeline and its labels. All values
-- are integer pixels because mpv's OSD and ASS drawing are pixel based.

local Layout = {}

local function finite(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

function Layout.compute(width, height, options)
    if not finite(width) or not finite(height)
        or width <= 0 or height <= 0 then
        return nil
    end

    width = math.floor(width)
    height = math.floor(height)
    if width < 1 or height < 1 then return nil end

    local panel_width = math.min(640, math.max(1, width - 32))
    local compact = height < 260
    local dense = compact or panel_width < 480
    local panel_height = dense and 140 or 200
    panel_height = math.min(panel_height, math.max(1, height - 4))
    local scale = panel_height / (dense and 140 or 200)
    local function sy(value) return math.floor(value * scale + 0.5) end
    local x = math.floor((width - panel_width) / 2)

    local layout_options = type(options) == "table" and options or {}
    local minimal_timeline = layout_options.minimal_timeline == true
        and layout_options.timeline_expanded ~= true
    local position = layout_options.osd_position
    if position ~= "top" and position ~= "bottom" and position ~= "custom" then
        position = "bottom"
    end

    local margin = layout_options.osd_margin
    if not finite(margin) or margin < 0 then
        margin = compact and 16 or 42
    end
    local max_y = math.max(0, height - panel_height)
    margin = math.min(math.floor(margin), max_y)

    local y
    if position == "top" then
        y = margin
    elseif position == "custom" then
        local offset = layout_options.osd_custom_offset
        if finite(offset) and offset >= 0 then
            y = math.max(0, math.min(max_y, math.floor(offset)))
        else
            position = "bottom"
            y = max_y - margin
        end
    else
        y = max_y - margin
    end

    local split_zones = layout_options.control_zones == "split"
        and not compact and not dense and position == "bottom"
    local top_zone
    local top_margin = layout_options.top_zone_margin
    if not finite(top_margin) or top_margin < 0 then top_margin = 24 end
    top_margin = math.min(math.floor(top_margin), math.max(0, height - 88))
    if split_zones and y >= top_margin + 88 then
        top_zone = { x = x, y = top_margin, width = panel_width, height = 80 }
    end

    local pad = dense and 16 or 24
    local inner_x = x + pad
    local inner_width = math.max(1, panel_width - pad * 2)
    local right_edge = x + panel_width - pad

    local title_y = y + sy(dense and 12 or 20)
    local status_width = dense and 132 or 200
    local title_width = math.max(1, inner_width - status_width - 8)
    local title = top_zone
        and { x = inner_x, y = top_zone.y + 12, width = title_width }
        or { x = inner_x, y = title_y, width = title_width }
    local status = {
        x = right_edge - status_width,
        y = title.y,
        width = status_width,
    }
    local divider_y = title.y + sy(dense and 30 or 38)

    local tiny = panel_width < 300
    local control_h = math.max(20, sy(dense and 40 or 56))
    local nav_size = tiny and 0 or math.max(18, sy(dense and 32 or 44))
    local play_width = tiny and 40 or math.max(40, sy(dense and 116 or 168))
    local gap = tiny and 0 or (dense and 6 or 8)
    local group_gap = tiny and 8 or (dense and 16 or 24)
    local control_y = y + sy(dense and 52 or 76)

    local prev = { x = inner_x, y = control_y + math.floor((control_h - nav_size) / 2),
        width = nav_size, height = nav_size }
    local next = { x = prev.x + nav_size + gap, y = prev.y,
        width = nav_size, height = nav_size }
    local play = { x = next.x + nav_size + group_gap, y = control_y,
        width = play_width, height = control_h }

    local volume_x = play.x + play_width + group_gap
    local icon_width = sy(dense and 20 or 28)
    local volume_width = math.max(1, right_edge - volume_x)
    local track_height = math.max(2, sy(dense and 4 or 6))
    local track_x = volume_x + icon_width
    local track_width = math.max(1, volume_width - icon_width)
    local track_y = control_y + math.floor(control_h / 2) - math.floor(track_height / 2)
        + sy(dense and 10 or 14)
    local volume_track = { x = track_x, y = track_y, width = track_width, height = track_height }
    local volume_hit = { x = track_x, y = track_y - 8,
        width = track_width, height = track_height + 16 }
    local volume = { x = volume_x, y = control_y, width = volume_width,
        height = control_h, track = volume_track, hit = volume_hit }

    local bar_y = y + sy(dense and 108 or 154)
    local bar_x = inner_x
    local bar_width = inner_width
    local label_y = bar_y + sy(dense and 10 or 16)
    local labels_have_room = bar_width >= 180
    local progress_label = {
        x = bar_x, y = label_y, width = 44,
        visible = labels_have_room and not minimal_timeline,
    }
    local time_label = {
        x = labels_have_room and (bar_x + bar_width - 132) or bar_x,
        y = label_y,
        width = labels_have_room and 132 or bar_width,
        visible = bar_width >= 44 and not minimal_timeline,
        compact = not labels_have_room,
        current_only = bar_width < 130,
        font_size = labels_have_room and 16 or 12,
    }

    local playlist = top_zone
        and { x = inner_x + play_width + group_gap,
              y = top_zone.y + 16, width = nav_size * 2 + gap, height = nav_size }
        or { x = prev.x, y = prev.y, width = nav_size * 2 + gap, height = nav_size }
    if top_zone then
        title.width = math.max(1, playlist.x - gap - inner_x)
        status.x = right_edge - status_width
        status.width = status_width
    end

    return {
        width = width,
        height = height,
        compact = compact,
        dense = dense,
        position = position,
        panel = { x = x, y = y, width = panel_width, height = panel_height },
        top_zone = top_zone,
        title = title,
        status = status,
        divider_y = divider_y,
        transport = { prev = prev, play = play, next = next },
        playback = play,
        playlist = playlist,
        volume = volume,
        timeline = {
            x = bar_x, y = bar_y, width = bar_width,
            height = minimal_timeline and 2 or 6,
            minimal = minimal_timeline,
            hit_x = bar_x, hit_y = bar_y - 12, hit_width = bar_width, hit_height = 30,
        },
        progress_label = progress_label,
        time_label = time_label,
    }
end

return Layout
