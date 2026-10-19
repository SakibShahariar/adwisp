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
    volume_step = 5,
    theme_file = "",
    thumbnail_preview = true,
}
options.read_options(opts, "adwisp")

local state = require "core.state"
local Renderer = require "core.renderer"
local Layout = require "core.layout"
local Theme = require "core.theme"
local utils = require "mp.utils"
local renderer = Renderer.new(mp, state)

-- thumbfast owns thumbnail generation and display. Adwisp only requests previews.
local thumbfast = { width = 0, height = 0, disabled = true, available = false }
local thumbnail_active = false
local dragging_volume = false
local dragging_timeline = false

local function clear_interaction_state()
    dragging_volume = false
    dragging_timeline = false
    state.hover_target = nil
end

local function clear_thumbnail()
    if thumbnail_active and thumbfast.available then
        mp.commandv("script-message-to", "thumbfast", "clear")
    end
    thumbnail_active = false
end

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
    if not state.visible then
        clear_interaction_state()
        clear_thumbnail()
    end
    render()
end

local function seek(delta)
    mp.commandv("seek", delta, "relative", "keyframes")
end

local function change_volume(delta)
    local current = tonumber(state.volume) or 100
    local step = math.max(1, tonumber(opts.volume_step) or 5)
    local volume = math.max(0, math.min(100, current + delta * step))
    state.volume = volume
    state.mute = false
    mp.commandv("set", "volume", volume)
    mp.commandv("set", "mute", "no")
end

local function set_volume_at(mouse_x, volume)
    if type(volume.width) ~= "number" or volume.width <= 0 then return end
    local fraction = math.max(0, math.min(1,
        (mouse_x - volume.x) / volume.width))
    local value = math.floor(fraction * 100 + 0.5)
    state.volume = value
    state.mute = false
    mp.commandv("set", "volume", value)
    mp.commandv("set", "mute", "no")
    render()
end

local function seek_at(mouse_x, timeline)
    if type(timeline.width) ~= "number" or timeline.width <= 0 then return end
    local fraction = math.max(0, math.min(1,
        (mouse_x - timeline.x) / timeline.width))
    mp.commandv("seek", fraction * 100, "absolute-percent")
end

local function handle_mouse_move()
    if not state.visible or type(mp.get_mouse_pos) ~= "function" then return end
    local mouse_x, mouse_y = mp.get_mouse_pos()
    if type(mouse_x) ~= "number" or type(mouse_y) ~= "number" then return end
    local width, height = mp.get_osd_size()
    local layout = Layout.compute(width, height)
    if not layout then return end

    if dragging_volume then
        set_volume_at(mouse_x, layout.volume)
    end
    if dragging_timeline then
        seek_at(mouse_x, layout.timeline)
    end

    local function contains(rect)
        return mouse_x >= rect.x and mouse_x <= rect.x + rect.width
            and mouse_y >= rect.y and mouse_y <= rect.y + rect.height
    end

    local hover_target
    if contains(layout.playback) then
        hover_target = "playback"
    elseif contains(layout.volume) then
        hover_target = "volume"
    elseif contains(layout.playlist) then
        hover_target = "playlist"
    elseif mouse_x >= layout.timeline.hit_x
        and mouse_x <= layout.timeline.hit_x + layout.timeline.hit_width
        and mouse_y >= layout.timeline.hit_y
        and mouse_y <= layout.timeline.hit_y + layout.timeline.hit_height then
        hover_target = "timeline"
    end

    local timeline = layout.timeline
    local on_timeline = opts.thumbnail_preview ~= false
        and mouse_x >= timeline.hit_x and mouse_x <= timeline.hit_x + timeline.hit_width
        and mouse_y >= timeline.hit_y and mouse_y <= timeline.hit_y + timeline.hit_height
    if on_timeline and not thumbfast.disabled and state.duration > 0
        and thumbfast.width > 0 and thumbfast.height > 0 then
        local fraction = math.max(0, math.min(1,
            (mouse_x - layout.timeline.x) / layout.timeline.width))
        local seconds = fraction * state.duration
        local osd_width = width
        local x = math.floor(math.max(8, math.min(
            osd_width - thumbfast.width - 8, mouse_x - thumbfast.width / 2)))
        local y = math.floor(math.max(0, layout.timeline.y - thumbfast.height - 12))
        mp.commandv("script-message-to", "thumbfast", "thumb", seconds, x, y)
        thumbnail_active = true
    else
        clear_thumbnail()
    end

    if state.hover_target ~= hover_target then
        state.hover_target = hover_target
        render()
    end
