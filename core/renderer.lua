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

local function s(v)
    return math.floor((type(v) == "number" and v == v
        and v ~= math.huge and v ~= -math.huge and v or 0) + 0.5)
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
    elseif kind == "fullscreen" then
        return table.concat({
            box(0.08, 0.08, 0.36, 0.16), box(0.08, 0.08, 0.16, 0.36),
            box(0.64, 0.08, 0.92, 0.16), box(0.84, 0.08, 0.92, 0.36),
            box(0.08, 0.84, 0.36, 0.92), box(0.08, 0.64, 0.16, 0.92),
            box(0.64, 0.84, 0.92, 0.92), box(0.84, 0.64, 0.92, 0.92),
        }, " ")
    elseif kind == "settings" then
        return box(0.10, 0.24, 0.90, 0.32) .. " "
            .. box(0.10, 0.47, 0.90, 0.55) .. " "
            .. box(0.10, 0.70, 0.90, 0.78)
    elseif kind == "repeat" then
        return box(0.14, 0.30, 0.82, 0.70)
            .. string.format(" m %d %d l %d %d %d %d",
                c(0.82), c(0.30), c(0.66), c(0.20), c(0.66), c(0.40))
    elseif kind == "menu" then
        return box(0.10, 0.20, 0.90, 0.30) .. " "
            .. box(0.10, 0.45, 0.90, 0.55) .. " "
            .. box(0.10, 0.70, 0.90, 0.80)
    end
    return rect_path(size, size)
end

local function shape(x, y, color, alpha_marker, path)
    return string.format("{\\an7\\pos(%d,%d)\\bord0\\shad0\\1c%s\\alpha%s\\p1}%s{\\p0}\n",
        px(x), px(y), color, alpha_marker, path)
end

