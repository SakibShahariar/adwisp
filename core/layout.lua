-- Adwisp layout calculations.
-- Pure geometry: no mpv dependency, so hit-testing can share these values later.

local Layout = {}

function Layout.compute(width, height, options)
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
    -- Switch to the compact arrangement when either axis is constrained.
    -- This keeps narrow, tall player windows from retaining desktop-sized rows.
    local compact = height < 240 or panel_width < 420
    local panel_height = math.min(156, math.max(1, height - (compact and 16 or 32)))
    -- Very short windows need a denser row arrangement, not merely a shorter panel.
    local dense_compact = compact and panel_height < 144
    local x = math.floor((width - panel_width) / 2)
    local layout_options = type(options) == "table" and options or {}
    local minimal_timeline = layout_options.minimal_timeline == true
        and layout_options.timeline_expanded ~= true
    local position = layout_options.osd_position
    if position ~= "top" and position ~= "bottom" and position ~= "custom" then
        position = "bottom"
    end

    local margin = layout_options.osd_margin
    if type(margin) ~= "number" or margin ~= margin
        or margin == math.huge or margin == -math.huge or margin < 0 then
        margin = compact and 8 or 42
    end
    local max_y = math.max(0, height - panel_height)
    margin = math.min(math.floor(margin), max_y)

    local y
    if position == "top" then
        y = margin
    elseif position == "custom" then
        local offset = layout_options.osd_custom_offset
        if type(offset) == "number" and offset == offset
            and offset ~= math.huge and offset ~= -math.huge and offset >= 0 then
            y = math.max(0, math.min(max_y, math.floor(offset)))
        else
            position = "bottom"
            y = max_y - margin
        end
    else
        y = max_y - margin
    end
    local split_zones = layout_options.control_zones == "split" and not compact and position == "bottom"
    local top_zone
    local top_margin = layout_options.top_zone_margin
    if type(top_margin) ~= "number" or top_margin ~= top_margin
        or top_margin == math.huge or top_margin == -math.huge or top_margin < 0 then
        top_margin = 24
    end
    top_margin = math.min(math.floor(top_margin), math.max(0, height - 44))
    if split_zones then
        if y >= top_margin + 76 then
            top_zone = { x = x, y = top_margin, width = panel_width, height = 64 }
        end
    end
    local padding = math.min(22, math.floor(panel_width * 0.06))
    local inner_x = x + padding
    local inner_width = math.max(1, panel_width - padding * 2)

    -- Keep both controls inside the panel even in narrow mpv windows.
    local control_gap = math.min(16, math.max(6, math.floor(inner_width * 0.06)))
    local playback_width = math.min(96,
        math.max(1, math.floor((inner_width - control_gap) * 0.45)))
    local volume_width = math.min(120,
        math.max(1, inner_width - playback_width - control_gap))
    -- Position rows as proportions of the actual panel height. The reference
    -- profiles preserve the established 156px, compact, and dense arrangements,
    -- while allowing short panels to compress without unrelated fixed offsets.
    local function panel_offset(reference_offset, reference_height)
        return math.floor(reference_offset * panel_height / reference_height + 0.5)
    end
    local control_y = y + (dense_compact and panel_offset(22, 104)
        or (compact and panel_offset(34, 156) or panel_offset(51, 156)))
    local bar_y = y + (dense_compact and panel_offset(59, 104)
        or (compact and panel_offset(78, 156) or panel_offset(104, 156)))
    local bar_x = inner_x
    local bar_width = inner_width
    local label_y = bar_y + (dense_compact and panel_offset(8, 104)
        or (compact and panel_offset(14, 156) or panel_offset(12, 156)))
    local labels_have_room = bar_width >= 164
    local progress_label = {
        x = bar_x, y = label_y, width = 36, visible = labels_have_room and not minimal_timeline,
    }
    local time_label = {
        x = labels_have_room and (bar_x + bar_width - 120) or bar_x,
        y = label_y,
        width = labels_have_room and 120 or bar_width,
        visible = bar_width >= 40 and not minimal_timeline,
        compact = not labels_have_room,
        current_only = bar_width < 120,
        font_size = labels_have_room and 15 or 11,
    }

    local volume_x = inner_x + playback_width + control_gap
    local volume_reference_height = dense_compact and 104 or 156
    local volume_track_offset = dense_compact and panel_offset(17, 104)
        or panel_offset(25, 156)
    local volume_track_height = math.max(2,
        panel_offset(4, volume_reference_height))
    local volume_hit_inset = math.max(1,
        panel_offset(2, volume_reference_height))
    local volume_track = {
        x = volume_x,
        y = control_y + volume_track_offset,
        width = volume_width,
        height = volume_track_height,
    }
    local volume_hit = {
        x = volume_x,
        y = volume_track.y - volume_hit_inset,
        width = volume_width,
        height = volume_track_height + volume_hit_inset * 2,
    }

    local title_geometry = top_zone and { x = inner_x, y = top_zone.y + 12, width = inner_width }
        or { x = inner_x, y = y + (dense_compact and panel_offset(5, 104)
            or (compact and panel_offset(10, 156) or 18)), width = inner_width }

    local playlist_geometry = top_zone and {
        x = inner_x, y = top_zone.y + 40, width = inner_width, height = 18,
    } or {
        x = inner_x,
        y = y + (dense_compact and panel_offset(80, 104)
            or (compact and panel_offset(116, 156) or 132)),
        width = inner_width,
        height = dense_compact and panel_offset(14, 104)
            or (compact and panel_offset(20, 156) or 20),
    }

    return {
        width = width,
        height = height,
        compact = compact,
        position = position,
        panel = { x = x, y = y, width = panel_width, height = panel_height },
        top_zone = top_zone,
        title = title_geometry,
        playback = { x = inner_x, y = control_y, width = playback_width,
            height = dense_compact and panel_offset(18, 104)
                or (compact and panel_offset(24, 156) or 32) },
        volume = {
            x = volume_x,
            y = control_y,
            width = volume_width,
            height = dense_compact and panel_offset(24, 104)
                or panel_offset(32, 156),
            track = volume_track,
            hit = volume_hit,
        },
        timeline = {
            x = bar_x, y = bar_y, width = bar_width,
            height = minimal_timeline and 2 or 6,
            minimal = minimal_timeline,
            hit_x = bar_x, hit_y = bar_y - 10, hit_width = bar_width, hit_height = 26,
        },
        progress_label = progress_label,
        time_label = time_label,
        playlist = playlist_geometry,
    }
end

return Layout
