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
    speed_step = 0.1,
    loop_toggle_key = "CTRL+ALT+L",
    ab_loop_key = "CTRL+ALT+A",
    screenshot_key = "CTRL+ALT+S",
    idle_hide_timeout = 0,
    fade_duration = 0.25,
    theme_file = "",
    thumbnail_preview = true,
    thumbnail_export_directory = "~~/",
    thumbnail_export_prefix = "adwisp-thumbnail",
    time_pos_render_interval = 0.15,
    osd_position = "bottom",
    osd_margin = -1,
    osd_custom_offset = 120,
    font_family = "Sans",
    font_scale = 1.0,
    log_level = "info",
}
options.read_options(opts, "adwisp")
if type(opts.font_family) ~= "string" then opts.font_family = "Sans" end
opts.font_family = opts.font_family:sub(1, 48):gsub("[^%w _%-]", "")
opts.font_family = opts.font_family:match("^%s*(.-)%s*$")
if opts.font_family == "" then opts.font_family = "Sans" end
local configured_font_scale = tonumber(opts.font_scale)
if type(configured_font_scale) ~= "number" or configured_font_scale ~= configured_font_scale
    or configured_font_scale == math.huge or configured_font_scale == -math.huge then
    configured_font_scale = 1
end
opts.font_scale = math.max(0.75, math.min(1.25, configured_font_scale))
local idle_hide_timeout = tonumber(opts.idle_hide_timeout)
if type(idle_hide_timeout) ~= "number" or idle_hide_timeout ~= idle_hide_timeout
    or idle_hide_timeout == math.huge or idle_hide_timeout == -math.huge then
    idle_hide_timeout = 0
end
opts.idle_hide_timeout = math.max(0, math.min(600, idle_hide_timeout))
local fade_duration = tonumber(opts.fade_duration)
if type(fade_duration) ~= "number" or fade_duration ~= fade_duration
    or fade_duration == math.huge or fade_duration == -math.huge then
    fade_duration = 0.25
end
opts.fade_duration = math.max(0.05, math.min(1, fade_duration))
if opts.log_level ~= "quiet" and opts.log_level ~= "debug" then
    opts.log_level = "info"
end
if type(opts.thumbnail_export_directory) ~= "string"
    or opts.thumbnail_export_directory:match("^%s*$") then
    opts.thumbnail_export_directory = "~~/"
end
opts.thumbnail_export_directory = opts.thumbnail_export_directory:sub(1, 512)
if type(opts.thumbnail_export_prefix) ~= "string" then
    opts.thumbnail_export_prefix = "adwisp-thumbnail"
end
opts.thumbnail_export_prefix = opts.thumbnail_export_prefix:gsub("[^%w_.%-]", ""):sub(1, 48)
if opts.thumbnail_export_prefix == "" then
    opts.thumbnail_export_prefix = "adwisp-thumbnail"
end

local state = require "core.state"
state.layout_options = opts
local Renderer = require "core.renderer"
local Layout = require "core.layout"
local Theme = require "core.theme"
local utils = require "mp.utils"
local BMP = require "core.bmp"
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
local thumbfast = {
    width = 0, height = 0, source_width = 0, source_height = 0,
    disabled = true, available = false, thumbnail_path = nil,
}
local thumbnail_active = false
local last_thumbnail_request = nil
local cached_layout = nil
local cached_layout_width, cached_layout_height
local cached_layout_position, cached_layout_margin, cached_layout_custom_offset
local active_drag = nil
local last_mouse_x, last_mouse_y

local function clear_interaction_state()
    active_drag = nil
    last_mouse_x, last_mouse_y = nil, nil
    state.hover_target = nil
    state.focus_target = nil
end

local function clear_thumbnail()
    if thumbnail_active and thumbfast.available then
        mp.commandv("script-message-to", "thumbfast", "clear")
    end
    local was_visible = state.preview_visible == true
    state.preview_visible = false
    state.preview_time = 0
    state.preview_x, state.preview_y = 0, 0
    state.preview_width, state.preview_height = 0, 0
    thumbnail_active = false
    last_thumbnail_request = nil
    return was_visible
