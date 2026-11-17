-- Adwisp renderer: ASS OSD drawing only.
-- Copyright (c) 2026 Adwisp contributors
-- MIT License. See LICENSE.

local Layout = require "core.layout"
local Theme = require "core.theme"
local I18n = require "core.i18n"

local Renderer = {}
Renderer.__index = Renderer

local function escape_ass(value)
    return tostring(value or "")
        :gsub("\\", "\\\\")
        :gsub("{", "\\{")
        :gsub("}", "\\}")
        :gsub("\r", " ")
        :gsub("\n", " ")
end

local function truncate_title(value, max_chars)
    value = tostring(value or "")
    if max_chars < 2 then return "…" end

    -- Count UTF-8 code points without depending on Lua's optional utf8 library.
    local count, index = 0, 1
    while index <= #value do
        local byte = value:byte(index)
        local step = 1
        if byte >= 240 then step = 4
        elseif byte >= 224 then step = 3
        elseif byte >= 192 then step = 2 end
        index = index + step
        count = count + 1
    end
    if count <= max_chars then return value end

    local keep = max_chars - 1
    local chars, pos = 0, 1
    while pos <= #value and chars < keep do
        local byte = value:byte(pos)
        local step = 1
        if byte >= 240 then step = 4
        elseif byte >= 224 then step = 3
        elseif byte >= 192 then step = 2 end
        pos = pos + step
        chars = chars + 1
    end
    return value:sub(1, pos - 1) .. "…"
end

