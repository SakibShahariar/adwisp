-- Adwisp renderer: ASS OSD drawing only.
-- Copyright (c) 2026 Adwisp contributors
-- MIT License. See LICENSE.

local Renderer = {}
Renderer.__index = Renderer

local function escape_ass(value)
    return tostring(value or "")
        :gsub("\\", "\\\\")
        :gsub("{", "\\{")
        :gsub("}", "\\}")
        :gsub("\n", " ")
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

    local title = escape_ass(state.title ~= "" and state.title or "Adwisp")
    local now = fmt_time(state.time_pos)
    local total = fmt_time(state.duration)
    local progress = 0
    if state.duration > 0 then
        progress = math.max(0, math.min(1, state.time_pos / state.duration))
    end

    local panel_width = math.floor(math.min(560, width * 0.72))
    local panel_height = 156
    local x = math.floor((width - panel_width) / 2)
    local y = math.max(16, height - panel_height - 42)
    local inner_x = x + 22
    local bar_x = x + 22
    local bar_y = y + 104
    local bar_width = panel_width - 44
    local filled = math.floor(bar_width * progress)
    local pause_label = state.paused and "Play" or "Pause"
    local volume_label = state.mute and "Muted" or string.format("Volume %d%%", math.floor(state.volume + 0.5))

    local ass = string.format([[
{\\an7\\pos(%d,%d)\\bord0\\shad0\\1c&H30251E&\\alpha&H18&\\p1}m 0 0 l %d 0 %d %d 0 %d{\\p0}
{\\an7\\pos(%d,%d)\\fnSans\\fs22\\b1\\1c&HFAF7F3&}%s
{\\an7\\pos(%d,%d)\\fnSans\\fs14\\1c&HDBD2C8&}%s
{\\an7\\pos(%d,%d)\\fnSans\\fs14\\1c&HDBD2C8&}%s
{\\an7\\pos(%d,%d)\\bord0\\shad0\\1c&H6D6259&\\p1}m 0 0 l %d 0 %d 6 0 6{\\p0}
{\\an7\\pos(%d,%d)\\bord0\\shad0\\1c&H9B7653&\\p1}m 0 0 l %d 0 0 6{\\p0}
{\\an7\\pos(%d,%d)\\fnSans\\fs13\\1c&HDBD2C8&}%s
{\\an7\\pos(%d,%d)\\fnSans\\fs15\\b1\\1c&HFAF7F3&}%s
{\\an7\\pos(%d,%d)\\fnSans\\fs15\\1c&HFAF7F3&}%s
]],
        x, y, panel_width, panel_width, panel_height, panel_height,
        inner_x, y + 18, title,
        inner_x, y + 51, pause_label,
        inner_x + 112, y + 51, volume_label,
        bar_x, bar_y, bar_width, bar_x, bar_y, filled,
        bar_x, bar_y + 22, string.format("%d%%", math.floor(progress * 100 + 0.5)),
        bar_x + bar_width - 100, bar_y + 22, now .. " / " .. total,
        inner_x, y + 132, "‹    Previous       Next    ›"
    )

    if self.last_data == ass and self.last_size == (width .. "x" .. height) then return end
    self.overlay.res_x = width
    self.overlay.res_y = height
    self.overlay.data = ass
    self.overlay:update()
    self.last_data = ass
    self.last_size = width .. "x" .. height
end

return Renderer