end

local thumbnail_export_sequence = 0

local function export_thumbnail()
    if not thumbnail_active or not thumbfast.available
        or type(thumbfast.thumbnail_path) ~= "string"
        or thumbfast.thumbnail_path == "" then
        mp.commandv("show-text", "Adwisp: no thumbfast preview is ready to export.", 3000)
        return
    end
    if thumbfast.source_width < 1 or thumbfast.source_width > 4096
        or thumbfast.source_height < 1 or thumbfast.source_height > 4096 then
        mp.commandv("show-text", "Adwisp: thumbfast preview dimensions are unsupported.", 3000)
        return
    end

    local source_path = thumbfast.thumbnail_path .. ".bgra"
    local source_info = utils.file_info(source_path)
    local expected_size = thumbfast.source_width * thumbfast.source_height * 4
    if not source_info or source_info.size ~= expected_size then
        mp.commandv("show-text", "Adwisp: thumbnail preview is not ready; try again.", 3000)
        return
    end

    local source = io.open(source_path, "rb")
    if not source then
        mp.commandv("show-text", "Adwisp: could not read the thumbfast preview.", 3000)
        return
    end
    local pixels = source:read("*a")
    source:close()
    local bitmap, encode_error = BMP.encode_bgra(
        thumbfast.source_width, thumbfast.source_height, pixels)
    if not bitmap then
        mp.msg.warn("Adwisp: thumbnail export failed: " .. tostring(encode_error))
        mp.commandv("show-text", "Adwisp: thumbnail export failed.", 3000)
        return
    end

    local directory = mp.command_native({ "expand-path", opts.thumbnail_export_directory })
    if type(directory) ~= "string" or directory == "" then
        mp.commandv("show-text", "Adwisp: thumbnail export directory is invalid.", 3000)
        return
    end
    local directory_info = utils.file_info(directory)
    if not directory_info or not directory_info.is_dir then
        mp.commandv("show-text", "Adwisp: export directory does not exist.", 3000)
        return
    end

    local separator = package.config:sub(1, 1)
    directory = directory:gsub("[/\\]+$", "")
    if directory == "" then directory = separator end
    local filename
    local output_path
    for _ = 1, 100 do
        thumbnail_export_sequence = thumbnail_export_sequence + 1
        filename = opts.thumbnail_export_prefix .. "-"
            .. os.date("%Y%m%d-%H%M%S") .. "-" .. thumbnail_export_sequence .. ".bmp"
        output_path = directory
            .. (directory:sub(-1) == separator and "" or separator) .. filename
        if not utils.file_info(output_path) then break end
        output_path = nil
    end
    if not output_path then
        mp.commandv("show-text", "Adwisp: could not choose a unique thumbnail filename.", 3000)
        return
    end

    local output, open_error = io.open(output_path, "wb")
    if not output then
        mp.msg.warn("Adwisp: could not write thumbnail: " .. tostring(open_error))
        mp.commandv("show-text", "Adwisp: could not write the thumbnail file.", 3000)
        return
    end
    local wrote, write_error = output:write(bitmap)
    local closed, close_error = output:close()
    if not wrote or not closed then
        os.remove(output_path)
        mp.msg.warn("Adwisp: thumbnail write failed: "
            .. tostring(write_error or close_error))
        mp.commandv("show-text", "Adwisp: thumbnail export failed while writing.", 3000)
        return
    end

    log_info("thumbnail exported to " .. output_path)
    mp.commandv("show-text", "Adwisp: exported " .. filename, 4000)
end

local time_pos_render_pending = false
local time_pos_render_generation = 0

local function render()
    -- Any immediate render supersedes a queued playback-position update.
    time_pos_render_generation = time_pos_render_generation + 1
    time_pos_render_pending = false
    renderer:render()
end

