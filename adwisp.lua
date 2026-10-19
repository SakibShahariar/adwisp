-- Adwisp: GTK-inspired OSD prototype for mpv
-- Copyright (c) 2026 Adwisp contributors
-- Licensed under the MIT License. See LICENSE.
--
-- This is an early scaffold. It uses mpv's ASS OSD overlay; it is not a GTK
-- application and does not yet implement the complete Adwisp UI.

local mp = require "mp"
local options = require "mp.options"

local opts = {
    seek_step = 5,
    auto_hide_seconds = 0,
    palette_file = "~/.config/mpv/adwisp-palette.conf",
}
options.read_options(opts, "adwisp")

local state = {
    visible = false,
    paused = false,
    time_pos = 0,
    duration = 0,
    title = "",
    volume = 100,
    mute = false,
}

local overlay = mp.create_osd_overlay("ass-events")
overlay.z = 20

local function escape_ass(value)
    value = tostring(value or "")
    value = value:gsub("\\", "\\\\")
                 :gsub("{", "\\{")
                 :gsub("}", "\\}")
                 :gsub("\n", " ")
    return value
end

local function fmt_time(seconds)
    if type(seconds) ~= "number" or seconds < 0 then
        return "--:--"
    end
    seconds = math.floor(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    if hours > 0 then
        return string.format("%d:%02d:%02d", hours, minutes, secs)
    end
    return string.format("%d:%02d", minutes, secs)
end

local function render()
    if not state.visible then
        overlay.data = ""
        overlay:update()
        return
    end

    local width, height = mp.get_osd_size()
    if not width or not height or width <= 0 or height <= 0 then
        return
    end

    local title = escape_ass(state.title ~= "" and state.title or "Adwisp")
    local now = fmt_time(state.time_pos)
    local total = fmt_time(state.duration)
    local progress = 0
    if state.duration > 0 then
        progress = math.max(0, math.min(1, state.time_pos / state.duration))
    end

    local bar_width = math.floor(math.min(520, width * 0.62))
    local filled = math.floor(bar_width * progress)
    local percent = math.floor(progress * 100 + 0.5)
    local pause_label = state.paused and "▶  Play" or "Ⅱ  Pause"
    local volume_label = state.mute and "Muted" or string.format("Volume %d%%", math.floor(state.volume + 0.5))

    -- ASS coordinates are scaled to the current OSD resolution.
    local ass = string.format([[
        {\an7\pos(%d,%d)\bord0\shad0\1c&H30251E&\alpha&H18&\p1}m 0 0 l %d 0 %d 150 0 150{\p0}
        {\an7\pos(%d,%d)\fnSans\fs22\b1\1c&HFAF7F3&}%s
        {\an7\pos(%d,%d)\fnSans\fs14\b0\1c&HDBD2C8&}%s
        {\an7\pos(%d,%d)\fnSans\fs16\1c&HFAF7F3&}%s     %s
        {\an7\pos(%d,%d)\bord0\shad0\1c&H6D6259&\p1}m 0 0 l %d 0 0 5 m 0 -2 l %d -2 0 3{\p0}
        {\an7\pos(%d,%d)\bord0\shad0\1c&H9B7653&\p1}m 0 0 l %d 0 0 5 m 0 -2 l %d -2 0 3{\p0}
        {\an7\pos(%d,%d)\fnSans\fs13\1c&HDBD2C8&}%s
        {\an7\pos(%d,%d)\fnSans\fs15\b1\1c&HFAF7F3&}‹     %s     ›
    ]],
        math.floor((width - bar_width - 56) / 2), height - 190,
        bar_width + 56, bar_width + 56,
        math.floor((width - bar_width - 56) / 2) + 24, height - 174, title,
        math.floor((width - bar_width - 56) / 2) + 24, height - 144, pause_label,
        math.floor((width - bar_width - 56) / 2) + 140, height - 144, volume_label, now .. " / " .. total,
        math.floor((width - bar_width) / 2), height - 94, bar_width, bar_width,
        math.floor((width - bar_width) / 2), height - 94, filled, filled,
        math.floor((width - bar_width) / 2), height - 72, string.format("%d%%", percent),
        math.floor((width - bar_width - 56) / 2) + 24, height - 48, state.paused and "Play" or "Pause"
    )

    overlay.res_x = width
    overlay.res_y = height
    overlay.data = ass
    overlay:update()
end

local function toggle()
    state.visible = not state.visible
    render()
end

local function seek(delta)
    mp.commandv("seek", delta, "relative", "keyframes")
end

mp.observe_property("pause", "bool", function(_, value)
    state.paused = value == true
    render()
end)
mp.observe_property("time-pos", "number", function(_, value)
    state.time_pos = value or 0
    render()
end)
mp.observe_property("duration", "number", function(_, value)
    state.duration = value or 0
    render()
end)
mp.observe_property("media-title", "string", function(_, value)
    state.title = value or ""
    render()
end)
mp.observe_property("volume", "number", function(_, value)
    state.volume = value or 100
    render()
end)
mp.observe_property("mute", "bool", function(_, value)
    state.mute = value == true
    render()
end)

mp.register_event("file-loaded", function()
    state.visible = true
    render()
end)
mp.register_event("end-file", function()
    state.visible = false
    render()
end)
mp.register_event("video-reconfig", render)

mp.add_key_binding("g", "adwisp-toggle", toggle)
mp.add_key_binding("LEFT", "adwisp-seek-back", function() seek(-tonumber(opts.seek_step or 5)) end)
mp.add_key_binding("RIGHT", "adwisp-seek-forward", function() seek(tonumber(opts.seek_step or 5)) end)
mp.add_key_binding("q", "adwisp-dismiss", function()
    state.visible = false
    render()
end)
mp.add_key_binding("SPACE", "adwisp-play-pause", function()
    mp.commandv("cycle", "pause")
end)

mp.register_script_message("adwisp-toggle", toggle)
mp.register_script_message("adwisp-show", function()
    state.visible = true
    render()
end)
mp.register_script_message("adwisp-hide", function()
    state.visible = false
    render()
end)

mp.msg.info("Adwisp prototype loaded. Press g to toggle the OSD.")