local function is_finite_number(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

-- ASS drawing helpers. Adwaita surfaces are rounded, layered, and lightly
-- outlined; these build the vector paths and one-tag-per-shape strings used by
-- the renderer. All coordinates are integer pixels because ASS \pos is pixel
-- based and Lua 5.3+ rejects fractional values for %d.

local function px(value)
    if not is_finite_number(value) then return 0 end
    return math.floor(value + 0.5)
end

local function rect_path(w, h)
    w, h = px(w), px(h)
    return string.format("m 0 0 l %d 0 %d %d 0 %d", w, w, h, h)
end

local function rounded_rect_path(w, h, radius)
    w, h = px(w), px(h)
    local r = math.max(0, math.min(px(radius), math.floor(math.min(w, h) / 2)))
    if r == 0 then return rect_path(w, h) end
    local k = px(r * 0.5523)
    return table.concat({
        string.format("m %d 0 l %d 0", r, w - r),
        string.format("b %d 0 %d %d %d %d", w - r + k, w, r - k, w, r),
        string.format("l %d %d", w, h - r),
        string.format("b %d %d %d %d %d %d", w, h - r + k, w - r + k, h, w - r, h),
        string.format("l %d %d", r, h),
        string.format("b %d %d %d %d %d %d", r - k, h, 0, h - r + k, 0, h - r),
        string.format("l 0 %d", r),
        string.format("b 0 %d %d 0 %d 0", r - k, r - k, r),
    }, " ")
end

local function circle_path(diameter)
    local d = math.max(2, px(diameter))
    local r = math.floor(d / 2)
    local k = px(r * 0.5523)
    return table.concat({
        string.format("m %d %d", d, r),
        string.format("b %d %d %d %d %d %d", d, r + k, r + k, d, r, d),
        string.format("b %d %d %d %d %d %d", r - k, d, 0, r + k, 0, r),
        string.format("b 0 %d %d 0 %d 0", r - k, r - k, r),
        string.format("b %d 0 %d %d %d %d", r + k, d, r - k, d, r),
    }, " ")
end

local function icon_path(kind, size)
    local s = px(size)
    local function c(value) return px(s * value) end
    local function box(x1, y1, x2, y2)
        return string.format("m %d %d l %d %d %d %d %d %d",
            c(x1), c(y1), c(x2), c(y1), c(x2), c(y2), c(x1), c(y2))
    end
    if kind == "play" then
        return string.format("m %d %d l %d %d %d %d",
            c(0.34), c(0.20), c(0.34), c(0.80), c(0.78), c(0.50))
    elseif kind == "pause" then
        return box(0.26, 0.20, 0.43, 0.80) .. " " .. box(0.57, 0.20, 0.74, 0.80)
    elseif kind == "prev" then
        return box(0.18, 0.22, 0.28, 0.78)
            .. string.format(" m %d %d l %d %d %d %d",
                c(0.78), c(0.22), c(0.38), c(0.50), c(0.78), c(0.78))
    elseif kind == "next" then
        return box(0.72, 0.22, 0.82, 0.78)
            .. string.format(" m %d %d l %d %d %d %d",
                c(0.22), c(0.22), c(0.62), c(0.50), c(0.22), c(0.78))
    elseif kind == "volume" then
        return box(0.08, 0.38, 0.28, 0.62)
            .. string.format(" m %d %d l %d %d %d %d %d %d",
                c(0.28), c(0.38), c(0.54), c(0.18), c(0.54), c(0.82), c(0.28), c(0.62))
    end
    return rect_path(size, size)
end

local function shape(x, y, color, alpha_marker, path)
    return string.format("{\\an7\\pos(%d,%d)\\bord0\\shad0\\1c%s\\alpha%s\\p1}%s{\\p0}\n",
        px(x), px(y), color, alpha_marker, path)
end

local function outline(x, y, w, h, radius, color, alpha_marker, stroke)
    return string.format("{\\an7\\pos(%d,%d)\\bord%d\\shad0\\1a&HFE&\\alpha%s\\3c%s\\3a%s\\p1}%s{\\p0}\n",
        px(x), px(y), math.max(1, px(stroke or 2)), alpha_marker, color, alpha_marker,
        rounded_rect_path(w, h, radius))
end

local function translate(state, key, fallback)
    return I18n.t(state and state.translations, key, fallback)
end

local function translate_format(state, key, fallback, ...)
    local template = translate(state, key, fallback)
    local ok, formatted = pcall(string.format, template, ...)
    if ok then return formatted end
    return string.format(fallback, ...)
end

local function safe_font_family(value)
    if type(value) ~= "string" then return "Sans" end
    value = value:sub(1, 48):gsub("[^%w _%-]", "")
    value = value:match("^%s*(.-)%s*$")
    return value ~= "" and value or "Sans"
end

local function fmt_time(seconds)
    if not is_finite_number(seconds) or seconds < 0 then return "--:--" end
    -- mpv timestamps are normally small; cap hostile metadata before integer formatting.
    seconds = math.floor(math.min(seconds, 2147483647))
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    if hours > 0 then return string.format("%d:%02d:%02d", hours, minutes, secs) end
    return string.format("%d:%02d", minutes, secs)
end

local function render_menu_panel(menu, width, height, colors, font_family, font_scale)
    if type(menu) ~= "table" or type(menu.lines) ~= "table" or #menu.lines == 0 then
        return ""
    end

    local lines = menu.lines
    local available_height = math.max(1, height - 16)
    local line_height = math.max(6, math.min(22,
        math.floor(math.max(1, available_height - 20) / #lines)))
    local panel_width = math.max(1, math.min(520, width - 16))
    local panel_height = math.min(available_height, 20 + #lines * line_height)
    local x = math.max(0, width - panel_width - 8)
    local y = math.max(0, math.floor((height - panel_height) / 2))
    local font_size = math.max(8, math.min(17,
        math.floor(line_height * 0.72 * font_scale + 0.5)))
    local max_chars = math.max(1, math.floor((panel_width - 28) / (font_size * 0.56)))
    local ass = shape(x + 2, y + 3, colors.background, "&H50&",
        rounded_rect_path(panel_width, panel_height, 10))
        .. shape(x, y, colors.surface, "&H10&",
        rounded_rect_path(panel_width, panel_height, 10))
        .. outline(x, y, panel_width, panel_height, 10, colors.muted, "&H30&", 1)

    for index, line in ipairs(lines) do
        local selected = menu.selected_line == index
        local color = selected and colors.on_accent
            or (index == 1 and colors.accent or (index == 2 and colors.muted or colors.text))
        local bold = (index == 1 or selected) and 1 or 0
        local line_y = y + 10 + (index - 1) * line_height
        if selected then
            ass = ass .. shape(x + 8, line_y - 2, colors.accent, "&H30&",
                rounded_rect_path(panel_width - 16, line_height, 5))
        end
        ass = ass .. string.format(
            "{\\an7\\pos(%d,%d)\\fn%s\\fs%d\\b%d\\1c%s}%s\\N",
            x + 14, line_y, font_family, font_size, bold, color,
            escape_ass(truncate_title(line, max_chars))
        )
    end
    return ass
end

function Renderer.new(mp, state)
    local self = setmetatable({}, Renderer)
    self.mp = mp
    self.state = state
    self.overlay = mp.create_osd_overlay("ass-events")
    self.overlay.z = 20
    self.last_size = nil
    self.last_data = nil
    return self
end

function Renderer:set_palette(palette)
    self.state.palette = palette
    self.last_data = nil
end

function Renderer:clear()
    if self.last_data == "" then return end
    self.overlay.data = ""
    self.overlay:update()
    self.last_data = ""
end

function Renderer:render()
    local state = self.state
    if not state.visible then
        self:clear()
        return
    end

    local width, height = self.mp.get_osd_size()
    if not width or not height or width <= 0 or height <= 0 then return end

    local time_pos = is_finite_number(state.time_pos) and state.time_pos or 0
    local duration = is_finite_number(state.duration) and state.duration or 0
    local volume_value = is_finite_number(state.volume) and state.volume or 0
    volume_value = math.max(0, math.min(100, volume_value))
    local now = fmt_time(state.time_pos)
    local total = fmt_time(state.duration)
    local progress = 0
    if duration > 0 then
        progress = math.max(0, math.min(1, time_pos / duration))
    end

    local layout_options = type(state.layout_options) == "table"
        and state.layout_options or {}
    local layout = Layout.compute(width, height, layout_options)
    if not layout then return end
    local top_zone_visible = not layout.top_zone
        or layout_options.top_zone_visibility ~= "hover"
        or state.hover_zone == "top" or state.focus_target == "playlist"
    local bottom_zone_visible = not layout.top_zone
        or layout_options.bottom_zone_visibility ~= "hover"
        or state.hover_zone == "bottom" or state.focus_target == "playback"
        or state.focus_target == "volume" or state.focus_target == "timeline"
    local panel = layout.panel
    local title_pos = layout.title
    local title_font_size = layout.compact and 20 or 26
    local status_labels = {}
    if state.buffering == true then
        local buffering_progress = is_finite_number(state.buffering_progress)
            and math.max(0, math.min(100, state.buffering_progress)) or 0
        if layout.compact and title_pos.width < 240 then
            status_labels[#status_labels + 1] = translate(state, "buffering", "Buffering")
        else
            status_labels[#status_labels + 1] = translate_format(state, "buffering_percent", "Buffering %d%%",
                math.floor(buffering_progress + 0.5))
        end
    end
    local loop_file = state.loop_file
    if loop_file == "inf" or (is_finite_number(tonumber(loop_file)) and tonumber(loop_file) > 0) then
        status_labels[#status_labels + 1] = translate(state, "loop", "Loop")
    end
    local loop_a = is_finite_number(state.ab_loop_a) and state.ab_loop_a or -1
    local loop_b = is_finite_number(state.ab_loop_b) and state.ab_loop_b or -1
    if loop_a >= 0 and loop_b >= 0 then
        status_labels[#status_labels + 1] = "A–B"
    elseif loop_a >= 0 then
        status_labels[#status_labels + 1] = "A"
    elseif loop_b >= 0 then
        status_labels[#status_labels + 1] = "B"
    end
    if state.image_mode == true then
        local image_zoom = is_finite_number(state.image_zoom)
            and math.max(-4, math.min(4, state.image_zoom)) or 0
        status_labels[#status_labels + 1] = translate_format(state, "image_zoom",
            "Image · Zoom %d%%", math.floor(100 * (2 ^ image_zoom) + 0.5))
    end
    if type(state.chapter_title) == "string" and state.chapter_title ~= "" then
        status_labels[#status_labels + 1] = translate_format(state, "chapter_status", "Chapter: %s", truncate_title(state.chapter_title, 14))
    end
    if (tonumber(state.audio_track_count) or 0) > 0 then
        local audio_label = type(state.audio_track_label) == "string"
            and state.audio_track_label ~= "" and state.audio_track_label or "—"
        status_labels[#status_labels + 1] = translate_format(state, "audio_status", "A: %s", truncate_title(audio_label, 10))
    end
    if (tonumber(state.subtitle_track_count) or 0) > 0 then
        local subtitle_label = type(state.subtitle_track_label) == "string"
            and state.subtitle_track_label ~= "" and state.subtitle_track_label or "Off"
        if subtitle_label == "Off" then
            subtitle_label = translate(state, "off", "Off")
        end
        status_labels[#status_labels + 1] = translate_format(state, "subtitle_status", "S: %s", truncate_title(subtitle_label, 10))
    end
    local status_text = escape_ass(truncate_title(table.concat(status_labels, " · "), 64))
    local title_chars = math.max(6,
        math.floor(title_pos.width / (title_font_size * 0.56)))
    local title = escape_ass(truncate_title(
        state.title ~= "" and state.title or "Adwisp", title_chars
    ))
    local playback = layout.playback
    local volume = layout.volume
    local timeline = layout.timeline
    local progress_label = layout.progress_label
    local time_label = layout.time_label
    local playlist = layout.playlist
    local playlist_label = ""
    local playlist_count = is_finite_number(state.playlist_count)
        and math.max(0, math.floor(state.playlist_count)) or 0
    if playlist_count >= 2 then
        playlist_label = translate(state, "playlist_controls", "‹    Previous       Next    ›")
        if is_finite_number(state.playlist_pos) and state.playlist_pos >= 0 then
            local playlist_pos = math.floor(state.playlist_pos)
            if playlist_pos < playlist_count then
                playlist_label = translate_format(state, "playlist_controls_position", "‹    Previous      %d / %d      Next    ›",
                    playlist_pos + 1, playlist_count)
            end
        end
    end
    playlist_label = escape_ass(playlist_label)
    local filled = math.floor(timeline.width * progress)
    local pause_label = state.paused and translate(state, "play", "Play") or translate(state, "pause", "Pause")
    local playback_label = escape_ass(string.format("%s  %.2g×", pause_label,
        is_finite_number(state.speed) and math.max(0.01, math.min(100, state.speed)) or 1))
    local volume_label = state.mute and translate(state, "muted", "Muted")
        or (volume_value <= 20 and translate_format(state, "low_volume", "Low volume %d%%", math.floor(volume_value + 0.5))
            or translate_format(state, "volume", "Volume %d%%", math.floor(volume_value + 0.5)))
    volume_label = escape_ass(volume_label)
    local progress_text = progress_label.visible
        and string.format("%d%%", math.floor(progress * 100 + 0.5)) or ""
    local time_text = ""
    if time_label.visible then
        if time_label.current_only then
            time_text = now
        elseif time_label.compact then
            time_text = now .. "/" .. total
        else
            time_text = now .. " / " .. total
        end
    end

    local preview_label = ""
    local preview_label_x, preview_label_y
    if state.preview_visible == true and is_finite_number(state.preview_time) then
        preview_label = fmt_time(state.preview_time)
        local preview_width = is_finite_number(state.preview_width)
            and math.max(0, state.preview_width) or 0
        local preview_height = is_finite_number(state.preview_height)
            and math.max(0, state.preview_height) or 0
        if preview_width > 0 and preview_height > 0 then
            local preview_x = is_finite_number(state.preview_x) and state.preview_x or 0
            local preview_y = is_finite_number(state.preview_y) and state.preview_y or 0
            local horizontal_margin = math.min(40, width / 2)
            preview_label_x = math.max(horizontal_margin, math.min(
                width - horizontal_margin, preview_x + preview_width / 2))
            preview_label_y = preview_y - 20
            if preview_label_y < 8 then
                preview_label_y = preview_y + preview_height + 8
            end
            local vertical_margin = math.min(8, height / 2)
            preview_label_y = math.max(vertical_margin, math.min(
                height - vertical_margin, preview_label_y))
            -- ASS positions are integer pixels; mouse-derived values may be fractional.
            preview_label_x = math.floor(preview_label_x + 0.5)
            preview_label_y = math.floor(preview_label_y + 0.5)
        else
            preview_label = ""
        end
    end

    local font_family = safe_font_family(layout_options.font_family)
    local font_scale = layout_options.font_scale
    if not is_finite_number(font_scale) then font_scale = 1 end
    font_scale = math.max(0.75, math.min(1.25, font_scale))

    local colors = Theme.to_ass(state.palette)
    local volume_label_color = (state.mute or volume_value <= 20)
        and colors.accent or colors.muted
    local transport = layout.transport
    local status_pos = layout.status
    local control_h = layout.transport.play.height
    local pad = layout.dense and 16 or 24
    local inner_x = panel.x + pad
    local volume_fraction = volume_value / 100
    local volume_fill = math.floor(volume.track.width * volume_fraction)

    local focus_geometry
    if state.focus_target == "playback" then
        focus_geometry = layout.playback
    elseif state.focus_target == "volume" then
        focus_geometry = layout.volume
    elseif state.focus_target == "playlist" and playlist_count >= 2 then
        focus_geometry = layout.playlist
    elseif state.focus_target == "timeline" then
        focus_geometry = {
            x = layout.timeline.x,
            y = layout.timeline.y - 4,
            width = layout.timeline.width,
            height = layout.timeline.height + 8,
        }
    end
    local focus_ass = ""
    if focus_geometry and ((state.focus_target == "playlist" and top_zone_visible)
        or (state.focus_target ~= "playlist" and bottom_zone_visible)) then
        local focus_panel = state.focus_target == "playlist" and layout.top_zone or panel
        local focus_x = math.max(focus_panel.x, focus_geometry.x - 4)
        local focus_y = math.max(focus_panel.y, focus_geometry.y - 4)
        local focus_right = math.min(focus_panel.x + focus_panel.width,
            focus_geometry.x + focus_geometry.width + 4)
        local focus_bottom = math.min(focus_panel.y + focus_panel.height,
            focus_geometry.y + focus_geometry.height + 4)
        local focus_width = focus_right - focus_x
        local focus_height = focus_bottom - focus_y
        if focus_width > 4 and focus_height > 4 then
            focus_ass = outline(focus_x, focus_y, focus_width, focus_height,
                    math.min(12, focus_height / 2), colors.accent, "&H40&", 2)
                .. shape(focus_x + 3, focus_y + 3, colors.background, "&H18&",
                    rounded_rect_path(focus_width - 6, focus_height - 6,
                        math.min(10, focus_height / 2)))
        end
    end
    if not top_zone_visible then
        title = ""
        status_text = ""
        playlist_label = ""
    end
    if not bottom_zone_visible then
        playback_label = ""
        volume_label = ""
        progress_text = ""
        time_text = ""
        preview_label = ""
    end

    local top_zone_ass = ""
    if layout.top_zone and top_zone_visible then
        local top = layout.top_zone
        local top_color = state.hover_zone == "top" and colors.surface or colors.background
        top_zone_ass = shape(top.x, top.y, top_color, "&H1A&",
            rounded_rect_path(top.width, top.height, 12))
            .. outline(top.x, top.y, top.width, top.height, 12, colors.muted, "&H28&", 1)
    end
    local panel_background = layout.top_zone and state.hover_zone == "bottom"
        and colors.surface or colors.background
    local panel_radius = layout.dense and 10 or 14

    local panel_surface = shape(panel.x + 2, panel.y + 4, colors.background, "&H50&",
            rounded_rect_path(panel.width, panel.height, panel_radius))
        .. shape(panel.x - 1, panel.y - 1, colors.muted, "&H24&",
            rounded_rect_path(panel.width + 2, panel.height + 2, panel_radius + 1))
        .. shape(panel.x, panel.y, panel_background, "&H18&",
            rounded_rect_path(panel.width, panel.height, panel_radius))
        .. shape(inner_x, layout.divider_y, colors.muted, "&H24&",
            rect_path(panel.width - pad * 2, 1))

    -- Transport buttons: two flat navigation circles and a raised primary action.
    local transport_ass = ""
    if bottom_zone_visible then
        local nav = { transport.prev, transport.next }
        for _, button in ipairs(nav) do
            if button.width >= 8 then
            local radius = math.floor(button.height / 2)
            transport_ass = transport_ass
                .. shape(button.x, button.y, colors.surface, "&H24&", circle_path(button.height))
                .. outline(button.x, button.y, button.height, button.height, radius,
                    colors.muted, "&H24&", 1)
                .. shape(button.x, button.y, colors.text, "&H10&",
                    icon_path(button == transport.prev and "prev" or "next", button.height))
            end
        end
        local play = transport.play
        local play_radius = math.floor(play.height / 2)
        transport_ass = transport_ass
            .. shape(play.x, play.y, colors.accent, "&H20&",
                rounded_rect_path(play.width, play.height, play_radius))
            .. outline(play.x, play.y, play.width, play.height, play_radius,
                colors.accent, "&H28&", 1)
            .. shape(play.x + 12, play.y + math.floor((play.height - 24) / 2),
                colors.on_accent, "&H10&",
                icon_path(state.paused and "play" or "pause", 24))
    end

    -- Volume group: speaker glyph, rounded track, slider knob, and caption.
    local volume_ass = ""
    if bottom_zone_visible then
        local icon_y = volume.y + math.floor((control_h - 24) / 2)
        volume_ass = volume_ass
            .. shape(volume.x, icon_y, volume_label_color, "&H10&", icon_path("volume", 24))
        local track = volume.track
        volume_ass = volume_ass .. shape(track.x, track.y, colors.muted, "&H40&",
                rounded_rect_path(track.width, track.height, track.height / 2))
        if volume_fill > 0 then
            volume_ass = volume_ass .. shape(track.x, track.y, colors.accent, "&H10&",
                    rounded_rect_path(volume_fill, track.height, track.height / 2))
                .. shape(track.x + volume_fill - 6,
                    track.y + (track.height - 12) / 2,
                    colors.accent, "&H10&", circle_path(12))
        end
    end

    local ass = top_zone_ass .. panel_surface .. focus_ass .. transport_ass .. volume_ass
        .. string.format([[
{\an7\pos(%d,%d)\fnSans\fs%d\b1\1c%s}%s
{\an9\pos(%d,%d)\fnSans\fs13\b1\1c%s}%s
{\an8\pos(%d,%d)\fnSans\fs13\b1\1c%s}%s
{\an7\pos(%d,%d)\fnSans\fs16\b1\1c%s}%s
{\an7\pos(%d,%d)\fnSans\fs14\1c%s}%s
{\an7\pos(%d,%d)\bord0\shad0\1c%s\p1}%s{\p0}
{\an7\pos(%d,%d)\bord0\shad0\1c%s\p1}%s{\p0}
{\an7\pos(%d,%d)\fnSans\fs14\1c%s}%s
{\an7\pos(%d,%d)\fnSans\fs%d\b1\1c%s}%s
{\an7\pos(%d,%d)\fnSans\fs16\1c%s}%s
]],
        title_pos.x, title_pos.y, title_font_size, colors.text, title,
        status_pos.x + status_pos.width, status_pos.y + 2, colors.accent, status_text,
        preview_label_x or 0, preview_label_y or 0, colors.accent, preview_label,
        transport.play.x + 44, transport.play.y + math.floor((control_h - 16) / 2),
        colors.on_accent, playback_label,
        volume.x, volume.y + 2, volume_label_color, volume_label,
        timeline.x, timeline.y, colors.muted,
        rounded_rect_path(timeline.width, 6, 3),
        timeline.x, timeline.y, colors.accent,
        rounded_rect_path(filled, 6, 3),
        progress_label.x, progress_label.y, colors.muted, progress_text,
        time_label.x, time_label.y, time_label.font_size, colors.text, time_text,
        playlist.x, playlist.y, colors.text, playlist_label
    )

    if bottom_zone_visible and not timeline.minimal and filled > 0 then
        ass = ass .. shape(timeline.x + filled - 6, timeline.y - 3,
            colors.accent, "&H10&", circle_path(12))
    end

    local chapter_markers = {}
    local chapters = type(state.chapter_list) == "table" and state.chapter_list or {}
    if bottom_zone_visible and not timeline.minimal
        and is_finite_number(duration) and duration > 0 then
        local seen_markers = {}
        for _, chapter in ipairs(chapters) do
            local chapter_time = type(chapter) == "table" and chapter.time or nil
            if is_finite_number(chapter_time) and chapter_time > 0
                and chapter_time < duration then
                local marker_x = math.floor(timeline.x
                    + chapter_time / duration * timeline.width + 0.5)
                if marker_x > timeline.x and marker_x < timeline.x + timeline.width
                    and not seen_markers[marker_x] then
                    seen_markers[marker_x] = true
                    chapter_markers[#chapter_markers + 1] = string.format(
                        "{\\an7\\pos(%d,%d)\\bord0\\shad0\\1c%s\\p1}"
                            .. "m 0 0 l 2 0 2 8 0 8{\\p0}",
                        marker_x, timeline.y - 1, colors.accent)
                end
            end
        end
    end
    ass = ass .. table.concat(chapter_markers, "\\n")
    ass = ass .. render_menu_panel(state.library_menu or state.playlist_menu or state.recent_menu, width, height,
        colors, font_family, font_scale)

    if state.hover_target == "playback" or state.hover_target == "volume"
        or state.hover_target == "playlist" or state.hover_target == "timeline" then
        local target
        if state.hover_target == "playback" then target = playback
        elseif state.hover_target == "volume" then target = volume
        elseif state.hover_target == "playlist" then target = playlist
        else
            target = {
                x = timeline.x,
                y = timeline.y - 5,
                width = timeline.width,
                height = timeline.height + 10,
            }
        end
        ass = shape(target.x - 6, target.y - 5, colors.surface, "&H30&",
            rounded_rect_path(target.width + 12, target.height + 10, 10)) .. ass
    end

    local opacity = is_finite_number(state.opacity)
        and math.max(0, math.min(1, state.opacity)) or 1
    local fade_alpha = math.floor((1 - opacity) * 255 + 0.5)
    local panel_alpha = bottom_zone_visible and math.min(255, 24 + fade_alpha) or 255
    local top_panel_alpha = top_zone_visible and math.min(255, 24 + fade_alpha) or 255
    local hover_alpha = math.min(255, 48 + fade_alpha)
    local focus_alpha = math.min(255, 64 + fade_alpha)
    ass = ass:gsub("{\\", "{\\alpha&H" .. string.format("%02X", fade_alpha) .. "&\\")
    ass = ass:gsub("\\alpha&H18&", "\\alpha&H" .. string.format("%02X", panel_alpha) .. "&")
    ass = ass:gsub("\\alpha&H1A&", "\\alpha&H" .. string.format("%02X", top_panel_alpha) .. "&")
    ass = ass:gsub("\\alpha&H30&", "\\alpha&H" .. string.format("%02X", hover_alpha) .. "&")
    ass = ass:gsub("\\alpha&H40&", "\\alpha&H" .. string.format("%02X", focus_alpha) .. "&")

    if layout.compact then
        -- Keep text legible without letting labels dominate short windows.
        ass = ass:gsub("\\fs16", "\\fs13")
            :gsub("\\fs14", "\\fs12")
            :gsub("\\fs13", "\\fs11")
    end

    ass = ass:gsub("\\fnSans", function() return "\\fn" .. font_family end)
    ass = ass:gsub("\\fs(%d+)", function(size)
        return "\\fs" .. math.max(1, math.floor(tonumber(size) * font_scale + 0.5))
    end)

    local chapter_markers = {}
    local chapters = type(state.chapter_list) == "table" and state.chapter_list or {}
    if bottom_zone_visible and not timeline.minimal
        and is_finite_number(duration) and duration > 0 then
        local seen_markers = {}
        for _, chapter in ipairs(chapters) do
            local chapter_time = type(chapter) == "table" and chapter.time or nil
            if is_finite_number(chapter_time) and chapter_time > 0
                and chapter_time < duration then
                local marker_x = math.floor(timeline.x
                    + chapter_time / duration * timeline.width + 0.5)
                if marker_x > timeline.x and marker_x < timeline.x + timeline.width
                    and not seen_markers[marker_x] then
                    seen_markers[marker_x] = true
                    chapter_markers[#chapter_markers + 1] = string.format(
                        "{\\an7\\pos(%d,%d)\\bord0\\shad0\\1c%s\\p1}"
                            .. "m 0 0 l 2 0 2 8 0 8{\\p0}",
                        marker_x, timeline.y - 1, colors.accent)
                end
            end
        end
    end
    ass = ass .. table.concat(chapter_markers, "\\n")
    ass = ass .. render_menu_panel(state.library_menu or state.playlist_menu or state.recent_menu, width, height,
        colors, font_family, font_scale)

    if state.hover_target == "playback" or state.hover_target == "volume"
        or state.hover_target == "playlist" or state.hover_target == "timeline" then
        local target
        if state.hover_target == "playback" then target = playback
        elseif state.hover_target == "volume" then target = volume
        elseif state.hover_target == "playlist" then target = playlist
        else
            target = {
                x = timeline.x,
                y = timeline.y - 5,
                width = timeline.width,
                height = timeline.height + 10,
            }
        end
        local hover_bg = shape(target.x - 6, target.y - 5, colors.surface, "&H30&",
            rounded_rect_path(target.width + 12, target.height + 10, 10))
        ass = hover_bg .. ass
    end

    local opacity = is_finite_number(state.opacity)
        and math.max(0, math.min(1, state.opacity)) or 1
    local fade_alpha = math.floor((1 - opacity) * 255 + 0.5)
    local panel_alpha = bottom_zone_visible and math.min(255, 24 + fade_alpha) or 255
    local top_panel_alpha = top_zone_visible and math.min(255, 24 + fade_alpha) or 255
    local hover_alpha = math.min(255, 48 + fade_alpha)
    local focus_alpha = math.min(255, 64 + fade_alpha)
    ass = ass:gsub("{\\", "{\\alpha&H" .. string.format("%02X", fade_alpha) .. "&\\")
    ass = ass:gsub("\\alpha&H18&", "\\alpha&H" .. string.format("%02X", panel_alpha) .. "&")
    ass = ass:gsub("\\alpha&H1A&", "\\alpha&H" .. string.format("%02X", top_panel_alpha) .. "&")
    ass = ass:gsub("\\alpha&H30&", "\\alpha&H" .. string.format("%02X", hover_alpha) .. "&")
    ass = ass:gsub("\\alpha&H40&", "\\alpha&H" .. string.format("%02X", focus_alpha) .. "&")

    local size_key = width .. "x" .. height
    if self.last_data == ass and self.last_size == size_key then return end
    self.overlay.res_x = width
    self.overlay.res_y = height
    self.overlay.data = ass
    self.overlay:update()
    self.last_data = ass
    self.last_size = size_key
end

return Renderer
