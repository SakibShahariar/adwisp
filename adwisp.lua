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
    auto_hide_seconds = 0,
    palette_file = "~/.config/mpv/adwisp-palette.conf",
}
options.read_options(opts, "adwisp")

local state = require "core.state"
local Renderer = require "core.renderer"
local renderer = Renderer.new(mp, state)

local function render()
    renderer:render()
end

local function toggle()
    state.visible = not state.visible
    render()
end

local function seek(delta)
    mp.commandv("seek", delta, "relative", "keyframes")
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

mp.register_script_message("adwisp-toggle", toggle)
mp.register_script_message("adwisp-show", function()
    state.visible = true
    render()
end)
mp.register_script_message("adwisp-hide", function()
    state.visible = false
    render()
end)

mp.msg.info("Adwisp modular prototype loaded. Press g to toggle the OSD.")
