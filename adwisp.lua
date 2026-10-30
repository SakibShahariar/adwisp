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
    time_pos_render_interval = 0.15,
    osd_position = "bottom",
    osd_margin = -1,
    osd_custom_offset = 120,
    log_level = "info",
}
options.read_options(opts, "adwisp")
if opts.log_level ~= "quiet" and opts.log_level ~= "debug" then
    opts.log_level = "info"
end

local state = require "core.state"
state.layout_options = opts
local Renderer = require "core.renderer"
local Layout = require "core.layout"
local Theme = require "core.theme"
local utils = require "mp.utils"
local renderer = Renderer.new(mp, state)

local function log_info(message)
    if opts.log_level ~= "quiet" then
        mp.msg.info("Adwisp: " .. message)
    end
end

local function log_debug(message)
    if opts.log_level == "debug" then
        mp.msg.info("Adwisp [debug]: " .. message)
    end
end

-- thumbfast owns thumbnail generation and display. Adwisp only requests previews.
local thumbfast = { width = 0, height = 0, disabled = true, available = false }
local thumbnail_active = false
local last_thumbnail_request = nil
local cached_layout = nil
local cached_layout_width, cached_layout_height
local cached_layout_position, cached_layout_margin, cached_layout_custom_offset
local active_drag = nil

local function clear_interaction_state()
    active_drag = nil
    state.hover_target = nil
end

local function clear_thumbnail()
    if thumbnail_active and thumbfast.available then
        mp.commandv("script-message-to", "thumbfast", "clear")
    end
    thumbnail_active = false
    last_thumbnail_request = nil
end

local time_pos_render_pending = false
local time_pos_render_generation = 0

local function render()
    -- Any immediate render supersedes a queued playback-position update.
    time_pos_render_generation = time_pos_render_generation + 1
    time_pos_render_pending = false
    renderer:render()
end

local active_palette

local function reload_theme()
    local palette, source, err, diagnostics = Theme.load(opts.theme_file)
    if palette then
        active_palette = palette
    elseif not active_palette then
        active_palette = Theme.load("")
    end

    renderer:set_palette(active_palette)
    render()

    for _, diagnostic in ipairs(diagnostics or {}) do
        mp.msg.warn("Adwisp: theme " .. diagnostic)
    end

    if source == "file" then
        log_info("theme reloaded from file.")
    elseif source == "fallback" then
        log_info("using the built-in fallback theme.")
    else
        mp.msg.warn("Adwisp: theme reload failed; keeping the previous palette: "
            .. tostring(err))
    end
end

reload_theme()
log_debug("options loaded; seek_step=" .. tostring(opts.seek_step)
    .. ", volume_step=" .. tostring(opts.volume_step)
    .. ", thumbnail_preview=" .. tostring(opts.thumbnail_preview)
    .. ", osd_position=" .. tostring(opts.osd_position))

local function toggle()
    state.visible = not state.visible
    if not state.visible then
        clear_interaction_state()
        clear_thumbnail()
    end
    render()
end

local function option_step(value, fallback)
    value = tonumber(value)
    if type(value) ~= "number" or value ~= value
        or value == math.huge or value == -math.huge then
        return fallback
    end
    return math.max(1, math.min(3600, value))
end

local function seek(delta)
    mp.commandv("seek", delta, "relative", "keyframes")
end

local function change_volume(delta)
    local current = tonumber(state.volume) or 100
    local step = option_step(opts.volume_step, 5)
    local volume = math.max(0, math.min(100, current + delta * step))
    state.volume = volume
    state.mute = false
    mp.commandv("set", "volume", volume)
    mp.commandv("set", "mute", "no")
end

local function set_volume_at(mouse_x, track)
    if type(track.width) ~= "number" or track.width <= 0 then return end
    local fraction = math.max(0, math.min(1,
        (mouse_x - track.x) / track.width))
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

local function has_playlist_navigation()
    local count = state.playlist_count
    return type(count) == "number" and count == count
        and count ~= math.huge and count ~= -math.huge and math.floor(count) >= 2
end