end

local function handle_mouse_click(event)
    if event and event.event == "up" then
        dragging_volume = false
        dragging_timeline = false
        return
    end
    if not state.visible or type(mp.get_mouse_pos) ~= "function" then return end

    local mouse_x, mouse_y = mp.get_mouse_pos()
    if type(mouse_x) ~= "number" or type(mouse_y) ~= "number" then return end

    local width, height = mp.get_osd_size()
    local layout = Layout.compute(width, height)
    if not layout then return end

    local volume = layout.volume
    if event and event.event == "down"
        and mouse_x >= volume.x and mouse_x <= volume.x + volume.width
        and mouse_y >= volume.y and mouse_y <= volume.y + volume.height then
        dragging_volume = true
        set_volume_at(mouse_x, volume)
        return
    end

    local timeline = layout.timeline
    if mouse_x >= timeline.hit_x and mouse_x <= timeline.hit_x + timeline.hit_width
        and mouse_y >= timeline.hit_y and mouse_y <= timeline.hit_y + timeline.hit_height then
        if state.duration > 0 then
            if event and event.event == "down" then
                dragging_timeline = true
            end
            seek_at(mouse_x, timeline)
        end
        return
    end

    local playback = layout.playback
    if mouse_x >= playback.x and mouse_x <= playback.x + playback.width
        and mouse_y >= playback.y and mouse_y <= playback.y + playback.height then
        mp.commandv("cycle", "pause")
        return
    end

    local playlist = layout.playlist
    if mouse_x >= playlist.x and mouse_x <= playlist.x + playlist.width
        and mouse_y >= playlist.y and mouse_y <= playlist.y + playlist.height then
        if mouse_x < playlist.x + playlist.width / 2 then
            mp.commandv("playlist-prev", "weak")
        else
            mp.commandv("playlist-next", "weak")
        end
        return
    end

    if mouse_x >= volume.x and mouse_x <= volume.x + volume.width
        and mouse_y >= volume.y and mouse_y <= volume.y + volume.height then
        set_volume_at(mouse_x, volume)
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
    clear_interaction_state()
    clear_thumbnail()
    state.visible = true
    render()
end)

mp.register_event("end-file", function()
    state.visible = false
    clear_interaction_state()
    clear_thumbnail()
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
    clear_interaction_state()
    clear_thumbnail()
    render()
end)
mp.add_key_binding("ESC", "adwisp-dismiss-escape", function()
    state.visible = false
    clear_interaction_state()
    clear_thumbnail()
    render()
end)
mp.add_key_binding("SPACE", "adwisp-play-pause", function()
    mp.commandv("cycle", "pause")
end)
mp.add_key_binding("m", "adwisp-mute-toggle", function()
    mp.commandv("cycle", "mute")
end)
mp.add_key_binding("CTRL+LEFT", "adwisp-playlist-prev", function()
    mp.commandv("playlist-prev", "weak")
end)
mp.add_key_binding("CTRL+RIGHT", "adwisp-playlist-next", function()
    mp.commandv("playlist-next", "weak")
end)
mp.add_key_binding("CTRL+UP", "adwisp-volume-up", function()
    change_volume(1)
end)
mp.add_key_binding("CTRL+DOWN", "adwisp-volume-down", function()
    change_volume(-1)
end)
mp.add_key_binding("MBTN_LEFT", "adwisp-mouse-click", handle_mouse_click, { complex = true })
mp.add_key_binding("mouse_move", "adwisp-mouse-move", handle_mouse_move, { complex = true })

mp.register_script_message("adwisp-toggle", toggle)
mp.register_script_message("adwisp-show", function()
    state.visible = true
    render()
end)
mp.register_script_message("adwisp-hide", function()
    state.visible = false
    clear_interaction_state()
    clear_thumbnail()
    render()
end)
mp.register_script_message("adwisp-reload-theme", reload_theme)
mp.register_script_message("thumbfast-info", function(json)
    local data = utils.parse_json(json)
    if type(data) == "table" and type(data.width) == "number"
        and type(data.height) == "number" then
        thumbfast = data
    else
        mp.msg.warn("Adwisp: received invalid thumbfast info; previews disabled.")
        thumbfast = { width = 0, height = 0, disabled = true, available = false }
    end
end)

mp.msg.info("Adwisp modular prototype loaded. Press g to toggle the OSD.")