local function finite_number(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

local idle_timer
local fade_timer
local idle_generation = 0
local fade_generation = 0
local start_fade_out

local function kill_timer(timer)
    if timer and type(timer.kill) == "function" then
        timer:kill()
    end
end

local function schedule_idle_hide()
    idle_generation = idle_generation + 1
    local generation = idle_generation
    kill_timer(idle_timer)
    idle_timer = nil
    if not state.visible or opts.idle_hide_timeout <= 0
        or type(mp.add_timeout) ~= "function" then
        return
    end
    idle_timer = mp.add_timeout(opts.idle_hide_timeout, function()
        if generation ~= idle_generation or not state.visible then return end
        idle_timer = nil
        if active_drag ~= nil then return end
        start_fade_out()
    end)
end

local function cancel_fade()
    fade_generation = fade_generation + 1
    kill_timer(fade_timer)
    fade_timer = nil
end

local function animate_opacity(target, on_complete)
    cancel_fade()
    local generation = fade_generation
    local start = finite_number(state.opacity) and math.max(0, math.min(1, state.opacity)) or 1
    local duration = opts.fade_duration
    if not finite_number(duration) or duration <= 0
        or type(mp.add_timeout) ~= "function" then
        state.opacity = target
        render()
        if on_complete then on_complete() end
        return
    end

    local steps = 6
    local step = 0
    local function advance()
        if generation ~= fade_generation or not state.visible then return end
        fade_timer = nil
        step = step + 1
        state.opacity = start + (target - start) * (step / steps)
        render()
        if step >= steps then
            state.opacity = target
            if on_complete then on_complete() end
        else
            fade_timer = mp.add_timeout(duration / steps, advance)
        end
    end
    fade_timer = mp.add_timeout(duration / steps, advance)
end

start_fade_out = function()
    if not state.visible then return end
    idle_generation = idle_generation + 1
    animate_opacity(0, function()
        state.visible = false
        state.opacity = 1
        clear_interaction_state()
        clear_thumbnail()
        render()
    end)
end

local function show_osd()
    idle_generation = idle_generation + 1
    cancel_fade()
    state.visible = true
    if opts.idle_hide_timeout > 0 then
        state.opacity = 0
        render()
        schedule_idle_hide()
        animate_opacity(1)
    else
        state.opacity = 1
        render()
    end
end

local function hide_osd()
    idle_generation = idle_generation + 1
    kill_timer(idle_timer)
    idle_timer = nil
    cancel_fade()
    state.visible = false
    state.opacity = 1
    clear_interaction_state()
    clear_thumbnail()
    render()
end


-- Cancel deferred work and release UI/thumbnail state before mpv exits.
local function cleanup_on_shutdown()
    idle_generation = idle_generation + 1
    kill_timer(idle_timer)
    idle_timer = nil
    cancel_fade()
    time_pos_render_generation = time_pos_render_generation + 1
    time_pos_render_pending = false
    clear_interaction_state()
    clear_thumbnail()
    state.visible = false
    state.opacity = 1
    renderer:clear()
end
local function note_activity()
    if not state.visible then return end
    idle_generation = idle_generation + 1
    kill_timer(idle_timer)
    idle_timer = nil
    cancel_fade()
    local was_faded = state.opacity ~= 1
    state.opacity = 1
    if was_faded then render() end
    schedule_idle_hide()
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
    if state.visible then hide_osd() else show_osd() end
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
    note_activity()
    local current = tonumber(state.volume) or 100
    local step = option_step(opts.volume_step, 5)
    local volume = math.max(0, math.min(100, current + delta * step))
    state.volume = volume
    state.mute = false
    mp.commandv("set", "volume", volume)
    mp.commandv("set", "mute", "no")
end

local function speed_step()
    local value = tonumber(opts.speed_step)
    if not finite_number(value) then value = 0.1 end
    return math.max(0.01, math.min(5, value))
end

local function set_speed(value)
    note_activity()
    value = tonumber(value)
    if not finite_number(value) then value = 1 end
    value = math.max(0.01, math.min(100, value))
    state.speed = value
    mp.commandv("set", "speed", value)
end

local function change_speed(delta)
    local current = finite_number(state.speed) and state.speed or 1
    set_speed(current + delta * speed_step())
end

local function reset_speed()
    set_speed(1)
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

local function seek_chapter_marker(mouse_x, timeline)
    if not finite_number(state.duration) or state.duration <= 0
        or type(timeline.width) ~= "number" or timeline.width <= 0 then
        return false
    end
    local closest_time
    local closest_distance = 6
    for _, chapter in ipairs(state.chapter_list) do
        local chapter_time = type(chapter) == "table" and chapter.time or nil
        if finite_number(chapter_time) and chapter_time > 0
            and chapter_time < state.duration then
            local marker_x = timeline.x + chapter_time / state.duration * timeline.width
            local distance = math.abs(mouse_x - marker_x)
            if distance <= closest_distance then
                closest_distance = distance
                closest_time = chapter_time
            end
        end
    end
    if closest_time ~= nil then
        mp.commandv("seek", closest_time, "absolute")
        return true
    end
    return false
end

local function has_playlist_navigation()
    local count = state.playlist_count
    return type(count) == "number" and count == count
        and count ~= math.huge and count ~= -math.huge and math.floor(count) >= 2
end

local function set_focus(target)
    if state.focus_target ~= target then
        state.focus_target = target
        render()
    end
end

local function focus_targets()
    local targets = { "playback", "volume" }
    if has_playlist_navigation() then
        targets[#targets + 1] = "playlist"
    end
    return targets
end

local function cycle_focus(reverse)
    if not state.visible then return end
    note_activity()
    local targets = focus_targets()
    local current = 0
    for index, target in ipairs(targets) do
        if target == state.focus_target then
            current = index
            break
        end
    end
    if reverse then
        current = current <= 1 and #targets or current - 1
    else
        current = current >= #targets and 1 or current + 1
    end
    set_focus(targets[current])
end

local function activate_focus()
    if not state.visible then return end
    note_activity()
    if state.focus_target == "playback" then
        mp.commandv("cycle", "pause")
    elseif state.focus_target == "volume" then
        mp.commandv("cycle", "mute")
    elseif state.focus_target == "playlist" and has_playlist_navigation() then
        mp.commandv("playlist-next", "weak")
    end
end

local function handle_left()
    note_activity()
    if state.focus_target == "volume" then
        change_volume(-1)
    elseif state.focus_target == "playlist" and has_playlist_navigation() then
        mp.commandv("playlist-prev", "weak")
    else
        seek(-option_step(opts.seek_step, 5))
    end
end

local function handle_right()
    note_activity()
    if state.focus_target == "volume" then
        change_volume(1)
    elseif state.focus_target == "playlist" and has_playlist_navigation() then
        mp.commandv("playlist-next", "weak")
    else
        seek(option_step(opts.seek_step, 5))
    end
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
    -- mpv may emit repeated mouse_move callbacks at an unchanged position.
    -- They cannot change hover, preview, or drag state, so avoid the rest of
    -- the layout/hit-test work (and avoid resetting the idle timer).
    if mouse_x == last_mouse_x and mouse_y == last_mouse_y then return end
    last_mouse_x, last_mouse_y = mouse_x, mouse_y
    note_activity()
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
    local preview_changed = false
    local preview_cleared = false
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
        preview_changed = not state.preview_visible
            or seconds ~= state.preview_time
            or x ~= state.preview_x or y ~= state.preview_y
        state.preview_visible = true
        state.preview_time = seconds
        state.preview_x, state.preview_y = x, y
        state.preview_width, state.preview_height = thumbfast.width, thumbfast.height
        if not last_thumbnail_request
            or request.seconds ~= last_thumbnail_request.seconds
            or request.x ~= last_thumbnail_request.x
            or request.y ~= last_thumbnail_request.y then
            mp.commandv("script-message-to", "thumbfast", "thumb", seconds, x, y)
            last_thumbnail_request = request
        end
        thumbnail_active = true
    else
        preview_cleared = clear_thumbnail()
    end

    if state.hover_target ~= hover_target then
        state.hover_target = hover_target
        render()
    elseif preview_changed or preview_cleared then
        render()
    end
end

local function handle_mouse_click(event)
    if event and event.event == "up" then
        active_drag = nil
        note_activity()
        return
    end
    if not state.visible or type(mp.get_mouse_pos) ~= "function" then return end
    note_activity()

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
                if not seek_chapter_marker(mouse_x, timeline) then
                    seek_at(mouse_x, timeline)
                end
            end
            return
        end
    end

    if contains_timeline(timeline, mouse_x, mouse_y) then
        if state.duration > 0 and not seek_chapter_marker(mouse_x, timeline) then
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

-- Keep the chapter title in sync with mpv's zero-based chapter index and metadata.
local function update_chapter_title()
    local index = finite_property(state.chapter, -1)
    local chapters = state.chapter_list
    local chapter = type(chapters) == "table" and chapters[math.floor(index) + 1] or nil
    state.chapter_title = type(chapter) == "table" and type(chapter.title) == "string"
        and chapter.title or ""
end

local function describe_track(track)
    local parts = {}
    for _, field in ipairs({ "lang", "title", "codec" }) do
        local value = track[field]
        if type(value) == "string" then
            value = value:match("^%s*(.-)%s*$")
            if value ~= "" then parts[#parts + 1] = value end
        end
    end
    if #parts == 0 and track.id ~= nil then
        parts[#parts + 1] = "Track " .. tostring(track.id)
    end
    return table.concat(parts, " ")
end

local function update_track_state(value)
    local audio_count, subtitle_count = 0, 0
    local audio_label, subtitle_label = "", "Off"
    if type(value) == "table" then
        for _, track in ipairs(value) do
            if type(track) == "table" and track.type == "audio" then
                audio_count = audio_count + 1
                if track.selected == true then audio_label = describe_track(track) end
            elseif type(track) == "table" and track.type == "sub" then
                subtitle_count = subtitle_count + 1
                if track.selected == true then subtitle_label = describe_track(track) end
            end
        end
    end
    state.audio_track_count = audio_count
    state.audio_track_label = audio_label
    state.subtitle_track_count = subtitle_count
    state.subtitle_track_label = subtitle_label
end

-- Playback properties update the shared state and invalidate the renderer.
local observers = {
    { "pause", "bool", function(value) state.paused = value == true end },
    { "time-pos", "number", function(value) state.time_pos = finite_property(value, 0) end },
    { "duration", "number", function(value) state.duration = math.max(0, finite_property(value, 0)) end },
    { "media-title", "string", function(value) state.title = type(value) == "string" and value or "" end },
    { "volume", "number", function(value) state.volume = math.max(0, math.min(100, finite_property(value, 100))) end },
    { "speed", "number", function(value) state.speed = math.max(0.01, math.min(100, finite_property(value, 1))) end },
    { "loop-file", "string", function(value) state.loop_file = type(value) == "string" and value or "no" end },
    { "ab-loop-a", "number", function(value) state.ab_loop_a = finite_property(value, -1) end },
    { "ab-loop-b", "number", function(value) state.ab_loop_b = finite_property(value, -1) end },
    { "mute", "bool", function(value) state.mute = value == true end },
    { "paused-for-cache", "bool", function(value) state.buffering = value == true end },
    { "cache-buffering-state", "number", function(value)
        state.buffering_progress = math.max(0, math.min(100, finite_property(value, 0)))
    end },
    { "playlist-pos", "number", function(value) state.playlist_pos = finite_property(value, -1) end },
    { "playlist-count", "number", function(value) state.playlist_count = math.max(0, finite_property(value, 0)) end },
    { "chapter", "number", function(value)
        state.chapter = finite_property(value, -1)
        update_chapter_title()
    end },
    { "chapter-list", "native", function(value)
        local chapters = {}
        if type(value) == "table" then
            for _, item in ipairs(value) do
                if type(item) == "table" then
                    chapters[#chapters + 1] = {
                        title = type(item.title) == "string" and item.title or "",
                        time = finite_property(item.time, 0),
                    }
                end
            end
        end
        state.chapter_list = chapters
        update_chapter_title()
    end },
    { "track-list", "native", update_track_state },
}

for _, observer in ipairs(observers) do
    local property, property_type, apply = observer[1], observer[2], observer[3]
    mp.observe_property(property, property_type, function(_, value)
        apply(value)
        -- Property changes can alter hit-test visibility without pointer motion.
        last_mouse_x, last_mouse_y = nil, nil
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
    show_osd()
end)

mp.register_event("end-file", function()
    log_debug("file ended")
    hide_osd()
end)

-- mpv emits shutdown before terminating Lua script event loops.
mp.register_event("shutdown", cleanup_on_shutdown)

mp.register_event("video-reconfig", function()
    last_mouse_x, last_mouse_y = nil, nil
    render()
end)
mp.observe_property("osd-dimensions", "native", function()
    last_mouse_x, last_mouse_y = nil, nil
    render()
end)

local function chapter_timestamp(value)
    local seconds = math.max(0, math.floor(finite_property(value, 0)))
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local remainder = seconds % 60
    if hours > 0 then
        return string.format("%d:%02d:%02d", hours, minutes, remainder)
    end
    return string.format("%02d:%02d", minutes, remainder)
end

local function show_chapter_list()
    local chapters = type(state.chapter_list) == "table" and state.chapter_list or {}
    if #chapters == 0 then
        mp.commandv("show-text", "Adwisp: this media has no chapters.", 2500)
        return
    end

    local lines = { "Chapters" }
    local limit = math.min(#chapters, 20)
    local current = math.floor(finite_property(state.chapter, -1)) + 1
    for index = 1, limit do
        local chapter = chapters[index]
        local title = type(chapter.title) == "string" and chapter.title or ""
        title = title:gsub("[%c{}]", " "):gsub("\\", " "):gsub("%s+", " ")
            :match("^%s*(.-)%s*$")
        if title == "" then title = "Chapter " .. index end
        title = title:sub(1, 100)
        local marker = index == current and ">" or " "
        lines[#lines + 1] = string.format("%s %02d  %s  %s",
            marker, index, chapter_timestamp(chapter.time), title)
    end
    if #chapters > limit then
        lines[#lines + 1] = "... and " .. (#chapters - limit)
            .. " more (use Ctrl+Page Up/Down to navigate)"
    end
    note_activity()
    mp.commandv("show-text", table.concat(lines, "\n"), 8000)
end

mp.add_key_binding("g", "adwisp-toggle", toggle)
mp.add_key_binding("LEFT", "adwisp-seek-back", handle_left)
mp.add_key_binding("RIGHT", "adwisp-seek-forward", handle_right)
mp.add_key_binding("TAB", "adwisp-focus-next", function()
    cycle_focus(false)
end)
mp.add_key_binding("SHIFT+TAB", "adwisp-focus-previous", function()
    cycle_focus(true)
end)
mp.add_key_binding("ENTER", "adwisp-focus-activate", activate_focus)
mp.add_key_binding("q", "adwisp-dismiss", hide_osd)
mp.add_key_binding("ESC", "adwisp-dismiss-escape", hide_osd)
mp.add_key_binding("SPACE", "adwisp-play-pause", function()
    note_activity()
    mp.commandv("cycle", "pause")
end)
mp.add_key_binding("m", "adwisp-mute-toggle", function()
    note_activity()
    mp.commandv("cycle", "mute")
end)
mp.add_key_binding("CTRL+LEFT", "adwisp-playlist-prev", function()
    if has_playlist_navigation() then
        note_activity()
        mp.commandv("playlist-prev", "weak")
    end
end)
mp.add_key_binding("CTRL+RIGHT", "adwisp-playlist-next", function()
    if has_playlist_navigation() then
        note_activity()
        mp.commandv("playlist-next", "weak")
    end
end)
mp.add_key_binding("CTRL+PGUP", "adwisp-chapter-prev", function()
    if #state.chapter_list > 0 then
        note_activity()
        mp.commandv("add", "chapter", -1)
    end
end)
mp.add_key_binding("CTRL+PGDWN", "adwisp-chapter-next", function()
    if #state.chapter_list > 0 then
        note_activity()
        mp.commandv("add", "chapter", 1)
    end
end)
mp.add_key_binding("CTRL+ALT+F8", "adwisp-chapter-list", show_chapter_list)
mp.add_key_binding("CTRL+ALT+F5", "adwisp-audio-cycle", function()
    if state.audio_track_count > 1 then
        note_activity()
        mp.commandv("cycle", "audio")
    end
end)
mp.add_key_binding("CTRL+ALT+F6", "adwisp-subtitle-cycle", function()
    if state.subtitle_track_count > 0 then
        note_activity()
        mp.commandv("cycle", "sub")
    end
end)
mp.add_key_binding("CTRL+UP", "adwisp-volume-up", function()
    change_volume(1)
end)
mp.add_key_binding("CTRL+DOWN", "adwisp-volume-down", function()
    change_volume(-1)
end)
mp.add_key_binding("CTRL+ALT+UP", "adwisp-speed-up", function()
    change_speed(1)
end)
mp.add_key_binding("CTRL+ALT+DOWN", "adwisp-speed-down", function()
    change_speed(-1)
end)
mp.add_key_binding("CTRL+ALT+BACKSPACE", "adwisp-speed-reset", reset_speed)
mp.add_key_binding("CTRL+ALT+F7", "adwisp-thumbnail-export", export_thumbnail)

local function register_configurable_key_binding(option_name, binding_name, callback, fallback)
    local key = opts[option_name]
    if type(key) ~= "string" or key:match("^%s*$") or #key > 64 then
        key = fallback
    end
    local ok = pcall(mp.add_key_binding, key, binding_name, callback)
    if not ok then
        mp.msg.warn("Adwisp: invalid " .. option_name .. "; using " .. fallback .. ".")
        mp.add_key_binding(fallback, binding_name, callback)
    end
end

register_configurable_key_binding("loop_toggle_key", "adwisp-loop-toggle", function()
    note_activity()
    mp.commandv("cycle-values", "loop-file", "inf", "no")
end, "CTRL+ALT+L")
register_configurable_key_binding("ab_loop_key", "adwisp-ab-loop", function()
    note_activity()
    mp.commandv("ab-loop")
end, "CTRL+ALT+A")
register_configurable_key_binding("screenshot_key", "adwisp-screenshot", function()
    note_activity()
    mp.commandv("screenshot")
end, "CTRL+ALT+S")
mp.add_key_binding("MBTN_LEFT", "adwisp-mouse-click", handle_mouse_click, { complex = true })
mp.add_key_binding("mouse_move", "adwisp-mouse-move", handle_mouse_move, { complex = true })

local function register_no_argument_message(name, callback)
    mp.register_script_message(name, function(...)
        if select("#", ...) > 0 then
            mp.msg.warn("Adwisp: script message " .. name .. " does not accept arguments.")
            return
        end
        callback()
    end)
end

register_no_argument_message("adwisp-toggle", toggle)
register_no_argument_message("adwisp-show", show_osd)
register_no_argument_message("adwisp-hide", hide_osd)
register_no_argument_message("adwisp-reload-theme", reload_theme)
register_no_argument_message("adwisp-query", function()
    local payload = {
        visible = state.visible == true,
        paused = state.paused == true,
        time_pos = finite_property(state.time_pos, 0),
        duration = finite_property(state.duration, 0),
        volume = finite_property(state.volume, 100),
        speed = finite_property(state.speed, 1),
        loop_file = state.loop_file == "inf" and "inf" or state.loop_file,
        ab_loop_a = finite_property(state.ab_loop_a, -1),
        ab_loop_b = finite_property(state.ab_loop_b, -1),
        mute = state.mute == true,
        playlist_pos = finite_property(state.playlist_pos, -1),
        playlist_count = finite_property(state.playlist_count, 0),
        chapter = finite_property(state.chapter, -1),
        chapter_title = type(state.chapter_title) == "string" and state.chapter_title or "",
        audio_track_count = state.audio_track_count,
        audio_track_label = state.audio_track_label,
        subtitle_track_count = state.subtitle_track_count,
        subtitle_track_label = state.subtitle_track_label,
        buffering = state.buffering == true,
        buffering_progress = finite_property(state.buffering_progress, 0),
    }
    local json = utils.format_json(payload)
    if type(json) ~= "string" then
        mp.msg.warn("Adwisp: could not serialize state query.")
        return
    end
    -- A query is an explicit response, so it remains visible even at log_level=quiet.
    mp.msg.info("Adwisp state: " .. json)
end)
mp.register_script_message("thumbfast-info", function(json)
    last_mouse_x, last_mouse_y = nil, nil
    local data = utils.parse_json(json)
    local function positive_finite(value)
        return type(value) == "number" and value == value
            and value ~= math.huge and value ~= -math.huge and value > 0
    end
    if type(data) == "table" and positive_finite(data.width)
        and positive_finite(data.height) and data.width <= 8192 and data.height <= 8192
        and type(data.disabled) == "boolean" and type(data.available) == "boolean" then
        local preview_cleared = false
        local scale_factor = positive_finite(data.scale_factor) and data.scale_factor or 1
        local source_width = data.width / scale_factor
        local source_height = data.height / scale_factor
        if not positive_finite(source_width) or source_width > 4096 then source_width = 0
        else source_width = math.floor(source_width + 0.5) end
        if not positive_finite(source_height) or source_height > 4096 then source_height = 0
        else source_height = math.floor(source_height + 0.5) end
        local thumbnail_path = type(data.thumbnail) == "string"
            and #data.thumbnail <= 1024 and not data.thumbnail:find("\0", 1, true)
            and data.thumbnail ~= "" and data.thumbnail or nil
        local dimensions_changed = math.floor(data.width) ~= thumbfast.width
            or math.floor(data.height) ~= thumbfast.height
        local path_changed = thumbnail_path ~= thumbfast.thumbnail_path
        if data.disabled or not data.available
            or (thumbnail_active and (dimensions_changed or path_changed)) then
            preview_cleared = clear_thumbnail()
        end
        last_thumbnail_request = nil
        thumbfast = {
            width = math.floor(data.width),
            height = math.floor(data.height),
            source_width = source_width,
            source_height = source_height,
            disabled = data.disabled,
            available = data.available,
            thumbnail_path = thumbnail_path,
        }
        if preview_cleared then render() end
        if thumbfast.width < 1 or thumbfast.height < 1 then
            thumbfast = {
                width = 0, height = 0, source_width = 0, source_height = 0,
                disabled = true, available = false, thumbnail_path = nil,
            }
        end
        log_debug("thumbfast info: available=" .. tostring(thumbfast.available)
            .. ", disabled=" .. tostring(thumbfast.disabled)
            .. ", size=" .. thumbfast.width .. "x" .. thumbfast.height)
    else
        mp.msg.warn("Adwisp: received invalid thumbfast info; previews disabled.")
        local preview_cleared = clear_thumbnail()
        thumbfast = {
                width = 0, height = 0, source_width = 0, source_height = 0,
                disabled = true, available = false, thumbnail_path = nil,
            }
        if preview_cleared then render() end
    end
end)

local mpv_version = type(mp.get_property) == "function"
    and mp.get_property("mpv-version") or "unknown"
log_info("loaded on " .. tostring(mpv_version) .. ". Press g to toggle the OSD.")