local function finite_number(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

local function request_time_pos_render()
    if not state.visible then return end
    if type(mp.add_timeout) ~= "function" then
        render()
        return
    end
    if time_pos_render_pending then return end

    local interval = tonumber(opts.time_pos_render_interval)
    if not finite_number(interval) then interval = 0.15 end
    interval = math.max(0.05, math.min(0.5, interval))

    time_pos_render_pending = true
    time_pos_render_generation = time_pos_render_generation + 1
    local generation = time_pos_render_generation
    mp.add_timeout(interval, function()
        if generation ~= time_pos_render_generation or not time_pos_render_pending then
            return
        end
        time_pos_render_pending = false
        if state.visible then render() end
    end)
end

local function contains(rect, mouse_x, mouse_y)
    return mouse_x >= rect.x and mouse_x <= rect.x + rect.width
        and mouse_y >= rect.y and mouse_y <= rect.y + rect.height
end

local function get_layout(width, height)
    if not cached_layout or width ~= cached_layout_width
        or height ~= cached_layout_height
        or opts.osd_position ~= cached_layout_position
        or opts.osd_margin ~= cached_layout_margin
        or opts.osd_custom_offset ~= cached_layout_custom_offset then
        cached_layout = Layout.compute(width, height, opts)
        cached_layout_width, cached_layout_height = width, height
        cached_layout_position = opts.osd_position
        cached_layout_margin = opts.osd_margin
        cached_layout_custom_offset = opts.osd_custom_offset
    end
    return cached_layout
end

local function contains_timeline(timeline, mouse_x, mouse_y)
    return mouse_x >= timeline.hit_x
        and mouse_x <= timeline.hit_x + timeline.hit_width
        and mouse_y >= timeline.hit_y
        and mouse_y <= timeline.hit_y + timeline.hit_height
end

local function handle_mouse_move()
    if not state.visible or type(mp.get_mouse_pos) ~= "function" then return end
    local mouse_x, mouse_y = mp.get_mouse_pos()
    if not finite_number(mouse_x) or not finite_number(mouse_y) then return end
    local width, height = mp.get_osd_size()
    local layout = get_layout(width, height)
    if not layout then return end

    if active_drag == "volume" then
        set_volume_at(mouse_x, layout.volume.track)
    elseif active_drag == "timeline" then
        seek_at(mouse_x, layout.timeline)
    end

    local hover_target
    if contains(layout.playback, mouse_x, mouse_y) then
        hover_target = "playback"
    elseif contains(layout.volume, mouse_x, mouse_y) then
        hover_target = "volume"
    elseif has_playlist_navigation() and contains(layout.playlist, mouse_x, mouse_y) then
        hover_target = "playlist"
    elseif contains_timeline(layout.timeline, mouse_x, mouse_y) then
        hover_target = "timeline"
    end

    local timeline = layout.timeline
    local on_timeline = active_drag == nil
        and opts.thumbnail_preview ~= false
        and contains_timeline(timeline, mouse_x, mouse_y)
    if on_timeline and not thumbfast.disabled and state.duration > 0
        and thumbfast.width > 0 and thumbfast.height > 0 then
        local fraction = math.max(0, math.min(1,
            (mouse_x - layout.timeline.x) / layout.timeline.width))
        local seconds = math.floor(fraction * state.duration * 10 + 0.5) / 10
        local osd_width = width
        local x = math.floor(math.max(8, math.min(
            osd_width - thumbfast.width - 8, mouse_x - thumbfast.width / 2)))
        local y = math.floor(math.max(0, layout.timeline.y - thumbfast.height - 12))
        local request = { seconds = seconds, x = x, y = y }
        if not last_thumbnail_request
            or request.seconds ~= last_thumbnail_request.seconds
            or request.x ~= last_thumbnail_request.x
            or request.y ~= last_thumbnail_request.y then
            mp.commandv("script-message-to", "thumbfast", "thumb", seconds, x, y)
            last_thumbnail_request = request
        end
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
        active_drag = nil
        return
    end
    if not state.visible or type(mp.get_mouse_pos) ~= "function" then return end

    local mouse_x, mouse_y = mp.get_mouse_pos()
    if not finite_number(mouse_x) or not finite_number(mouse_y) then return end

    local width, height = mp.get_osd_size()
    local layout = get_layout(width, height)
    if not layout then return end

    local volume = layout.volume
    local volume_hit = volume.hit
    local timeline = layout.timeline

    if event and event.event == "down" then
        -- A new press replaces any previous drag, so the two interactions
        -- can never become active together.
        active_drag = nil
        if contains(volume_hit, mouse_x, mouse_y) then
            active_drag = "volume"
            set_volume_at(mouse_x, volume.track)
            return
        end
        if contains_timeline(timeline, mouse_x, mouse_y) then
            if state.duration > 0 then
                active_drag = "timeline"
                seek_at(mouse_x, timeline)
            end
            return
        end
    end

    if contains_timeline(timeline, mouse_x, mouse_y) then
        if state.duration > 0 then
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
    if has_playlist_navigation() and mouse_x >= playlist.x
        and mouse_x <= playlist.x + playlist.width
        and mouse_y >= playlist.y and mouse_y <= playlist.y + playlist.height then
        if mouse_x < playlist.x + playlist.width / 2 then
            mp.commandv("playlist-prev", "weak")
        else
            mp.commandv("playlist-next", "weak")
        end
        return
    end

    if contains(volume_hit, mouse_x, mouse_y) then
        set_volume_at(mouse_x, volume.track)
    end
end

-- Ignore invalid numeric property values instead of letting NaN or infinity
-- leak into interaction math or state used by the renderer.
local function finite_property(value, fallback)
    if type(value) ~= "number" or value ~= value
        or value == math.huge or value == -math.huge then
        return fallback
    end
    return value
end

-- Playback properties update the shared state and invalidate the renderer.
local observers = {
    { "pause", "bool", function(value) state.paused = value == true end },
    { "time-pos", "number", function(value) state.time_pos = finite_property(value, 0) end },
    { "duration", "number", function(value) state.duration = math.max(0, finite_property(value, 0)) end },
    { "media-title", "string", function(value) state.title = type(value) == "string" and value or "" end },
    { "volume", "number", function(value) state.volume = math.max(0, math.min(100, finite_property(value, 100))) end },
    { "mute", "bool", function(value) state.mute = value == true end },
    { "paused-for-cache", "bool", function(value) state.buffering = value == true end },
    { "cache-buffering-state", "number", function(value)
        state.buffering_progress = math.max(0, math.min(100, finite_property(value, 0)))
    end },
    { "playlist-pos", "number", function(value) state.playlist_pos = finite_property(value, -1) end },
    { "playlist-count", "number", function(value) state.playlist_count = math.max(0, finite_property(value, 0)) end },
}

for _, observer in ipairs(observers) do
    local property, property_type, apply = observer[1], observer[2], observer[3]
    mp.observe_property(property, property_type, function(_, value)
        apply(value)
        if property ~= "time-pos" then
            log_debug("property " .. property .. " updated")
        end
        if property == "time-pos" then
            request_time_pos_render()
        else
            render()
        end
    end)
end

mp.register_event("file-loaded", function()
    log_debug("file loaded")
    clear_interaction_state()
    clear_thumbnail()
    state.visible = true
    render()
end)

mp.register_event("end-file", function()
    log_debug("file ended")
    state.visible = false
    clear_interaction_state()
    clear_thumbnail()
    render()
end)

mp.register_event("video-reconfig", render)
mp.observe_property("osd-dimensions", "native", render)

mp.add_key_binding("g", "adwisp-toggle", toggle)
mp.add_key_binding("LEFT", "adwisp-seek-back", function()
    seek(-option_step(opts.seek_step, 5))
end)
mp.add_key_binding("RIGHT", "adwisp-seek-forward", function()
    seek(option_step(opts.seek_step, 5))
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
    if has_playlist_navigation() then
        mp.commandv("playlist-prev", "weak")
    end
end)
mp.add_key_binding("CTRL+RIGHT", "adwisp-playlist-next", function()
    if has_playlist_navigation() then
        mp.commandv("playlist-next", "weak")
    end
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
    local function positive_finite(value)
        return type(value) == "number" and value == value
            and value ~= math.huge and value ~= -math.huge and value > 0
    end
    if type(data) == "table" and positive_finite(data.width)
        and positive_finite(data.height) and type(data.disabled) == "boolean"
        and type(data.available) == "boolean" then
        last_thumbnail_request = nil
        thumbfast = {
            width = math.floor(data.width),
            height = math.floor(data.height),
            disabled = data.disabled,
            available = data.available,
        }
        if thumbfast.width < 1 or thumbfast.height < 1 then
            thumbfast = { width = 0, height = 0, disabled = true, available = false }
        end
        log_debug("thumbfast info: available=" .. tostring(thumbfast.available)
            .. ", disabled=" .. tostring(thumbfast.disabled)
            .. ", size=" .. thumbfast.width .. "x" .. thumbfast.height)
    else
        mp.msg.warn("Adwisp: received invalid thumbfast info; previews disabled.")
        thumbfast = { width = 0, height = 0, disabled = true, available = false }
    end
end)

local mpv_version = type(mp.get_property) == "function"
    and mp.get_property("mpv-version") or "unknown"
log_info("loaded on " .. tostring(mpv_version) .. ". Press g to toggle the OSD.")