-- A deterministic ring: an outer border shape and an inner fill shape.
-- ASS/libass do not reliably honour 1a + 3c for drawing outlines, so nested
-- filled shapes are used instead.
local function ring(x, y, w, h, radius, border_color, border_alpha,
    fill_color, fill_alpha, stroke)
    local t = math.max(1, px(stroke or 2))
    return shape(x - t, y - t, border_color, border_alpha,
            rounded_rect_path(w + t * 2, h + t * 2, radius + t))
        .. shape(x, y, fill_color, fill_alpha,
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
    if type(value) ~= "string" then return "Adwaita Sans" end
    value = value:sub(1, 48):gsub("[^%w _%-]", "")
    value = value:match("^%s*(.-)%s*$")
    return value ~= "" and value or "Adwaita Sans"
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
    local title = lines[1]
    local rows = {}
    local footer = nil
    for index = 2, #lines do
        local line = lines[index]
        local hint = line:find("Up/Down") or line:find("Esc closes")
            or line:find("unavailable")
        if hint then
            footer = line
        else
            rows[#rows + 1] = line
        end
    end
    if #rows == 0 and footer then
        rows[1] = footer
        footer = nil
    end

    local header_h, row_h, footer_h = 34, 28, 24
    local panel_width = math.max(120, math.min(340, width - 24))
    local panel_height = header_h + #rows * row_h + (footer and footer_h or 0)
    local x = math.max(8, width - panel_width - 24)
    local y = math.max(12, math.floor(height * 0.12))
    if y + panel_height > height - 8 then y = math.max(8, height - panel_height - 8) end
    local font_size = math.max(9, math.min(15, math.floor(13 * font_scale + 0.5)))
    local max_chars = math.max(4, math.floor((panel_width - 52) / (font_size * 0.56)))

    local ass = ring(x, y, panel_width, panel_height, 12,
        colors.muted, "&H28&", colors.surface, "&H18&", 1)
        .. shape(x + 14, y + 10, colors.accent, "&H10&",
            rounded_rect_path(12, 12, 3))
        .. string.format("{\\an7\\pos(%d,%d)\\fn%s\\fs%d\\b1\\1c%s}%s\n",
            x + 36, y + 8, font_family, font_size, colors.text,
            escape_ass(truncate_title(title, max_chars)))
        .. string.format("{\\an7\\pos(%d,%d)\\fn%s\\fs%d\\1c%s}x\n",
            x + panel_width - 22, y + 8, font_family, font_size, colors.muted)
        .. shape(x + 12, y + header_h - 2, colors.muted, "&H30&",
            rect_path(panel_width - 24, 1))

    for index, line in ipairs(rows) do
        local line_y = y + header_h + 6 + (index - 1) * row_h
        local selected = menu.selected_line == index
        if selected then
            ass = ass .. shape(x + 8, line_y - 4, colors.accent, "&H28&",
                rounded_rect_path(panel_width - 16, row_h - 2, 6))
        end
        local mark = line:match("^([>%*])")
        local text = line:gsub("^[>%*]%s*", "")
        local color = selected and colors.on_accent
            or (mark and colors.accent or colors.text)
        ass = ass .. string.format("{\\an7\\pos(%d,%d)\\fn%s\\fs%d\\b%d\\1c%s}%s\n",
            x + 20, line_y, font_family, font_size, selected and 1 or 0,
            color, escape_ass(truncate_title(text, max_chars)))
    end

    if footer then
        ass = ass .. shape(x + 12, y + panel_height - footer_h + 4,
            colors.muted, "&H30&", rect_path(panel_width - 24, 1))
            .. string.format("{\\an7\\pos(%d,%d)\\fn%s\\fs%d\\1c%s}%s\n",
                x + 20, y + panel_height - footer_h + 8,
                font_family, math.max(8, font_size - 2), colors.muted,
                escape_ass(truncate_title(footer, max_chars + 8)))
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
    if not state.visible then self:clear(); return end
    local width, height = self.mp.get_osd_size()
    if not width or not height or width <= 0 or height <= 0 then return end

    local time_pos = is_finite_number(state.time_pos) and state.time_pos or 0
    local duration = is_finite_number(state.duration) and state.duration or 0
    local volume_value = is_finite_number(state.volume) and state.volume or 0
    volume_value = math.max(0, math.min(100, volume_value))
    local progress = duration > 0 and math.max(0, math.min(1, time_pos / duration)) or 0

    local options = type(state.layout_options) == "table" and state.layout_options or {}
    options.ui_scale = state.ui_scale or options.ui_scale
    options.fullscreen = state.fullscreen == true
    local layout = Layout.compute(width, height, options)
    if not layout then return end
    local panel = layout.panel
    local scale = layout.scale
    local font_scale = is_finite_number(options.font_scale) and options.font_scale or 1
    font_scale = math.max(0.75, math.min(1.25, font_scale))
    local colors = Theme.to_ass(state.palette)
    local font_family = safe_font_family(options.font_family)

    local osd = {}
    local function px(v) return math.floor(v + 0.5) end
    local function txt(x, y, align, size, color, value, bold)
        osd[#osd + 1] = string.format("{\\an%d\\pos(%d,%d)\\fn%s\\fs%d\\b%d\\1c%s}%s",
            align or 4, px(x), px(y), font_family, math.max(1, px(size * font_scale)),
            bold and 1 or 0, color, escape_ass(tostring(value or "")))
    end
    local function inset(base) return px(base * scale) end

    -- Title bar
    if not state.fullscreen then
        local tb = layout.title_bar
        osd[#osd + 1] = shape(tb.x, tb.y, colors.background, "&H18&",
            rect_path(tb.width, tb.height))
        local hb = layout.hamburger
        osd[#osd + 1] = shape(hb.x, hb.y + inset(4), colors.text, "&H10&",
            icon_path("menu", hb.height - inset(8)))
        txt(tb.x + tb.width / 2, tb.y + tb.height / 2 - inset(10), 5,
            20 * scale, colors.text, "mpv", true)
        -- Window controls: minimize bar, hollow maximize square, accent close button with X.
        local wc = layout.window_controls
        local btn = inset(20)
        local gap = inset(6)
        local cy = wc.y + btn / 2
        osd[#osd + 1] = shape(wc.x, cy - inset(1), colors.text, "&H10&",
            rect_path(btn, inset(2)))
        local max_x = wc.x + btn + gap
        osd[#osd + 1] = ring(max_x, wc.y, btn, btn, inset(1),
            colors.text, "&H10&", colors.background, "&H00&", inset(1))
        local close_x = max_x + btn + gap
        osd[#osd + 1] = shape(close_x, wc.y, colors.accent, "&H10&",
            rounded_rect_path(btn, btn, inset(4)))
        local m = inset(5)
        local d = btn - m * 2
        osd[#osd + 1] = string.format(
            "{\\an7\\pos(%d,%d)\\bord%d\\shad0\\1a&HFE&\\3c%s\\p1}"
                .. "m 0 0 l %d %d m %d 0 l 0 %d{\\p0}",
            close_x + m, wc.y + m, inset(2), colors.on_accent, d, d, d, d)
    end

    -- Scrim: 0x00 opaque, 0xFF transparent. Top ~31% opaque, bottom ~96%.
    local bands = 12
    for i = 1, bands do
        local alpha = px(0x10 - (i - 1) * (0x10 - 0x04) / (bands - 1))
        local y0 = panel.y + math.floor((i - 1) * panel.height / bands)
        local y1 = panel.y + math.floor(i * panel.height / bands)
        osd[#osd + 1] = shape(0, y0, colors.background,
            string.format("&H%02X&", alpha), rect_path(panel.width, math.max(1, y1 - y0 + 1)))
    end

    -- Media row
    local thumb = layout.thumbnail
    osd[#osd + 1] = shape(thumb.x, thumb.y, colors.surface, "&H20&",
        rounded_rect_path(thumb.width, thumb.height, inset(5)))
    osd[#osd + 1] = shape(thumb.x + inset(10), thumb.y + inset(10), colors.accent, "&H20&",
        circle_path(thumb.width - inset(20)))
    local title_text = state.title ~= "" and state.title or "Adwisp"
    local title_chars = math.max(4, math.floor(layout.title.width / (13 * scale * 0.56)))
    txt(layout.title.x, layout.title.y, 4, 18 * scale, colors.text,
        truncate_title(title_text, title_chars))
    txt(layout.media_actions.x, layout.media_actions.y, 6, 13 * scale, colors.muted, "⛶  ⋯")

    -- Timeline
    local tl = layout.timeline
    local filled = px(tl.width * progress)
    osd[#osd + 1] = shape(tl.x, tl.y, colors.muted, "&H50&",
        rounded_rect_path(tl.width, tl.height, tl.height / 2))
    if filled > 0 then
        osd[#osd + 1] = shape(tl.x, tl.y, colors.accent, "&H10&",
            rounded_rect_path(filled, tl.height, tl.height / 2))
        osd[#osd + 1] = shape(tl.x + filled - inset(6), tl.y - inset(3),
            colors.accent, "&H10&", circle_path(inset(12)))
    end

    -- Chapter markers
    if (options.timeline_expanded == true or options.minimal_timeline ~= true)
        and is_finite_number(duration) and duration > 0 then
        local chapters = type(state.chapter_list) == "table" and state.chapter_list or {}
        local seen = {}
        for _, c in ipairs(chapters) do
            local ct = type(c) == "table" and c.time or nil
            if is_finite_number(ct) and ct > 0 and ct < duration then
                local mx = px(tl.x + ct / duration * tl.width)
                if mx > tl.x and mx < tl.x + tl.width and not seen[mx] then
                    seen[mx] = true
                    osd[#osd + 1] = string.format(
                        "{\\an7\\pos(%d,%d)\\bord0\\shad0\\1c%s\\p1}"
                            .. "m 4 0 l 8 4 4 8 0 4{\\p0}",
                        mx - 4, tl.y - 4, colors.accent)
                end
            end
        end
    end

    -- Transport
    local tr = layout.transport
    for _, rect in ipairs({tr.repeat_left, tr.prev, tr.next, tr.repeat_right}) do
        -- Raised circular icon button: surface fill + subtle outline.
        osd[#osd + 1] = ring(rect.x, rect.y, rect.width, rect.height,
            rect.width / 2, colors.muted, "&H28&", colors.surface, "&H24&", 1)
    end
    local function glyph(rect, kind)
        osd[#osd + 1] = shape(rect.x + inset(6), rect.y + inset(6),
            colors.text, "&H10&", icon_path(kind, rect.width - inset(12)))
    end
    glyph(tr.repeat_left, "repeat"); glyph(tr.prev, "prev")
    glyph(tr.next, "next"); glyph(tr.repeat_right, "repeat")
    local play = tr.play
    osd[#osd + 1] = shape(play.x, play.y, colors.accent, "&H10&", circle_path(play.width))
    osd[#osd + 1] = shape(play.x + inset(16), play.y + inset(16), colors.on_accent, "&H10&",
        icon_path(state.paused and "play" or "pause", play.width - inset(32)))

    -- Volume
    local v = layout.volume
    local track = v.track
    local vfill = px(track.width * volume_value / 100)
    osd[#osd + 1] = shape(v.x, layout.time_label.y, colors.text, "&H30&",
        icon_path("volume", inset(18)))
    osd[#osd + 1] = shape(track.x, track.y, colors.muted, "&H40&",
        rounded_rect_path(track.width, track.height, track.height / 2))
    if vfill > 0 then
        osd[#osd + 1] = shape(track.x, track.y, colors.accent, "&H10&",
            rounded_rect_path(vfill, track.height, track.height / 2))
        osd[#osd + 1] = shape(track.x + vfill - inset(5), track.y - inset(3),
            colors.accent, "&H10&", circle_path(inset(10)))
    end

    -- Right utilities
    osd[#osd + 1] = shape(layout.fullscreen.x, layout.fullscreen.y, colors.text, "&H30&",
        icon_path("fullscreen", layout.fullscreen.width))
    osd[#osd + 1] = shape(layout.settings.x, layout.settings.y, colors.text, "&H30&",
        icon_path("settings", layout.settings.width))

    -- Time and secondary labels
    if layout.time_label.visible then
        local now, total = fmt_time(state.time_pos), fmt_time(state.duration)
        txt(layout.time_label.x, layout.time_label.y, 4, 17 * scale, colors.text,
            now .. " / " .. total)
    end
    if width >= 640 and layout.progress_label.visible then
        txt(layout.time_label.x + inset(150), layout.time_label.y, 4, 12 * scale,
            colors.muted, string.format("%d%%", px(progress * 100)))
    end
    local speed = is_finite_number(state.speed)
        and math.max(0.01, math.min(100, state.speed)) or 1
    local action = translate(state, state.paused and "play" or "pause",
        state.paused and "Play" or "Pause")
    -- Playback action/speed beside the time label.
    txt(layout.time_label.x + inset(240), layout.time_label.y, 4, 11 * scale,
        colors.muted, action .. "  " .. string.format("%.2g×", speed))
    local volume_text = state.mute and translate(state, "muted", "Muted")
        or (volume_value <= 20 and translate_format(state, "low_volume",
            "Low volume %d%%", px(volume_value))
            or translate_format(state, "volume", "Volume %d%%", px(volume_value)))
    txt(v.x, panel.y + inset(48), 4, 12 * scale,
        (state.mute or volume_value <= 20) and colors.accent or colors.muted, volume_text)

    local status = {}
    if state.buffering == true then
        status[#status + 1] = width >= 640 and
            ("Buffering " .. px(is_finite_number(state.buffering_progress)
                and state.buffering_progress or 0) .. "%") or "Buffering"
    end
    if type(state.chapter_title) == "string" and state.chapter_title ~= "" then
        status[#status + 1] = translate_format(state, "chapter_status", "Chapter: %s",
            truncate_title(state.chapter_title, 14))
    end
    if (tonumber(state.audio_track_count) or 0) > 0 then
        status[#status + 1] = translate_format(state, "audio_status", "A: %s",
            truncate_title(type(state.audio_track_label) == "string"
                and state.audio_track_label or "—", 10))
    end
    if (tonumber(state.subtitle_track_count) or 0) > 0 then
        local sub = type(state.subtitle_track_label) == "string"
            and state.subtitle_track_label or "Off"
        if sub == "Off" then sub = translate(state, "off", "Off") end
        status[#status + 1] = translate_format(state, "subtitle_status", "S: %s",
            truncate_title(sub, 10))
    end
    local lf = state.loop_file
    if lf == "inf" or (is_finite_number(tonumber(lf)) and tonumber(lf) > 0) then
        status[#status + 1] = "Loop"
    end
    local la, lb = state.ab_loop_a or -1, state.ab_loop_b or -1
    if is_finite_number(la) and is_finite_number(lb) then
        if la >= 0 and lb >= 0 then status[#status + 1] = "A–B"
        elseif la >= 0 then status[#status + 1] = "A"
        elseif lb >= 0 then status[#status + 1] = "B" end
    end
    if state.image_mode == true then status[#status + 1] = "Image" end
    if #status > 0 then
        txt(layout.title.x, panel.y + inset(48), 4, 12 * scale, colors.accent,
            table.concat(status, " · "))
    end

    local pc = is_finite_number(state.playlist_count)
        and math.max(0, math.floor(state.playlist_count)) or 0
    if pc >= 2 and is_finite_number(state.playlist_pos) then
        local pos = math.floor(state.playlist_pos)
        if pos >= 0 and pos < pc then
            txt(layout.time_label.x + inset(300), layout.time_label.y, 4, 12 * scale,
                colors.muted,
                "‹  Previous  " .. (pos + 1) .. " / " .. pc .. "  Next  ›")
        end
    end

    -- Thumbfast preview pill (own positioned label)
    if state.preview_visible == true and is_finite_number(state.preview_time) then
        local pxv = is_finite_number(state.preview_x) and state.preview_x or width / 2
        local pyv = is_finite_number(state.preview_y) and state.preview_y or 0
        local pill_w, pill_h = inset(70), inset(24)
        local px0 = math.max(inset(4), math.min(width - pill_w - inset(4), pxv - pill_w / 2))
        local py0 = math.max(inset(4), pyv - inset(30))
        osd[#osd + 1] = ring(px0, py0, pill_w, pill_h, inset(6),
            colors.accent, "&H28&", colors.surface, "&H18&", 1)
        osd[#osd + 1] = string.format(
            "{\\an8\\pos(%d,%d)\\fn%s\\fs%d\\1c%s}",
            px(px0 + pill_w / 2), px(py0), font_family,
            math.max(1, px(12 * scale * font_scale)), colors.text)
            .. fmt_time(state.preview_time)
    end

    -- Notification toast
    if type(state.notification) == "table" and state.notification.text
        and state.notification.text ~= "" then
        local tw = math.min(inset(360), width - inset(32))
        local tx, ty = px((width - tw) / 2), inset(16)
        osd[#osd + 1] = ring(tx, ty, tw, inset(38), inset(10),
            colors.muted, "&H28&", colors.surface, "&H18&", 1)
        osd[#osd + 1] = shape(tx + inset(12), ty + inset(11), colors.accent, "&H10&",
            circle_path(inset(16)))
        txt(tx + inset(46), ty + inset(10), 4, 13 * scale, colors.text,
            truncate_title(state.notification.text, 48))
    end

    -- Menus
    if type(render_menu_panel) == "function" then
        local menu = state.library_menu or state.playlist_menu or state.recent_menu
        if menu then
            osd[#osd + 1] = render_menu_panel(menu, width, height, colors,
                font_family, font_scale)
        end
    end

    local fade = px((1 - (is_finite_number(state.opacity)
        and math.max(0, math.min(1, state.opacity)) or 1)) * 255)
    if fade > 0 then
        for i, line in ipairs(osd) do
            osd[i] = line:gsub("{\\", "{\\alpha&H" .. string.format("%02X", fade) .. "&\\", 1)
        end
    end

    local data = table.concat(osd, "\n")
    local size_key = width .. "x" .. height
    if self.last_data == data and self.last_size == size_key then return end
    self.overlay.res_x = width
    self.overlay.res_y = height
    self.overlay.data = data
    self.overlay:update()
    self.last_data = data
    self.last_size = size_key
end

return Renderer
