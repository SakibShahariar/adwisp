-- Adwisp: GTK-inspired OSD prototype for mpv
-- Copyright (c) 2026 Adwisp contributors
-- Licensed under the MIT License. See LICENSE.

local mp = require "mp"
local options = require "mp.options"

-- Allow project-local modules to be loaded when this script is installed as a folder.
local script_dir = mp.get_script_directory()
package.path = script_dir .. "/?.lua;" .. script_dir .. "/?/init.lua;" .. package.path

local opts = {
    seek_step = 5,
    theme_file = "",
}
options.read_options(opts, "adwisp")

local state = require "core.state"
local Renderer = require "core.renderer"
local Layout = require "core.layout"
local Theme = require "core.theme"
local renderer = Renderer.new(mp, state)

local function render()
    renderer:render()
end

local function reload_theme()
    local palette, source, err = Theme.load(opts.theme_file)
    renderer:set_palette(palette)
    render()
    if source == "fallback" and err then
        mp.msg.warn("Adwisp: couldn't load theme_file; using fallback palette: " .. tostring(err))
    else
        mp.msg.info("Adwisp: theme reloaded (" .. source .. ").")
    end
end

reload_theme()

local function toggle()
    state.visible = not state.visible
    render()
end

local function seek(delta)
    mp.commandv("seek", delta, "relative", "keyframes")
end

local function handle_mouse_move()
    if not state.visible or type(mp.get_mouse_pos) ~= "function" then return end
    local mouse_x, mouse_y = mp.get_mouse_pos()
    if type(mouse_x) ~= "number" or type(mouse_y) ~= "number" then return end
    local width, height = mp.get_osd_size()
    local layout = Layout.compute(width, height)
    if not layout then return end

    local function contains(rect)
        return mouse_x >= rect.x and mouse_x <= rect.x + rect.width
            and mouse_y >= rect.y and mouse_y <= rect.y + rect.height
    end

    local hover_target
    if contains(layout.playback) then
        hover_target = "playback"
    elseif contains(layout.volume) then
        hover_target = "volume"
    end

    if state.hover_target ~= hover_target then
        state.hover_target = hover_target
        render()
    end
end

local function handle_mouse_click()
    if not state.visible or type(mp.get_mouse_pos) ~= "function" then return end

    local mouse_x, mouse_y = mp.get_mouse_pos()
    if type(mouse_x) ~= "number" or type(mouse_y) ~= "number" then return end

    local width, height = mp.get_osd_size()
    local layout = Layout.compute(width, height)
    if not layout then return end

    local timeline = layout.timeline
    if mouse_x >= timeline.hit_x and mouse_x <= timeline.hit_x + timeline.hit_width
        and mouse_y >= timeline.hit_y and mouse_y <= timeline.hit_y + timeline.hit_height then
        if state.duration > 0 then
            local fraction = math.max(0, math.min(1, (mouse_x - timeline.x) / timeline.width))
            mp.commandv("seek", fraction * 100, "absolute-percent")
        end
        return
    end

    local playback = layout.playback
    if mouse_x >= playback.x and mouse_x <= playback.x + playback.width
        and mouse_y >= playback.y and mouse_y <= playback.y + playback.height then
        mp.commandv("cycle", "pause")
        return
    end

    local volume = layout.volume
    if mouse_x >= volume.x and mouse_x <= volume.x + volume.width
        and mouse_y >= volume.y and mouse_y <= volume.y + volume.height then
        mp.commandv("cycle", "mute")
    end
end

-- Playback properties update the shared state and invalidate the renderer.
local observers = {
    { "pause", "bool", function(value) state.paused = value == true end },
    { "time-pos", "number", function(value) state.time_pos = value or 0 end },
    { "duration", "number", function(value) state.duration = value or 0 end },
    { "media-title", "string", function(value) state.title = value or "" end },
    { "volume", "number", function(value) state.volume = value or 100 end },
    { "mute", "bool", function(value) state.mute = value == true end },
}

for _, observer in ipairs(observers) do
    local property, property_type, apply = observer[1], observer[2], observer[3]
    mp.observe_property(property, property_type, function(_, value)
        apply(value)
        render()
    end)
end

mp.register_event("file-loaded", function()
    state.visible = true
    render()
end)

mp.register_event("end-file", function()
    state.visible = false
    render()
end)

mp.register_event("video-reconfig", render)
mp.observe_property("osd-dimensions", "native", render)

mp.add_key_binding("g", "adwisp-toggle", toggle)
mp.add_key_binding("LEFT", "adwisp-seek-back", function()
    seek(-tonumber(opts.seek_step or 5))
end)
mp.add_key_binding("RIGHT", "adwisp-seek-forward", function()
    seek(tonumber(opts.seek_step or 5))
end)
mp.add_key_binding("q", "adwisp-dismiss", function()
    state.visible = false
    render()
end)
mp.add_key_binding("SPACE", "adwisp-play-pause", function()
    mp.commandv("cycle", "pause")
end)
mp.add_key_binding("MBTN_LEFT", "adwisp-mouse-click", handle_mouse_click)
mp.add_key_binding("mouse_move", "adwisp-mouse-move", handle_mouse_move, { complex = true })

mp.register_script_message("adwisp-toggle", toggle)
mp.register_script_message("adwisp-show", function()
    state.visible = true
    render()
end)
mp.register_script_message("adwisp-hide", function()
    state.visible = false
    render()
end)
mp.register_script_message("adwisp-reload-theme", reload_theme)

mp.msg.info("Adwisp modular prototype loaded. Press g to toggle the OSD.")
