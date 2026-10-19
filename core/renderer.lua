-- Adwisp renderer: ASS OSD drawing only.
-- Copyright (c) 2026 Adwisp contributors
-- MIT License. See LICENSE.

local Layout = require "core.layout"
local Theme = require "core.theme"

local Renderer = {}
Renderer.__index = Renderer

local function escape_ass(value)
    return tostring(value or "")
        :gsub("\\", "\\\\")
        :gsub("{", "\\{")
        :gsub("}", "\\}")
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

local function fmt_time(seconds)
    if type(seconds) ~= "number" or seconds < 0 then return "--:--" end
    seconds = math.floor(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    if hours > 0 then return string.format("%d:%02d:%02d", hours, minutes, secs) end
    return string.format("%d:%02d", minutes, secs)
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

    local now = fmt_time(state.time_pos)
    local total = fmt_time(state.duration)
    local progress = 0
    if state.duration > 0 then
        progress = math.max(0, math.min(1, state.time_pos / state.duration))
    end

    local layout = Layout.compute(width, height)
    if not layout then return end
    local panel = layout.panel
    local title_pos = layout.title
    local title_font_size = layout.compact and 18 or 22
    local title_chars = math.max(8, math.floor(title_pos.width / (title_font_size * 0.56)))
    local title = escape_ass(truncate_title(
        state.title ~= "" and state.title or "Adwisp", title_chars
    ))
    local playback = layout.playback
    local volume = layout.volume
    local timeline = layout.timeline
    local progress_label = layout.progress_label
    local time_label = layout.time_label
    local playlist = layout.playlist
    local filled = math.floor(timeline.width * progress)
    local pause_label = state.paused and "Play" or "Pause"
    local volume_label = state.mute and "Muted" or string.format("Volume %d%%", math.floor(state.volume + 0.5))

    local ass = string.format([[
{\an7\pos(%d,%d)\bord0\shad0\1c&H30251E&\alpha&H18&\p1}m 0 0 l %d 0 %d %d 0 %d{\p0}
{\an7\pos(%d,%d)\fnSans\fs22\b1\1c&HFAF7F3&}%s
{\an7\pos(%d,%d)\fnSans\fs14\1c&HDBD2C8&}%s
{\an7\pos(%d,%d)\fnSans\fs14\1c&HDBD2C8&}%s
{\an7\pos(%d,%d)\bord0\shad0\1c&H6D6259&\p1}m 0 0 l %d 0 %d 6 0 6{\p0}
{\an7\pos(%d,%d)\bord0\shad0\1c&H9B7653&\p1}m 0 0 l %d 0 %d 6 0 6{\p0}
{\an7\pos(%d,%d)\fnSans\fs13\1c&HDBD2C8&}%s
{\an7\pos(%d,%d)\fnSans\fs15\b1\1c&HFAF7F3&}%s
{\an7\pos(%d,%d)\fnSans\fs15\1c&HFAF7F3&}%s
]],
        panel.x, panel.y, panel.width, panel.width, panel.height, panel.height,
        title_pos.x, title_pos.y, title,
        playback.x, playback.y, pause_label,
        volume.x, volume.y, volume_label,
        timeline.x, timeline.y, timeline.width, timeline.width,
        timeline.x, timeline.y, filled, filled,
        progress_label.x, progress_label.y, string.format("%d%%", math.floor(progress * 100 + 0.5)),
        time_label.x, time_label.y, now .. " / " .. total,
        playlist.x, playlist.y, "‹    Previous       Next    ›"
    )

    if layout.compact then
        -- Keep text legible without letting labels dominate short windows.
        ass = ass:gsub("\\fs22", "\\fs18")
            :gsub("\\fs14", "\\fs12")
            :gsub("\\fs13", "\\fs11")
            :gsub("\\fs15", "\\fs12")
    end

    local volume_fraction = math.max(0, math.min(1, (state.volume or 0) / 100))
    local volume_fill = math.floor(volume.width * volume_fraction)
    local volume_track = string.format([[
{\an7\pos(%d,%d)\bord0\shad0\1c&H6D6259&\p1}m 0 0 l %d 0 %d 4 0 4{\p0}
{\an7\pos(%d,%d)\bord0\shad0\1c&H9B7653&\p1}m 0 0 l %d 0 %d 4 0 4{\p0}
]], volume.x, volume.y + 25, volume.width, volume.width,
        volume.x, volume.y + 25, volume_fill, volume_fill)
    ass = ass .. volume_track

    local colors = Theme.to_ass(state.palette)
    ass = ass:gsub("&H30251E&", colors.background)
        :gsub("&HFAF7F3&", colors.text)
        :gsub("&HDBD2C8&", colors.muted)
        :gsub("&H6D6259&", colors.muted)
        :gsub("&H9B7653&", colors.accent)

    if state.hover_target == "playback" or state.hover_target == "volume" then
        local target = state.hover_target == "playback" and playback or volume
        local hover_bg = string.format(
            "{\\an7\\pos(%d,%d)\\bord0\\shad0\\1c%s\\alpha&H30&\\p1}"
                .. "m 0 0 l %d 0 %d %d 0 %d{\\p0}\\n",
            target.x - 6, target.y - 5, colors.surface,
            target.width + 12, target.width + 12,
            target.height + 10, target.height + 10
        )
        ass = hover_bg .. ass
    end

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
