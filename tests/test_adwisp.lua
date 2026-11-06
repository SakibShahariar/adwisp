package.path = "./?.lua;./?/init.lua;" .. package.path

local observers = {}
local events = {}
local key_bindings = {}
local script_messages = {}
local commands = {}
local overlays = {}
local timers = {}
local mouse_x, mouse_y = 0, 0
local thumbfast_payload
local logs = { info = {}, warn = {} }

local mp = {
    get_script_directory = function() return "." end,
    observe_property = function(name, property_type, callback)
        observers[name] = { type = property_type, callback = callback }
    end,
    register_event = function(name, callback)
        events[name] = callback
    end,
    add_key_binding = function(key, name, callback)
        if key == "INVALID" then error("invalid test key") end
        key_bindings[name] = { key = key, callback = callback }
    end,
    add_forced_key_binding = function(key, name, callback, flags)
        key_bindings[name] = { key = key, callback = callback, flags = flags, forced = true }
    end,
    remove_key_binding = function(name)
        key_bindings[name] = nil
    end,
    register_script_message = function(name, callback)
        script_messages[name] = callback
    end,
    commandv = function(...)
        commands[#commands + 1] = { ... }
    end,
    command_native = function(args)
        if args[1] == "expand-path" then return "." end
        return nil
    end,
    add_timeout = function(seconds, callback)
        local timer = { timeout = seconds, callback = callback, killed = false }
        function timer:kill() self.killed = true end
        timers[#timers + 1] = timer
        return timer
    end,
    create_osd_overlay = function(kind)
        local overlay = { kind = kind, update_count = 0 }
        function overlay:update()
            self.update_count = self.update_count + 1
        end
        overlays[#overlays + 1] = overlay
        return overlay
    end,
    get_osd_size = function()
        return 1280, 720
    end,
    get_property = function(name)
        if name == "mpv-version" then return "mpv test-version" end
        return nil
    end,
    get_mouse_pos = function()
        return mouse_x, mouse_y
    end,
    msg = {
        info = function(message) logs.info[#logs.info + 1] = message end,
        warn = function(message) logs.warn[#logs.warn + 1] = message end,
    },
}

package.loaded.mp = mp
package.loaded["mp.utils"] = {
    parse_json = function() return thumbfast_payload end,
    format_json = function(value)
        return '{"visible":' .. tostring(value.visible)
            .. ',"paused":' .. tostring(value.paused)
            .. ',"volume":' .. tostring(value.volume)
            .. ',"speed":' .. tostring(value.speed)
            .. ',"loop_file":"' .. tostring(value.loop_file)
            .. '","ab_loop_a":' .. tostring(value.ab_loop_a)
            .. ',"ab_loop_b":' .. tostring(value.ab_loop_b) .. '}'
    end,
    file_info = function(path)
        if path == "." then return { is_dir = true } end
        local file = io.open(path, "rb")
        if not file then return nil end
        local data = file:read("*a")
        file:close()
        return { is_file = true, size = #data }
    end,
}
package.loaded["mp.options"] = {
    read_options = function(options)
        assert(options.seek_step == 5, "default seek step should be five seconds")
        assert(options.time_pos_render_interval == 0.15,
            "playback render interval should default to 150 milliseconds")
        assert(options.minimal_timeline == false,
            "minimal timeline should be disabled by default")
        assert(options.osd_position == "bottom",
            "OSD position should default to bottom")
        assert(options.osd_margin == -1,
            "OSD margin should default to responsive placement")
        assert(options.osd_custom_offset == 120,
            "custom OSD offset should have a safe default")
        assert(options.log_level == "info",
            "logging should default to concise informational output")
        assert(options.font_family == "Sans",
            "font family should have a safe default")
        assert(options.font_scale == 1,
            "font scale should default to 1")
        assert(options.loop_toggle_key == "CTRL+ALT+L",
            "file-loop shortcut should have a safe default")
        assert(options.ab_loop_key == "CTRL+ALT+A",
            "A-B loop shortcut should have a safe default")
        assert(options.screenshot_key == "CTRL+ALT+S",
            "screenshot shortcut should have a safe default")
        assert(options.toggle_key == "g", "toggle shortcut should default to g")
        assert(options.dismiss_key == "q", "dismiss shortcut should default to q")
        assert(options.dismiss_escape_key == "ESC", "escape dismiss shortcut should default to Escape")
        assert(options.seek_back_key == "LEFT", "seek-back shortcut should default to Left")
        assert(options.seek_forward_key == "RIGHT", "seek-forward shortcut should default to Right")
        assert(options.volume_up_key == "CTRL+UP", "volume-up shortcut should have a safe default")
        assert(options.volume_down_key == "CTRL+DOWN", "volume-down shortcut should have a safe default")
        assert(options.mute_toggle_key == "m", "mute shortcut should default to m")
        assert(options.playlist_prev_key == "CTRL+LEFT", "playlist-prev shortcut should have a safe default")
        assert(options.playlist_next_key == "CTRL+RIGHT", "playlist-next shortcut should have a safe default")
        options.seek_back_key = "ALT+LEFT"
        options.seek_forward_key = "ALT+LEFT"
        options.volume_up_key = "CTRL+ALT+F5"
        options.mute_toggle_key = "INVALID"
        assert(options.idle_hide_timeout == 0,
            "idle hide should be disabled by default")
        assert(options.fade_duration == 0.25,
            "fade duration should have a safe default")
        package.loaded["mp.options"].last_options = options
    end,
}

dofile("adwisp.lua")

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error((message or "values differ") .. ": expected " .. tostring(expected)
            .. ", got " .. tostring(actual), 2)
    end
end

local function assert_true(value, message)
    if not value then error(message or "expected true", 2) end
end

assert_equal(#overlays, 1, "entry point should create one OSD overlay")
assert_equal(overlays[1].kind, "ass-events", "renderer should use ASS events")
assert_equal(key_bindings["adwisp-toggle"].key, "g", "toggle should keep its default binding")
assert_equal(key_bindings["adwisp-seek-back"].key, "ALT+LEFT",
    "seek-back should accept a custom binding")
assert_equal(key_bindings["adwisp-seek-forward"].key, "RIGHT",
    "conflicting seek-forward binding should fall back to its default")
assert_equal(key_bindings["adwisp-volume-up"].key, "CTRL+UP",
    "bindings that conflict with fixed Adwisp actions should fall back")
assert_equal(key_bindings["adwisp-mute-toggle"].key, "m",
    "invalid key names should fall back to the documented default")
local reported_binding_issues = {}
for _, message in ipairs(logs.warn) do
    for _, option in ipairs({ "seek_forward_key", "volume_up_key", "mute_toggle_key" }) do
        if message:find(option, 1, true) then reported_binding_issues[option] = true end
    end
end
assert_true(reported_binding_issues.seek_forward_key
    and reported_binding_issues.volume_up_key and reported_binding_issues.mute_toggle_key,
    "conflicting and invalid bindings should be reported")
assert_true(observers.pause ~= nil, "pause property should be observed")
assert_true(observers["time-pos"] ~= nil, "playback position should be observed")
assert_true(observers["video-zoom"] ~= nil, "image zoom should be observed")
assert_true(observers["paused-for-cache"] ~= nil,
    "cache pause state should be observed")
assert_true(observers["cache-buffering-state"] ~= nil,
    "cache buffering progress should be observed")
assert_true(observers.chapter ~= nil and observers.chapter.type == "number",
    "current chapter index should be observed")
assert_true(observers["chapter-list"] ~= nil and observers["chapter-list"].type == "native",
    "chapter metadata should be observed")
assert_true(observers["track-list"] ~= nil and observers["track-list"].type == "native",
    "audio and subtitle track metadata should be observed")
assert_true(observers["audio-device-list"] ~= nil
    and observers["audio-device-list"].type == "native",
    "available audio output devices should be observed as native metadata")
assert_true(observers["audio-device"] ~= nil and observers["audio-device"].type == "string",
    "the selected audio output device should be observed")
assert_true(observers.playlist ~= nil and observers.playlist.type == "native",
    "playlist metadata should be observed")
assert_true(observers["osd-dimensions"] ~= nil, "OSD dimensions should be observed")
assert_true(events["file-loaded"] ~= nil, "file-loaded event should be registered")
assert_true(events["end-file"] ~= nil, "end-file event should be registered")
assert_true(events["shutdown"] ~= nil, "shutdown cleanup event should be registered")
assert_true(key_bindings["adwisp-toggle"] ~= nil, "toggle key should be registered")
assert_true(key_bindings["adwisp-dismiss-escape"] ~= nil, "Escape dismiss shortcut should be registered")
assert_true(key_bindings["adwisp-mouse-click"] ~= nil, "mouse click should be registered")
assert_true(key_bindings["adwisp-mouse-move"] ~= nil, "mouse move should be registered")
assert_true(key_bindings["adwisp-volume-up"] ~= nil, "volume-up shortcut should be registered")
assert_true(key_bindings["adwisp-volume-down"] ~= nil, "volume-down shortcut should be registered")
assert_true(key_bindings["adwisp-speed-up"] ~= nil, "speed-up shortcut should be registered")
assert_true(key_bindings["adwisp-speed-down"] ~= nil, "speed-down shortcut should be registered")
assert_true(key_bindings["adwisp-speed-reset"] ~= nil, "speed-reset shortcut should be registered")
assert_true(key_bindings["adwisp-focus-next"] ~= nil, "Tab should focus the next control")
assert_true(key_bindings["adwisp-focus-previous"] ~= nil, "Shift+Tab should focus the previous control")
assert_true(key_bindings["adwisp-focus-activate"] ~= nil, "Enter should activate the focused control")
assert_true(key_bindings["adwisp-loop-toggle"] ~= nil, "file-loop shortcut should be registered")
assert_true(key_bindings["adwisp-ab-loop"] ~= nil, "A-B loop shortcut should be registered")
assert_true(key_bindings["adwisp-screenshot"] ~= nil, "screenshot shortcut should be registered")
assert_true(key_bindings["adwisp-thumbnail-export"] ~= nil,
    "thumbfast thumbnail export shortcut should be registered")
assert_true(key_bindings["adwisp-playlist-prev"] ~= nil, "playlist-prev shortcut should be registered")
assert_true(key_bindings["adwisp-playlist-next"] ~= nil, "playlist-next shortcut should be registered")
assert_true(key_bindings["adwisp-chapter-prev"] ~= nil, "chapter-prev shortcut should be registered")
assert_true(key_bindings["adwisp-chapter-next"] ~= nil, "chapter-next shortcut should be registered")
assert_true(key_bindings["adwisp-chapter-list"] ~= nil, "chapter-list shortcut should be registered")
assert_true(key_bindings["adwisp-audio-cycle"] ~= nil, "audio-cycle shortcut should be registered")
assert_true(key_bindings["adwisp-subtitle-cycle"] ~= nil, "subtitle-cycle shortcut should be registered")
assert_true(key_bindings["adwisp-audio-menu"] ~= nil, "audio-menu shortcut should be registered")
assert_true(key_bindings["adwisp-audio-device-menu"] ~= nil,
    "audio output device menu shortcut should be registered")
assert_true(key_bindings["adwisp-subtitle-menu"] ~= nil, "subtitle-menu shortcut should be registered")
assert_true(key_bindings["adwisp-playlist-menu"] ~= nil, "playlist-menu shortcut should be registered")
assert_true(key_bindings["adwisp-mute-toggle"] ~= nil, "mute toggle shortcut should be registered")
assert_true(script_messages["adwisp-show"] ~= nil, "show message should be registered")
assert_true(script_messages["adwisp-hide"] ~= nil, "hide message should be registered")
assert_true(script_messages["adwisp-toggle"] ~= nil, "toggle message should be registered")
assert_true(script_messages["adwisp-reload-theme"] ~= nil, "theme reload message should be registered")
assert_true(script_messages["adwisp-query"] ~= nil, "state query message should be registered")
assert_true(script_messages["thumbfast-info"] ~= nil, "thumbfast info message should be registered")
local commands_before_empty_export = #commands
key_bindings["adwisp-thumbnail-export"].callback()
assert_equal(#commands, commands_before_empty_export + 1,
    "thumbnail export without an active preview should show feedback")
assert_equal(commands[#commands][1], "show-text",
    "thumbnail export without a preview should explain why it cannot proceed")
local saw_version = false
for _, message in ipairs(logs.info) do
    if message:find("mpv test-version", 1, true) then saw_version = true end
end
assert_true(saw_version, "startup diagnostics should include the mpv version")

-- Property callbacks should update state and safely render while the UI is hidden.
observers.pause.callback("pause", true)
observers["time-pos"].callback("time-pos", 12)
observers.duration.callback("duration", 60)
observers["media-title"].callback("media-title", "Test video")
observers["time-pos"].callback("time-pos", math.huge)
observers.duration.callback("duration", -20)
observers.volume.callback("volume", math.huge)
observers.speed.callback("speed", math.huge)
observers["playlist-count"].callback("playlist-count", 0 / 0)
observers["playlist-pos"].callback("playlist-pos", -math.huge)
local observed_state = require("core.state")
observers.playlist.callback("playlist", {
    { filename = "/videos/one.mkv", title = "One", current = true },
    { filename = "/videos/two.mkv", title = "Two", current = false },
})
assert_equal(observed_state.playlist_count, 2, "playlist metadata should populate playlist count")
assert_equal(observed_state.playlist_items[1].title, "One",
    "playlist view should prefer the entry title")
key_bindings["adwisp-playlist-menu"].callback()
assert_true(overlays[1].data:find("One", 1, true) ~= nil
    and overlays[1].data:find("Two", 1, true) ~= nil,
    "playlist view should list its entries")
key_bindings["adwisp-playlist-menu-select-2"].callback()
assert_equal(commands[#commands - 1][1], "set", "playlist selection should set playlist-pos")
assert_equal(commands[#commands - 1][2], "playlist-pos", "playlist selection should target playlist-pos")
assert_equal(commands[#commands - 1][3], 1, "playlist selection should use zero-based index")
key_bindings["adwisp-playlist-menu"].callback()
key_bindings["adwisp-playlist-menu-remove-1"].callback()
assert_equal(commands[#commands - 1][1], "playlist-remove",
    "playlist removal should use mpv playlist-remove command")
assert_equal(commands[#commands - 1][2], 0, "playlist removal should use zero-based index")
observers.playlist.callback("playlist", {})
key_bindings["adwisp-playlist-menu"].callback()
assert_true(commands[#commands][2]:find("playlist is empty", 1, true) ~= nil,
    "empty playlist should be reported gracefully")
observers.playlist.callback("playlist", {
    { title = "Entry 1", current = true },
    { title = "Entry 2" },
    { title = "Entry 3" },
    { title = "Entry 4" },
    { title = "Entry 5" },
    { title = "Entry 6" },
    { title = "Entry 7" },
    { title = "Entry 8" },
    { title = "Entry 9" },
    { title = "Entry 10" },
})
key_bindings["adwisp-playlist-menu"].callback()
assert_true(key_bindings["adwisp-playlist-menu-next"] ~= nil,
    "long playlists should expose a next-page shortcut")
key_bindings["adwisp-playlist-menu-next"].callback()
assert_true(overlays[1].data:find("Entry 10", 1, true) ~= nil,
    "playlist next-page should display later entries")
key_bindings["adwisp-playlist-menu-select-1"].callback()
assert_equal(commands[#commands - 1][3], 9,
    "playlist page selection should retain the absolute playlist index")
observers.playlist.callback("playlist", nil)
assert_equal(observed_state.time_pos, 0, "non-finite playback position should fall back to zero")
assert_equal(observed_state.duration, 0, "negative duration should clamp to zero")
assert_equal(observed_state.volume, 100, "non-finite volume should fall back to a safe default")
assert_equal(observed_state.speed, 1, "non-finite speed should fall back to normal speed")
observers["loop-file"].callback("loop-file", "inf")
observers["ab-loop-a"].callback("ab-loop-a", 12)
observers["ab-loop-b"].callback("ab-loop-b", 24)
assert_equal(observed_state.loop_file, "inf", "loop-file state should be observed")
assert_equal(observed_state.ab_loop_a, 12, "A-B start should be observed")
assert_equal(observed_state.ab_loop_b, 24, "A-B end should be observed")
observers["chapter-list"].callback("chapter-list", {
    { title = "Opening", time = 0 },
    { title = "The Journey", time = 42 },
})
observers.chapter.callback("chapter", 1)
assert_equal(observed_state.chapter_title, "The Journey",
    "current chapter title should follow mpv chapter metadata")
key_bindings["adwisp-chapter-list"].callback()
assert_equal(commands[#commands][1], "show-text", "chapter list should use mpv OSD text")
assert_true(commands[#commands][2]:find("Opening", 1, true) ~= nil
    and commands[#commands][2]:find("00:42", 1, true) ~= nil
    and commands[#commands][2]:find("The Journey", 1, true) ~= nil,
    "chapter list should include chapter titles and timestamps")
observers["track-list"].callback("track-list", {
    { type = "audio", id = 1, lang = "eng", title = "English", codec = "aac", selected = true },
    { type = "audio", id = 2, lang = "jpn", title = "Japanese", codec = "flac", selected = false },
    { type = "sub", id = 3, lang = "eng", title = "English", codec = "ass", selected = true },
})
assert_equal(observed_state.audio_track_count, 2, "audio track count should be read from mpv metadata")
assert_true(observed_state.audio_track_label:find("eng", 1, true) ~= nil
    and observed_state.audio_track_label:find("English", 1, true) ~= nil
    and observed_state.audio_track_label:find("aac", 1, true) ~= nil,
    "active audio label should include language, title, and codec")
assert_equal(observed_state.subtitle_track_count, 1, "subtitle track count should be read from mpv metadata")
assert_true(observed_state.subtitle_track_label:find("English", 1, true) ~= nil,
    "active subtitle label should include its title")
key_bindings["adwisp-audio-menu"].callback()
assert_true(commands[#commands][2]:find("Audio tracks", 1, true) ~= nil
    and commands[#commands][2]:find("Japanese", 1, true) ~= nil,
    "audio menu should list available tracks")
assert_true(key_bindings["adwisp-track-menu-select-2"] ~= nil,
    "audio menu should register number shortcuts for selection")
key_bindings["adwisp-track-menu-select-2"].callback()
assert_equal(commands[#commands - 1][1], "set", "audio menu selection should set mpv track property")
assert_equal(commands[#commands - 1][2], "aid", "audio menu should select the audio id")
assert_equal(commands[#commands - 1][3], 2, "audio menu should pass the selected track id")
assert_true(key_bindings["adwisp-track-menu-select-2"] == nil,
    "selecting an audio track should remove temporary menu shortcuts")
key_bindings["adwisp-subtitle-menu"].callback()
assert_true(commands[#commands][2]:find("Off", 1, true) ~= nil
    and commands[#commands][2]:find("English", 1, true) ~= nil,
    "subtitle menu should include Off and available subtitle tracks")
key_bindings["adwisp-track-menu-select-1"].callback()
assert_equal(commands[#commands - 1][1], "set", "subtitle Off selection should set mpv property")
assert_equal(commands[#commands - 1][2], "sid", "subtitle menu should target sid")
assert_equal(commands[#commands - 1][3], "no", "subtitle menu should expose an Off selection")
local commands_before_tracks = #commands
key_bindings["adwisp-audio-cycle"].callback()
assert_equal(commands[#commands][1], "cycle", "audio cycling should use mpv cycle command")
assert_equal(commands[#commands][2], "audio", "audio cycling should target audio tracks")
key_bindings["adwisp-subtitle-cycle"].callback()
assert_equal(commands[#commands][1], "cycle", "subtitle cycling should use mpv cycle command")
assert_equal(commands[#commands][2], "sub", "subtitle cycling should target subtitle tracks")
assert_true(#commands >= commands_before_tracks + 2,
    "track cycling should issue commands when tracks are available")
observers["track-list"].callback("track-list", nil)
local commands_without_tracks = #commands
key_bindings["adwisp-audio-cycle"].callback()
key_bindings["adwisp-subtitle-cycle"].callback()
assert_equal(#commands, commands_without_tracks,
    "track cycling should be a no-op when media has no tracks")
key_bindings["adwisp-audio-menu"].callback()
assert_true(commands[#commands][2]:find("no audio tracks", 1, true) ~= nil,
    "audio menu should explain when no audio tracks are available")
key_bindings["adwisp-subtitle-menu"].callback()
assert_true(commands[#commands][2]:find("no subtitle tracks", 1, true) ~= nil,
    "subtitle menu should explain when no subtitle tracks are available")

-- Playlist menu filtering preserves source indices and supports keyboard search.
observers["playlist"].callback("playlist", {
    { title = "Arrival", filename = "/media/arrival.mkv" },
    { title = "Episode 2", filename = "/media/nocturne.mkv", current = true },
    { title = "Arrival", filename = "/media/arrival-live.mkv" },
    { title = "Other", filename = "/media/other.mkv" },
})
observers["playlist-pos"].callback("playlist-pos", 1)
assert_equal(observed_state.playlist_items[2].filename, "/media/nocturne.mkv",
    "playlist state should retain filenames for metadata filtering")
local timers_before_playlist_view = #timers
key_bindings["adwisp-playlist-menu"].callback()
assert_equal(#timers, timers_before_playlist_view,
    "the playlist view should not schedule an auto-close timer")
assert_true(observed_state.playlist_menu ~= nil,
    "the playlist view should be rendered in the persistent OSD overlay")
assert_true(overlays[1].data:find("Playlist", 1, true) ~= nil,
    "the playlist panel should be visible in the renderer overlay")
assert_true(key_bindings["adwisp-playlist-menu-search-input"] ~= nil
    and key_bindings["adwisp-playlist-menu-search-input"].key == "ANY_UNICODE",
    "playlist menu should register forced text input while open")

local function type_playlist_query(value)
    for index = 1, #value do
        local character = value:sub(index, index)
        key_bindings["adwisp-playlist-menu-search-input"].callback({
            event = "down",
            key_name = character,
            key_text = character,
        })
    end
end

type_playlist_query("arr")
assert_true(overlays[1].data:find("Search: arr", 1, true) ~= nil
    and overlays[1].data:find("Arrival", 1, true) ~= nil
    and overlays[1].data:find("Episode 2", 1, true) == nil,
    "typing should filter playlist titles while preserving matching duplicates")
assert_true(key_bindings["adwisp-playlist-menu-select-2"] ~= nil,
    "filtered playlist results should retain number selection")
key_bindings["adwisp-playlist-menu-select-2"].callback()
assert_equal(commands[#commands - 1][1], "set",
    "filtered playlist selection should request a playlist position change")
assert_equal(commands[#commands - 1][2], "playlist-pos",
    "filtered playlist selection should update playlist-pos")
assert_equal(commands[#commands - 1][3], 2,
    "filtered row two should map to original playlist index three")
assert_true(key_bindings["adwisp-playlist-menu-search-input"] == nil,
    "selecting a playlist entry should remove temporary search bindings")

key_bindings["adwisp-playlist-menu"].callback()
type_playlist_query("noct")
assert_true(overlays[1].data:find("Episode 2", 1, true) ~= nil,
    "playlist filename metadata should match even when the title differs")
key_bindings["adwisp-playlist-menu-search-enter"].callback({ event = "down" })
assert_equal(commands[#commands - 1][3], 1,
    "Enter should select the filtered item using its original playlist index")

key_bindings["adwisp-playlist-menu"].callback()
type_playlist_query("arr")
key_bindings["adwisp-playlist-menu-search-clear"].callback({ event = "down" })
assert_true(overlays[1].data:find("Arrival", 1, true) ~= nil
    and overlays[1].data:find("Episode 2", 1, true) ~= nil
    and overlays[1].data:find(">* Episode 2", 1, true) ~= nil,
    "clearing search should restore the full list and current-item selection")

type_playlist_query("arr")
key_bindings["adwisp-playlist-menu-search-down"].callback({ event = "down" })
key_bindings["adwisp-playlist-menu-search-enter"].callback({ event = "down" })
assert_equal(commands[#commands - 1][3], 2,
    "Down and Enter should select the next filtered source item")

key_bindings["adwisp-playlist-menu"].callback()
type_playlist_query("arrx")
key_bindings["adwisp-playlist-menu-search-backspace"].callback({ event = "down" })
assert_true(overlays[1].data:find("Arrival", 1, true) ~= nil,
    "Backspace should remove the final search character")
type_playlist_query("zzzz")
assert_true(overlays[1].data:find("No matching playlist items", 1, true) ~= nil,
    "an empty filtered result should display a clear empty state")
key_bindings["adwisp-playlist-menu-search-escape"].callback({ event = "down" })
assert_true(key_bindings["adwisp-playlist-menu-search-input"] == nil,
    "Escape should close the playlist menu and remove temporary search bindings")
key_bindings["adwisp-playlist-menu"].callback()
assert_true(key_bindings["adwisp-playlist-menu-search-input"] ~= nil,
    "the playlist shortcut should reopen a dismissed view")
key_bindings["adwisp-playlist-menu"].callback()
assert_true(key_bindings["adwisp-playlist-menu-search-input"] == nil,
    "the playlist shortcut should toggle the view closed")
assert_equal(observed_state.playlist_menu, nil,
    "closing the playlist view should remove its persistent panel")
assert_true(key_bindings["adwisp-playlist-menu-wheel-down"] == nil,
    "closing the playlist panel should restore the normal mouse-wheel binding")
assert_equal(observed_state.playlist_items[1].title, "Arrival",
    "searching must not mutate mpv's playlist data")

-- Playlist page size adapts to the available OSD height and refreshes on resize.
local original_playlist_size = mp.get_osd_size
local long_playlist = {}
for index = 1, 20 do
    long_playlist[index] = {
        title = "Long playlist item " .. index,
        filename = "/media/item-" .. index .. ".mkv",
    }
end
observers["playlist"].callback("playlist", long_playlist)
mp.get_osd_size = function() return 420, 180 end
key_bindings["adwisp-playlist-menu"].callback()
assert_equal(observed_state.playlist_menu.page_size, 6,
    "a shorter OSD should show fewer playlist rows per page")
assert_true(key_bindings["adwisp-playlist-menu-wheel-down"] ~= nil
    and key_bindings["adwisp-playlist-menu-wheel-up"] ~= nil,
    "the open playlist panel should capture mouse-wheel navigation")
key_bindings["adwisp-playlist-menu-wheel-down"].callback({ event = "down" })
assert_true(overlays[1].data:find("2.  * Long playlist item 2", 1, true) ~= nil,
    "wheel-down should move the focused playlist entry")
key_bindings["adwisp-playlist-menu-wheel-up"].callback({ event = "down" })
assert_true(overlays[1].data:find("1.  * Long playlist item 1", 1, true) ~= nil,
    "wheel-up should move the focused playlist entry back")
assert_true(key_bindings["adwisp-playlist-menu-next"] ~= nil,
    "long playlists should expose page navigation")
key_bindings["adwisp-playlist-menu-next"].callback()
assert_equal(observed_state.playlist_menu.offset, 6,
    "next-page navigation should preserve the selected source entry")
mp.get_osd_size = original_playlist_size
observers["osd-dimensions"].callback("osd-dimensions", nil)
assert_equal(observed_state.playlist_menu.page_size, 9,
    "resizing the OSD should recalculate the visible playlist page size")
key_bindings["adwisp-playlist-menu"].callback()
observers["playlist"].callback("playlist", {})

-- Audio and subtitle track menus search their displayed language/title/codec labels.
observers["track-list"].callback("track-list", {
    { id = 1, type = "audio", lang = "eng", title = "Commentary", codec = "aac" },
    { id = 2, type = "audio", lang = "jpn", title = "Main", codec = "flac", selected = true },
    { id = 3, type = "sub", lang = "eng", title = "English", codec = "ass", selected = true },
    { id = 4, type = "sub", lang = "spa", title = "Spanish", codec = "srt" },
})
key_bindings["adwisp-audio-menu"].callback()
local function type_track_query(value)
    for index = 1, #value do
        local character = value:sub(index, index)
        key_bindings["adwisp-track-menu-search-input"].callback({
            event = "down",
            key_name = character,
            key_text = character,
        })
    end
end
type_track_query("jpn")
assert_true(commands[#commands][2]:find("Main", 1, true) ~= nil
    and commands[#commands][2]:find("Commentary", 1, true) == nil,
    "audio track search should match language metadata")
key_bindings["adwisp-track-menu-search-enter"].callback({ event = "down" })
assert_equal(commands[#commands - 1][2], "aid",
    "Enter should select a filtered audio track")
assert_equal(commands[#commands - 1][3], 2,
    "audio track filtering should preserve the original track ID")

key_bindings["adwisp-audio-menu"].callback()
type_track_query("aac")
assert_true(commands[#commands][2]:find("Commentary", 1, true) ~= nil,
    "audio track codec metadata should be searchable")
key_bindings["adwisp-track-menu-search-clear"].callback({ event = "down" })
assert_true(commands[#commands][2]:find("Main", 1, true) ~= nil
    and commands[#commands][2]:find("Commentary", 1, true) ~= nil
    and commands[#commands][2]:find(">* jpn Main", 1, true) ~= nil,
    "clearing track search should restore the selected audio track")

key_bindings["adwisp-subtitle-menu"].callback()
type_track_query("spa")
assert_true(commands[#commands][2]:find("Spanish", 1, true) ~= nil
    and commands[#commands][2]:find("English", 1, true) == nil,
    "subtitle track search should match language metadata")
key_bindings["adwisp-track-menu-search-enter"].callback({ event = "down" })
assert_equal(commands[#commands - 1][2], "sid",
    "Enter should select a filtered subtitle track")
assert_equal(commands[#commands - 1][3], 4,
    "subtitle track filtering should preserve the original track ID")
key_bindings["adwisp-subtitle-menu"].callback()
type_track_query("missing")
assert_true(commands[#commands][2]:find("No matching subtitle tracks", 1, true) ~= nil,
    "subtitle track search should show an empty-results state")
key_bindings["adwisp-track-menu-search-escape"].callback({ event = "down" })
observers["track-list"].callback("track-list", {})

-- Still-image controls activate only for mpv tracks marked as images.
local commands_before_image_controls = #commands
key_bindings["adwisp-image-fit"].callback()
key_bindings["adwisp-image-zoom-in"].callback()
assert_equal(#commands, commands_before_image_controls,
    "image controls should be inactive during ordinary playback")

observers["track-list"].callback("track-list", {
    { id = 7, type = "video", selected = true, image = true },
})
assert_equal(observed_state.image_mode, true,
    "a selected mpv still-image track should activate image mode")
key_bindings["adwisp-image-fit"].callback()
assert_equal(commands[#commands - 3][2], "video-unscaled",
    "fit should enable normal window scaling")
assert_equal(commands[#commands - 2][2], "video-zoom",
    "fit should reset video zoom")
assert_equal(commands[#commands - 1][2], "video-pan-x",
    "fit should center the image horizontally")
assert_equal(commands[#commands][2], "video-pan-y",
    "fit should center the image vertically")
key_bindings["adwisp-image-zoom-in"].callback()
assert_equal(commands[#commands][2], "video-zoom",
    "zoom in should update mpv's video-zoom property")
assert_equal(commands[#commands][3], 0.25,
    "zoom in should increase the logarithmic zoom value")
observers["video-zoom"].callback("video-zoom", 0.25)
key_bindings["adwisp-image-zoom-out"].callback()
assert_equal(commands[#commands][3], 0,
    "zoom out should reverse the previous zoom step")
key_bindings["adwisp-speed-reset"].callback()
assert_equal(commands[#commands - 3][2], "video-unscaled",
    "the reset shortcut should restore fit while image mode is active")
observers["track-list"].callback("track-list", {
    { id = 8, type = "video", selected = true, image = false },
})
assert_equal(observed_state.image_mode, false,
    "ordinary video tracks should leave image mode")
local commands_after_image_mode = #commands
key_bindings["adwisp-image-zoom-in"].callback()
assert_equal(#commands, commands_after_image_mode,
    "image zoom controls should become inactive when image playback ends")

observers["track-list"].callback("track-list", {
    { id = 9, type = "video", selected = true, albumart = true },
})
assert_equal(observed_state.image_mode, true,
    "a selected album-art image track should activate image mode")
observers["track-list"].callback("track-list", {})

-- Chapter search preserves the original chapter index and supports time metadata.
observers["chapter-list"].callback("chapter-list", {
    { title = "Opening", time = 0 },
    { title = "Middle", time = 60 },
    { title = "Final", time = 120 },
})
observers.chapter.callback("chapter", 1)
key_bindings["adwisp-chapter-list"].callback()
local function type_chapter_query(value)
    for index = 1, #value do
        local character = value:sub(index, index)
        key_bindings["adwisp-chapter-menu-search-input"].callback({
            event = "down",
            key_name = character,
            key_text = character,
        })
    end
end
type_chapter_query("final")
assert_true(commands[#commands][2]:find("Final", 1, true) ~= nil
    and commands[#commands][2]:find("Opening", 1, true) == nil,
    "chapter menu should filter chapter titles")
key_bindings["adwisp-chapter-menu-search-enter"].callback({ event = "down" })
assert_equal(commands[#commands - 1][2], "chapter",
    "Enter should select a filtered chapter")
assert_equal(commands[#commands - 1][3], 2,
    "chapter filtering should map to the original chapter index")

key_bindings["adwisp-chapter-list"].callback()
type_chapter_query("60")
assert_true(commands[#commands][2]:find("Middle", 1, true) ~= nil,
    "chapter timestamps should be searchable")
key_bindings["adwisp-chapter-menu-search-clear"].callback({ event = "down" })
assert_true(commands[#commands][2]:find("Opening", 1, true) ~= nil
    and commands[#commands][2]:find("Final", 1, true) ~= nil
    and commands[#commands][2]:find(">* 01:00  Middle", 1, true) ~= nil,
    "clearing chapter search should restore the full list and current chapter")
type_chapter_query("missing")
assert_true(commands[#commands][2]:find("No matching chapters", 1, true) ~= nil,
    "chapter menu should display an empty-results state")
key_bindings["adwisp-chapter-menu-search-escape"].callback({ event = "down" })
observers["chapter-list"].callback("chapter-list", {})
observers.chapter.callback("chapter", -1)

observers["playlist"].callback("playlist", {
    { title = "Fallback item", filename = "/media/fallback.mkv" },
})
local original_forced_binding = mp.add_forced_key_binding
mp.add_forced_key_binding = function(key, name, callback, flags)
    if key == "ANY_UNICODE" then error("unsupported pseudo-key") end
    return original_forced_binding(key, name, callback, flags)
end
key_bindings["adwisp-playlist-menu"].callback()
assert_true(key_bindings["adwisp-playlist-menu-search-input"] == nil
    and overlays[1].data:find("Text filtering is unavailable", 1, true) ~= nil,
    "unsupported ANY_UNICODE should not break the playlist menu")
key_bindings["adwisp-playlist-menu-search-escape"].callback({ event = "down" })
mp.add_forced_key_binding = original_forced_binding

observers["playlist"].callback("playlist", {})
observers["playlist-pos"].callback("playlist-pos", -1)

-- Audio output devices use mpv's audio-device-list/audio-device properties.
key_bindings["adwisp-audio-device-menu"].callback()
assert_true(commands[#commands][2]:find("no audio output devices", 1, true) ~= nil,
    "an empty audio-device list should be reported safely")
observers["audio-device-list"].callback("audio-device-list", {
    { name = "auto", description = "Automatic output" },
    { name = "pipewire/speaker", description = "Built-in Speakers" },
    { name = "pipewire/headset", description = "Bluetooth Headphones" },
    { name = "", description = "Invalid empty device" },
    { name = 42, description = "Invalid non-string device" },
    "invalid entry",
})
observers["audio-device"].callback("audio-device", "pipewire/headset")
assert_equal(observed_state.audio_device, "pipewire/headset",
    "the selected audio output should follow mpv's audio-device property")
assert_equal(#observed_state.audio_devices, 3,
    "malformed audio-device entries should be ignored")
key_bindings["adwisp-audio-device-menu"].callback()
assert_true(commands[#commands][2]:find("Automatic output", 1, true) ~= nil
    and commands[#commands][2]:find("Built-in Speakers", 1, true) ~= nil
    and commands[#commands][2]:find("> Bluetooth Headphones", 1, true) ~= nil,
    "the device menu should list descriptions and mark the active device")
assert_true(key_bindings["adwisp-audio-device-select-2"] ~= nil,
    "the device menu should register number shortcuts")
key_bindings["adwisp-audio-device-select-2"].callback()
assert_equal(commands[#commands - 1][1], "set",
    "device selection should request an mpv property change")
assert_equal(commands[#commands - 1][2], "audio-device",
    "device selection should set audio-device")
assert_equal(commands[#commands - 1][3], "pipewire/speaker",
    "device selection should pass the original mpv device name")
assert_true(commands[#commands][2]:find("requested audio output", 1, true) ~= nil,
    "device selection should provide feedback")

-- An open device menu refreshes when mpv reports a changed device list or active output.
key_bindings["adwisp-audio-device-menu"].callback()
observers["audio-device-list"].callback("audio-device-list", {
    { name = "auto", description = "Automatic output" },
    { name = "pipewire/headset", description = "Bluetooth Headphones" },
})
assert_true(key_bindings["adwisp-audio-device-select-3"] == nil,
    "refreshing a shorter device list should remove stale selection bindings")
assert_true(commands[#commands][2]:find("Audio output devices", 1, true) ~= nil
    and commands[#commands][2]:find("Built-in Speakers", 1, true) == nil,
    "an open menu should refresh to the latest device list")
observers["audio-device"].callback("audio-device", "pipewire/missing")
assert_true(commands[#commands][2]:find("not in the available device list", 1, true) ~= nil,
    "a disconnected current device should be identified without breaking the menu")
key_bindings["adwisp-audio-device-menu"].callback()
assert_true(key_bindings["adwisp-audio-device-menu-next"] == nil,
    "short device lists should not expose unnecessary pagination")
local many_devices = { { name = "auto", description = "Automatic output" } }
for index = 1, 10 do
    many_devices[#many_devices + 1] = {
        name = "test/device-" .. index,
        description = "Test device " .. index,
    }
end
observers["audio-device-list"].callback("audio-device-list", many_devices)
key_bindings["adwisp-audio-device-menu"].callback()
assert_true(key_bindings["adwisp-audio-device-menu-next"] ~= nil,
    "long device lists should expose a next-page shortcut")
key_bindings["adwisp-audio-device-menu-next"].callback()
assert_true(commands[#commands][2]:find("Test device 10", 1, true) ~= nil,
    "the second page should display devices beyond the first nine")
key_bindings["adwisp-audio-device-select-2"].callback()
assert_equal(commands[#commands - 1][3], "test/device-10",
    "second-page selection should map to the original device name")
observers["audio-device-list"].callback("audio-device-list", nil)
key_bindings["adwisp-audio-device-menu"].callback()
assert_true(commands[#commands][2]:find("no audio output devices", 1, true) ~= nil,
    "a missing device list should be handled safely")
observers["chapter-list"].callback("chapter-list", {
    { title = "Opening", time = 0 },
    { title = "Middle", time = 60 },
})
observers.chapter.callback("chapter", 1)
local commands_before_chapters = #commands
key_bindings["adwisp-chapter-prev"].callback()
assert_equal(commands[#commands][1], "add", "previous chapter should use mpv chapter command")
assert_equal(commands[#commands][2], "chapter", "previous chapter should target chapter index")
assert_equal(commands[#commands][3], -1, "previous chapter should decrement chapter index")
key_bindings["adwisp-chapter-next"].callback()
assert_equal(commands[#commands][3], 1, "next chapter should increment chapter index")
assert_true(#commands >= commands_before_chapters + 2,
    "chapter shortcuts should send navigation commands when chapters exist")
observers["chapter-list"].callback("chapter-list", nil)
local commands_without_chapters = #commands
key_bindings["adwisp-chapter-prev"].callback()
key_bindings["adwisp-chapter-next"].callback()
assert_equal(#commands, commands_without_chapters,
    "chapter shortcuts should be no-ops when media has no chapters")
key_bindings["adwisp-chapter-list"].callback()
assert_true(commands[#commands][2]:find("no chapters", 1, true) ~= nil,
    "chapter list should report when media has no chapters")
observers["chapter-list"].callback("chapter-list", {
    { title = "Opening", time = 0 },
    { title = "The Journey", time = 42 },
})
observers.chapter.callback("chapter", 1)
observers["loop-file"].callback("loop-file", "no")
observers["ab-loop-a"].callback("ab-loop-a", nil)
observers["ab-loop-b"].callback("ab-loop-b", nil)
observers.chapter.callback("chapter", math.huge)
assert_equal(observed_state.playlist_count, 0, "non-finite playlist count should fall back to zero")
assert_equal(observed_state.playlist_pos, -1, "non-finite playlist position should fall back to no selection")
assert_equal(observed_state.chapter, -1, "invalid chapter index should fall back to no selection")
observers["cache-buffering-state"].callback("cache-buffering-state", 45)
observers["paused-for-cache"].callback("paused-for-cache", true)
assert_equal(observed_state.buffering, true,
    "paused-for-cache should activate the buffering indicator")
assert_equal(observed_state.buffering_progress, 45,
    "cache progress should be retained for the indicator")
observers["cache-buffering-state"].callback("cache-buffering-state", 150)
assert_equal(observed_state.buffering_progress, 100,
    "cache progress should clamp to 100 percent")
observers["paused-for-cache"].callback("paused-for-cache", false)
assert_equal(observed_state.buffering, false,
    "local or resumed playback should hide the buffering indicator")
script_messages["adwisp-hide"]()
local hidden_overlay_updates = overlays[1].update_count
observers["time-pos"].callback("time-pos", 12)
observers.duration.callback("duration", 60)
observers.volume.callback("volume", 100)
observers.speed.callback("speed", 1)
observers["playlist-count"].callback("playlist-count", 0)
observers["playlist-pos"].callback("playlist-pos", -1)
assert_equal(overlays[1].update_count, hidden_overlay_updates,
    "hidden OSD should not redraw after playback state changes")

-- Loop, A-B repeat, and screenshot shortcuts use mpv's documented commands.
key_bindings["adwisp-loop-toggle"].callback()
assert_equal(commands[#commands][1], "cycle-values",
    "loop toggle should use mpv's cycle-values command")
assert_equal(commands[#commands][2], "loop-file",
    "loop toggle should target the current file")
assert_equal(commands[#commands][3], "inf",
    "loop toggle should enable infinite file looping")
assert_equal(commands[#commands][4], "no",
    "loop toggle should disable file looping on the next cycle")
key_bindings["adwisp-ab-loop"].callback()
assert_equal(commands[#commands][1], "ab-loop",
    "A-B shortcut should use mpv's A-B loop state command")
key_bindings["adwisp-screenshot"].callback()
assert_equal(commands[#commands][1], "screenshot",
    "screenshot shortcut should use mpv's screenshot command")

-- Playback speed controls clamp values and always use mpv's speed property.
local commands_before_speed = #commands
key_bindings["adwisp-speed-up"].callback()
assert_equal(commands[#commands][1], "set",
    "speed increase should set the mpv speed property")
assert_equal(commands[#commands][2], "speed",
    "speed increase should target speed")
assert_equal(commands[#commands][3], 1.1,
    "speed increase should use the configured step")
key_bindings["adwisp-speed-down"].callback()
assert_equal(commands[#commands][3], 1,
    "speed decrease should return to normal speed")
key_bindings["adwisp-speed-reset"].callback()
assert_equal(commands[#commands][3], 1,
    "speed reset should restore normal playback")
observed_state.speed = 99.95
key_bindings["adwisp-speed-up"].callback()
assert_equal(commands[#commands][3], 100,
    "speed increase should respect mpv's upper speed bound")
observed_state.speed = 0.02
key_bindings["adwisp-speed-down"].callback()
assert_equal(commands[#commands][3], 0.01,
    "speed decrease should respect mpv's lower speed bound")
assert_true(#commands > commands_before_speed,
    "speed actions should send commands to mpv")

-- Loading a file makes the UI visible and renders current state.
events["file-loaded"]()
assert_equal(overlays[1].update_count, 2, "file-loaded should render the OSD")
assert_true(overlays[1].data:find("Test video", 1, true) ~= nil,
    "rendered OSD should include the current media title")
assert_true(overlays[1].data:find("Play", 1, true) ~= nil,
    "paused playback should show a Play action")

-- Re-rendering unchanged state should use the renderer cache.
observers.pause.callback("pause", true)
assert_equal(overlays[1].update_count, 2, "unchanged render should be cached")

-- Playback-position updates are coalesced, but the latest value is rendered.
local timer_count_before_position = #timers
local updates_before_position = overlays[1].update_count
observers["time-pos"].callback("time-pos", 24)
assert_equal(#timers, timer_count_before_position + 1,
    "the first visible time-pos update should schedule one render")
local position_timer = timers[#timers]
assert_equal(position_timer.timeout, 0.15,
    "time-pos renders should use the configured interval")
observers["time-pos"].callback("time-pos", 26)
assert_equal(#timers, timer_count_before_position + 1,
    "rapid time-pos updates should share the pending timer")
assert_equal(overlays[1].update_count, updates_before_position,
    "time-pos updates should not render before the throttle window")
position_timer.callback()
assert_equal(overlays[1].update_count, updates_before_position + 1,
    "the scheduled callback should render once")
assert_true(overlays[1].data:find("0:26", 1, true) ~= nil,
    "the scheduled render should use the latest playback position")

-- An immediate non-time observer supersedes a queued playback render.
observers["time-pos"].callback("time-pos", 27)
local stale_position_timer = timers[#timers]
local updates_before_immediate = overlays[1].update_count
observers["media-title"].callback("media-title", "Immediate update")
assert_equal(overlays[1].update_count, updates_before_immediate + 1,
    "non-time observers should still render immediately")
assert_true(stale_position_timer.killed,
    "an immediate observer should cancel the pending playback timer")
stale_position_timer.callback()
assert_equal(overlays[1].update_count, updates_before_immediate + 1,
    "superseded time-pos callbacks should not trigger stale renders")
observers["media-title"].callback("media-title", "Test video")

observers["playlist-count"].callback("playlist-count", 5)
observers["playlist-pos"].callback("playlist-pos", 1)
assert_true(overlays[1].data:find("2 / 5", 1, true) ~= nil,
    "playlist row should show the current item position and total")

-- Keyboard focus cycles through interactive controls and activates the selection.
key_bindings["adwisp-focus-next"].callback()
assert_equal(observed_state.focus_target, "playback",
    "Tab should focus playback first")
key_bindings["adwisp-focus-activate"].callback()
assert_equal(commands[#commands][1], "cycle",
    "Enter should activate the focused playback control")
assert_equal(commands[#commands][2], "pause",
    "playback activation should toggle pause")
key_bindings["adwisp-focus-next"].callback()
assert_equal(observed_state.focus_target, "volume",
    "Tab should advance focus to volume")
observed_state.volume = 50
local volume_before_focus = observed_state.volume
key_bindings["adwisp-seek-forward"].callback()
assert_equal(observed_state.volume, volume_before_focus + 5,
    "right arrow should adjust volume when volume has focus")
key_bindings["adwisp-focus-activate"].callback()
assert_equal(commands[#commands][1], "cycle",
    "Enter should activate the focused volume control")
assert_equal(commands[#commands][2], "mute",
    "volume activation should toggle mute")
key_bindings["adwisp-focus-previous"].callback()
assert_equal(observed_state.focus_target, "playback",
    "Shift+Tab should move focus backwards")
key_bindings["adwisp-focus-next"].callback()
key_bindings["adwisp-focus-next"].callback()
assert_equal(observed_state.focus_target, "playlist",
    "Tab should include playlist when multiple items are available")
key_bindings["adwisp-seek-forward"].callback()
assert_equal(commands[#commands][1], "playlist-next",
    "right arrow should advance the playlist when playlist has focus")
key_bindings["adwisp-focus-activate"].callback()
assert_equal(commands[#commands][1], "playlist-next",
    "Enter should activate the focused playlist control")
key_bindings["adwisp-focus-next"].callback()
assert_equal(observed_state.focus_target, "playback",
    "focus should wrap to the first control")


local option_fixture = package.loaded["mp.options"].last_options
option_fixture.seek_step = math.huge
key_bindings["adwisp-seek-back"].callback()
assert_equal(commands[#commands][2], -5,
    "infinite seek step should fall back to the safe default")
option_fixture.seek_step = 5

key_bindings["adwisp-seek-back"].callback()
assert_equal(commands[#commands][1], "seek", "left seek should issue seek command")
assert_equal(commands[#commands][2], -5, "left seek should use configured step")
key_bindings["adwisp-seek-forward"].callback()
assert_equal(commands[#commands][2], 5, "right seek should use configured step")

key_bindings["adwisp-play-pause"].callback()
assert_equal(commands[#commands][1], "cycle", "play/pause should cycle pause")
assert_equal(commands[#commands][2], "pause", "play/pause should target pause")

key_bindings["adwisp-mute-toggle"].callback()
assert_equal(commands[#commands][1], "cycle", "mute shortcut should cycle mute")
assert_equal(commands[#commands][2], "mute", "mute shortcut should target mute state")

-- Single-item playlists must not accept keyboard navigation.
observers["playlist-count"].callback("playlist-count", 1)
observers["playlist-pos"].callback("playlist-pos", 0)
local commands_before_single_item_keys = #commands
key_bindings["adwisp-playlist-prev"].callback()
key_bindings["adwisp-playlist-next"].callback()
assert_equal(#commands, commands_before_single_item_keys,
    "single-item playlists should ignore keyboard navigation")
observers["playlist-count"].callback("playlist-count", 5)
observers["playlist-pos"].callback("playlist-pos", 1)

key_bindings["adwisp-playlist-prev"].callback()
assert_equal(commands[#commands][1], "playlist-prev", "Ctrl+Left should go to previous playlist item")
assert_equal(commands[#commands][2], "weak", "previous shortcut should use weak mode")
key_bindings["adwisp-playlist-next"].callback()
assert_equal(commands[#commands][1], "playlist-next", "Ctrl+Right should go to next playlist item")
assert_equal(commands[#commands][2], "weak", "next shortcut should use weak mode")

-- Excessively large but finite volume steps should be bounded before adjustment.
option_fixture = package.loaded["mp.options"].last_options
option_fixture.volume_step = 1e100
key_bindings["adwisp-volume-down"].callback()
assert_equal(commands[#commands - 1][3], 0,
    "excessive volume step should be bounded and volume clamped to zero")
option_fixture.volume_step = 5
observers.volume.callback("volume", 100)

-- Keyboard volume shortcuts should adjust by the configured step and unmute.
key_bindings["adwisp-volume-down"].callback()
assert_equal(commands[#commands - 1][1], "set", "volume-down should set volume")
assert_equal(commands[#commands - 1][2], "volume", "volume-down should target volume")
assert_equal(commands[#commands - 1][3], 95, "volume-down should reduce volume by five")
assert_equal(commands[#commands][2], "mute", "volume adjustment should clear mute")
assert_equal(commands[#commands][3], "no", "volume adjustment should unmute playback")
key_bindings["adwisp-volume-up"].callback()
assert_equal(commands[#commands - 1][3], 100, "volume-up should increase volume by five")

-- NaN and infinite pointer coordinates must be ignored rather than entering geometry.
local original_mouse_x, original_mouse_y = mouse_x, mouse_y
mouse_x, mouse_y = 0 / 0, 20
local command_count_before_invalid_mouse = #commands
key_bindings["adwisp-mouse-click"].callback()
key_bindings["adwisp-mouse-move"].callback()
assert_equal(#commands, command_count_before_invalid_mouse,
    "non-finite mouse coordinates should not issue commands")
mouse_x, mouse_y = math.huge, 20
key_bindings["adwisp-mouse-click"].callback()
assert_equal(#commands, command_count_before_invalid_mouse,
    "infinite mouse coordinates should not issue commands")
mouse_x, mouse_y = original_mouse_x, original_mouse_y

-- Mouse clicks should seek proportionally along the shared timeline geometry.
local Layout = require "core.layout"
local layout = Layout.compute(1280, 720)
-- Repeated mouse_move callbacks at an identical position must skip layout
-- lookup and hit-testing rather than repeating work for an unchanged pointer.
local original_get_osd_size = mp.get_osd_size
local osd_size_calls = 0
mp.get_osd_size = function()
    osd_size_calls = osd_size_calls + 1
    return original_get_osd_size()
end
mouse_x, mouse_y = 12, 12
key_bindings["adwisp-mouse-move"].callback()
local osd_calls_after_pointer_move = osd_size_calls
key_bindings["adwisp-mouse-move"].callback()
assert_equal(osd_size_calls, osd_calls_after_pointer_move,
    "unchanged mouse coordinates should skip OSD geometry and hit-testing")

-- Playback-position updates do not change hit-test geometry, so a stationary
-- pointer must remain on the duplicate-coordinate fast path.
observers["time-pos"].callback("time-pos", 28)
local playback_timer = timers[#timers]
local calls_after_playback_update = osd_size_calls
key_bindings["adwisp-mouse-move"].callback()
assert_equal(osd_size_calls, calls_after_playback_update,
    "time-pos updates should not invalidate the unchanged pointer cache")
playback_timer.callback()

-- Duration changes affect timeline preview eligibility and must re-evaluate
-- the pointer even when its coordinates have not changed.
observers.duration.callback("duration", 90)
local calls_after_duration_update = osd_size_calls
key_bindings["adwisp-mouse-move"].callback()
assert_equal(osd_size_calls, calls_after_duration_update + 1,
    "duration updates should invalidate the pointer cache")
observers.duration.callback("duration", 60)

local function assert_pointer_cache_invalidated(label, trigger)
    mouse_x, mouse_y = 17, 17
    key_bindings["adwisp-mouse-move"].callback()
    trigger()
    local calls_after_trigger = osd_size_calls
    key_bindings["adwisp-mouse-move"].callback()
    assert_equal(osd_size_calls, calls_after_trigger + 1, label)
end

-- Playlist content and count determine whether playlist navigation is hit-testable.
assert_pointer_cache_invalidated("playlist changes should invalidate the pointer cache", function()
    observers["playlist"].callback("playlist", {
        { title = "First", filename = "/media/first.mkv" },
        { title = "Second", filename = "/media/second.mkv" },
    })
end)
observers["playlist"].callback("playlist", {})
assert_pointer_cache_invalidated("playlist visibility changes should invalidate the pointer cache", function()
    observers["playlist-count"].callback("playlist-count", 2)
end)

-- OSD geometry changes and video reconfiguration alter the hit-test coordinate space.
assert_pointer_cache_invalidated("OSD dimension changes should invalidate the pointer cache", function()
    observers["osd-dimensions"].callback("osd-dimensions", { w = 640, h = 480 })
end)
assert_pointer_cache_invalidated("video reconfiguration should invalidate the pointer cache", function()
    events["video-reconfig"]()
end)

-- thumbfast metadata can change preview geometry under a stationary pointer.
thumbfast_payload = {
    width = 160, height = 90, scale_factor = 1,
    disabled = false, available = true, thumbnail = "thumbfast-cache",
}
assert_pointer_cache_invalidated("thumbfast metadata changes should invalidate the pointer cache", function()
    script_messages["thumbfast-info"]("{}")
end)
thumbfast_payload = { width = 160, height = 90, disabled = true, available = false }
script_messages["thumbfast-info"]("{}")
thumbfast_payload = nil

mp.get_osd_size = original_get_osd_size

-- Mouse movement warms the OSD-size layout cache; clicks should reuse it.
mouse_x, mouse_y = 10, 10
key_bindings["adwisp-mouse-move"].callback()
local original_layout_compute = Layout.compute
local layout_compute_calls = 0
Layout.compute = function(...)
    layout_compute_calls = layout_compute_calls + 1
    return original_layout_compute(...)
end
mouse_x = layout.timeline.x + layout.timeline.width / 2
mouse_y = layout.timeline.y
key_bindings["adwisp-mouse-click"].callback()
assert_equal(layout_compute_calls, 0,
    "mouse clicks should reuse the cached layout for unchanged OSD dimensions")
Layout.compute = original_layout_compute
assert_equal(commands[#commands][1], "seek", "timeline click should issue seek")
assert_equal(commands[#commands][2], 50, "timeline midpoint should seek to 50 percent")
assert_equal(commands[#commands][3], "absolute-percent",
    "timeline click should use absolute-percent mode")

-- Clicking near a chapter marker seeks to the exact chapter timestamp.
mouse_x = layout.timeline.x + layout.timeline.width * 0.7
mouse_y = layout.timeline.y
key_bindings["adwisp-mouse-click"].callback()
assert_equal(commands[#commands][1], "seek", "chapter marker click should issue a seek")
assert_equal(commands[#commands][2], 42, "chapter marker click should seek to its exact timestamp")
assert_equal(commands[#commands][3], "absolute",
    "chapter marker click should use absolute time rather than approximate percent")

-- Configured OSD placement must be shared by rendering and hit testing.
option_fixture.osd_position = "top"
option_fixture.osd_margin = 24
local top_layout = Layout.compute(1280, 720, option_fixture)
assert_equal(top_layout.panel.y, 24, "top OSD should use its configured margin")
observers["media-title"].callback("media-title", "Top OSD")
assert_true(overlays[1].data:find("\\pos(360,24)", 1, true) ~= nil,
    "renderer should place the panel at the configured top offset")
local commands_before_top_click = #commands
mouse_x = top_layout.playback.x + 5
mouse_y = top_layout.playback.y + 5
key_bindings["adwisp-mouse-click"].callback()
assert_equal(commands[#commands][1], "cycle",
    "mouse hit testing should follow the repositioned playback control")
assert_equal(#commands, commands_before_top_click + 1,
    "clicking the repositioned control should issue exactly one command")
option_fixture.osd_position = "bottom"
option_fixture.osd_margin = -1

-- Minimal timeline expands on hover, keyboard focus, and active dragging.
option_fixture.minimal_timeline = true
script_messages["adwisp-show"]()
local collapsed_timeline = Layout.compute(1280, 720, option_fixture)
assert_equal(collapsed_timeline.timeline.height, 2,
    "minimal-timeline mode should start with a thin progress line")
mouse_x = collapsed_timeline.timeline.x + collapsed_timeline.timeline.width / 2
mouse_y = collapsed_timeline.timeline.hit_y + collapsed_timeline.timeline.hit_height / 2
key_bindings["adwisp-mouse-move"].callback()
assert_equal(observed_state.hover_target, "timeline",
    "hovering the collapsed hit region should activate timeline hover")
assert_equal(option_fixture.timeline_expanded, true,
    "timeline hover should expand the minimal timeline")
assert_true(overlays[1].data:find(" / 1:00", 1, true) ~= nil,
    "hover expansion should restore the time label")

mouse_x = collapsed_timeline.timeline.x + collapsed_timeline.timeline.width / 2
mouse_y = collapsed_timeline.timeline.hit_y + collapsed_timeline.timeline.hit_height / 2
key_bindings["adwisp-mouse-click"].callback({ event = "down" })
assert_equal(option_fixture.timeline_expanded, true,
    "starting a timeline drag should expand the timeline")
mouse_x, mouse_y = 10, 10
key_bindings["adwisp-mouse-move"].callback()
assert_equal(option_fixture.timeline_expanded, true,
    "an active timeline drag should keep the timeline expanded outside hover")
key_bindings["adwisp-mouse-click"].callback({ event = "up" })
assert_equal(option_fixture.timeline_expanded, false,
    "releasing a drag outside the timeline should collapse it")

observed_state.focus_target = nil
key_bindings["adwisp-focus-next"].callback()
key_bindings["adwisp-focus-next"].callback()
key_bindings["adwisp-focus-next"].callback()
assert_equal(observed_state.focus_target, "timeline",
    "minimal-timeline mode should add the timeline to keyboard focus order")
assert_equal(option_fixture.timeline_expanded, true,
    "keyboard focus should expand the timeline")
local commands_before_focused_seek = #commands
key_bindings["adwisp-seek-forward"].callback()
assert_equal(commands[#commands][1], "seek",
    "Left/Right should seek while the timeline has keyboard focus")
assert_equal(#commands, commands_before_focused_seek + 1,
    "focused timeline seek should issue one command")
key_bindings["adwisp-focus-previous"].callback()
assert_true(observed_state.focus_target ~= "timeline",
    "Shift+Tab should move focus away from the timeline")
assert_equal(option_fixture.timeline_expanded, false,
    "moving keyboard focus away should collapse the timeline")
option_fixture.minimal_timeline = false
option_fixture.timeline_expanded = false
script_messages["adwisp-show"]()
observers["media-title"].callback("media-title", "Test video")
mouse_x = layout.playback.x + 5
mouse_y = layout.playback.y + 5

-- Clicking the playback control should toggle pause.
mouse_x = layout.playback.x + 5
mouse_y = layout.playback.y + 5
key_bindings["adwisp-mouse-click"].callback()
assert_equal(commands[#commands][1], "cycle", "playback click should issue cycle")
assert_equal(commands[#commands][2], "pause", "playback click should target pause")

-- A single-item playlist hides its controls and rejects mouse interaction.
mouse_x, mouse_y = 10, 10
key_bindings["adwisp-mouse-move"].callback()
observers["playlist-count"].callback("playlist-count", 1)
observers["playlist-pos"].callback("playlist-pos", 0)
mouse_x = layout.playlist.x + 5
mouse_y = layout.playlist.y + 5
key_bindings["adwisp-mouse-move"].callback()
assert_true(overlays[1].data:find("Previous", 1, true) == nil
    and overlays[1].data:find("Next", 1, true) == nil,
    "single-item playlists should hide navigation controls")
assert_true(overlays[1].data:find("\\alpha&H30&", 1, true) == nil,
    "single-item playlist row should not show hover feedback")
local commands_before_single_item_click = #commands
key_bindings["adwisp-mouse-click"].callback()
assert_equal(#commands, commands_before_single_item_click,
    "single-item playlists should ignore mouse navigation")
observers["playlist-count"].callback("playlist-count", 5)
observers["playlist-pos"].callback("playlist-pos", 1)

-- Multi-item playlists retain their navigation controls and hover feedback.
mouse_x = layout.playlist.x + 5
mouse_y = layout.playlist.y + 5
key_bindings["adwisp-mouse-move"].callback()
assert_true(overlays[1].data:find("\\alpha&H30&", 1, true) ~= nil,
    "hovering playlist should draw a highlight")

-- Playlist row halves should navigate backward and forward.
mouse_x = layout.playlist.x + layout.playlist.width * 0.25
mouse_y = layout.playlist.y + 5
key_bindings["adwisp-mouse-click"].callback()
assert_equal(commands[#commands][1], "playlist-prev",
    "left playlist half should go to previous item")
assert_equal(commands[#commands][2], "weak", "previous item should use weak mode")

mouse_x = layout.playlist.x + layout.playlist.width * 0.75
mouse_y = layout.playlist.y + 5
key_bindings["adwisp-mouse-click"].callback()
assert_equal(commands[#commands][1], "playlist-next",
    "right playlist half should go to next item")
assert_equal(commands[#commands][2], "weak", "next item should use weak mode")

-- The volume label is not part of the slider hit area.
mouse_x = layout.volume.x + layout.volume.width * 0.75
mouse_y = layout.volume.y + 5
local commands_before_volume_label_click = #commands
key_bindings["adwisp-mouse-click"].callback()
assert_equal(#commands, commands_before_volume_label_click,
    "clicking the volume label should not change the slider")

-- Clicking the visible volume track should set volume proportionally and unmute.
local volume_track = layout.volume.track
local volume_hit = layout.volume.hit
mouse_x = volume_track.x + volume_track.width * 0.75
mouse_y = volume_track.y + volume_track.height / 2
key_bindings["adwisp-mouse-click"].callback()
assert_equal(commands[#commands - 1][1], "set", "volume click should set volume")
assert_equal(commands[#commands - 1][2], "volume", "volume click should target volume")
assert_equal(commands[#commands - 1][3], 75, "volume click should map to percentage")
assert_equal(commands[#commands][1], "set", "volume click should ensure audio is unmuted")
assert_equal(commands[#commands][2], "mute", "volume click should target mute state")
assert_equal(commands[#commands][3], "no", "volume click should unmute playback")
assert_true(overlays[1].data:find("Volume 75%", 1, true) ~= nil,
    "volume click should update the displayed value immediately")

-- Mouse-down starts volume dragging and mouse movement updates the slider.
mouse_x = volume_track.x + volume_track.width * 0.2
mouse_y = volume_hit.y + volume_hit.height / 2
key_bindings["adwisp-mouse-click"].callback({ event = "down" })
assert_equal(commands[#commands - 1][3], 20, "drag start should set volume at pointer")
mouse_x = volume_track.x + volume_track.width * 0.6
key_bindings["adwisp-mouse-move"].callback()
assert_equal(commands[#commands - 1][3], 60, "drag movement should update volume")
key_bindings["adwisp-mouse-click"].callback({ event = "up" })
local after_drag = #commands
mouse_x = volume_track.x + volume_track.width * 0.9
key_bindings["adwisp-mouse-move"].callback()
assert_equal(#commands, after_drag,
    "mouse movement after drag release should not continue changing volume")

-- Volume values should clamp at both ends of the slider.
mouse_x = volume_track.x
mouse_y = volume_track.y + volume_track.height / 2
key_bindings["adwisp-mouse-click"].callback()
assert_equal(commands[#commands - 1][3], 0, "volume below slider should clamp to zero")
mouse_x = volume_track.x + volume_track.width
key_bindings["adwisp-mouse-click"].callback()
assert_equal(commands[#commands - 1][3], 100, "volume at slider end should reach one hundred")

-- Clicks outside controls should not issue commands.
local command_count = #commands
mouse_x = 10
mouse_y = 10
key_bindings["adwisp-mouse-click"].callback()
assert_equal(#commands, command_count, "click outside controls should be ignored")

-- Hovering playback controls should update the visible overlay.
-- Reuse the layout module loaded above
local hover_layout = Layout.compute(1280, 720)
mouse_x = hover_layout.playback.x + 5
mouse_y = hover_layout.playback.y + 5
key_bindings["adwisp-mouse-move"].callback()
assert_true(overlays[1].data:find("\\alpha&H30&", 1, true) ~= nil,
    "hovering playback should draw a highlight")

mouse_x = 10
mouse_y = 10
key_bindings["adwisp-mouse-move"].callback()
assert_true(overlays[1].data:find("\\alpha&H30&", 1, true) == nil,
    "moving outside controls should remove the highlight")

-- Malformed dimensions and missing status flags must disable previews safely.
thumbfast_payload = { width = math.huge, height = 90, disabled = false, available = true }
script_messages["thumbfast-info"]("{}")
mouse_x = layout.timeline.x + layout.timeline.width / 2
mouse_y = layout.timeline.y
key_bindings["adwisp-mouse-move"].callback()
assert_true(commands[#commands][3] ~= "thumb",
    "infinite thumbnail dimensions must not trigger a preview")
thumbfast_payload = { width = 10000, height = 90, disabled = false, available = true }
script_messages["thumbfast-info"]("{}")
key_bindings["adwisp-mouse-move"].callback()
assert_true(commands[#commands][3] ~= "thumb",
    "excessive thumbnail dimensions must not trigger a preview")
thumbfast_payload = { width = 160, height = 90, available = true }
script_messages["thumbfast-info"]("{}")
key_bindings["adwisp-mouse-move"].callback()
assert_true(commands[#commands][3] ~= "thumb",
    "missing thumbfast status flags must disable previews")

-- thumbfast supplies thumbnail dimensions; Adwisp requests previews only on timeline hover.
thumbfast_payload = { width = 160, height = 90, disabled = false, available = true }
script_messages["thumbfast-info"]("{}")
mouse_x = hover_layout.timeline.x + hover_layout.timeline.width / 2
mouse_y = hover_layout.timeline.y
key_bindings["adwisp-mouse-move"].callback()
assert_true(overlays[1].data:find("\\alpha&H30&", 1, true) ~= nil,
    "hovering timeline should draw a highlight")
assert_equal(commands[#commands][1], "script-message-to",
    "timeline hover should send a thumbfast script message")
assert_equal(commands[#commands][2], "thumbfast", "preview should target thumbfast")
assert_equal(commands[#commands][3], "thumb", "preview should use thumbfast thumb command")
assert_equal(commands[#commands][4], 30, "timeline midpoint should preview midpoint time")
assert_true(type(commands[#commands][5]) == "number", "preview should provide x coordinate")
assert_true(type(commands[#commands][6]) == "number", "preview should provide y coordinate")
assert_true(overlays[1].data:find("0:30", 1, true) ~= nil,
    "timeline hover should show the preview timestamp")
assert_true(overlays[1].data:find("\\an8\\pos(", 1, true) ~= nil,
    "preview timestamp should use its own positioned label")

-- Disabling thumbfast clears the timestamp immediately; re-enabling restores it.
thumbfast_payload = { width = 160, height = 90, disabled = true, available = false }
script_messages["thumbfast-info"]("{}")
assert_true(overlays[1].data:find("0:30", 1, true) == nil,
    "unavailable thumbfast previews should hide the timestamp")
assert_equal(commands[#commands][3], "clear",
    "disabling thumbfast should clear its active preview")
thumbfast_payload = { width = 160, height = 90, disabled = false, available = true }
script_messages["thumbfast-info"]("{}")
key_bindings["adwisp-mouse-move"].callback()
assert_true(overlays[1].data:find("0:30", 1, true) ~= nil,
    "re-enabled thumbfast previews should restore the timestamp")

-- A thumbfast restart/path change must clear the old preview before accepting new frames.
thumbfast_payload = {
    width = 160, height = 90, disabled = false, available = true,
    thumbnail = "/tmp/adwisp-preview-a",
}
script_messages["thumbfast-info"]("{}")
key_bindings["adwisp-mouse-move"].callback()
assert_equal(observed_state.preview_visible, true,
    "a valid thumbfast adapter should restore the active preview")
thumbfast_payload = {
    width = 160, height = 90, disabled = false, available = true,
    thumbnail = "/tmp/adwisp-preview-b",
}
script_messages["thumbfast-info"]("{}")
assert_equal(observed_state.preview_visible, false,
    "changing thumbfast's backing path should clear the old preview")
assert_equal(commands[#commands][3], "clear",
    "thumbfast path changes should clear the previous adapter preview")
key_bindings["adwisp-mouse-move"].callback()

-- Repeated motion within the same 100ms preview bucket should not resend a request.
local preview_command_count = #commands
key_bindings["adwisp-mouse-move"].callback()
assert_equal(#commands, preview_command_count,
    "unchanged thumbnail preview requests should be deduplicated")

mouse_x = 10
mouse_y = 10
key_bindings["adwisp-mouse-move"].callback()
assert_equal(commands[#commands][1], "script-message-to",
    "leaving timeline should send a thumbfast clear message")
assert_equal(commands[#commands][2], "thumbfast", "clear should target thumbfast")
assert_equal(commands[#commands][3], "clear", "leaving timeline should clear preview")
assert_true(overlays[1].data:find("0:30", 1, true) == nil,
    "leaving the timeline should hide the preview timestamp")

-- Invalid adapter messages must clear an active preview and disable future requests.
mouse_x = hover_layout.timeline.x + hover_layout.timeline.width / 2
mouse_y = hover_layout.timeline.y
thumbfast_payload = {
    width = 160, height = 90, disabled = false, available = true,
    thumbnail = "/tmp/adwisp-preview-invalid",
}
script_messages["thumbfast-info"]("{}")
key_bindings["adwisp-mouse-move"].callback()
assert_equal(observed_state.preview_visible, true,
    "invalid-message setup should activate a preview")
local warnings_before_invalid_thumbfast = #logs.warn
thumbfast_payload = nil
script_messages["thumbfast-info"]("{}")
assert_equal(#logs.warn, warnings_before_invalid_thumbfast + 1,
    "invalid thumbfast metadata should produce a warning")
assert_equal(observed_state.preview_visible, false,
    "invalid thumbfast metadata should clear the active preview")
local commands_before_disabled_thumbfast = #commands
key_bindings["adwisp-mouse-move"].callback()
assert_equal(#commands, commands_before_disabled_thumbfast,
    "invalid thumbfast metadata should disable subsequent preview requests")

-- Loading a new file and ending the current file must both clear active previews.
thumbfast_payload = {
    width = 160, height = 90, disabled = false, available = true,
    thumbnail = "/tmp/adwisp-preview-file-load",
}
script_messages["thumbfast-info"]("{}")
key_bindings["adwisp-mouse-move"].callback()
assert_equal(observed_state.preview_visible, true,
    "file-load setup should activate a preview")
events["file-loaded"]()
assert_equal(observed_state.preview_visible, false,
    "loading a new file should clear the previous thumbnail")
assert_equal(commands[#commands][3], "clear",
    "loading a new file should notify thumbfast to clear its preview")

thumbfast_payload = {
    width = 160, height = 90, disabled = false, available = true,
    thumbnail = "/tmp/adwisp-preview-end-file",
}
script_messages["thumbfast-info"]("{}")
key_bindings["adwisp-mouse-move"].callback()
assert_equal(observed_state.preview_visible, true,
    "end-file setup should activate a preview")
events["end-file"]()
assert_equal(observed_state.preview_visible, false,
    "ending a file should clear its thumbnail")
assert_equal(commands[#commands][3], "clear",
    "ending a file should notify thumbfast to clear its preview")

script_messages["adwisp-show"]()
mouse_x = hover_layout.timeline.x + hover_layout.timeline.width / 2
mouse_y = hover_layout.timeline.y
thumbfast_payload = {
    width = 160, height = 90, disabled = false, available = true,
    thumbnail = "/tmp/adwisp-preview-dismiss",
}
script_messages["thumbfast-info"]("{}")
key_bindings["adwisp-mouse-move"].callback()
assert_equal(observed_state.preview_visible, true,
    "dismissal setup should activate a preview")
script_messages["adwisp-hide"]()
assert_equal(observed_state.preview_visible, false,
    "dismissing the OSD should clear its thumbnail")
assert_equal(commands[#commands][3], "clear",
    "dismissing the OSD should notify thumbfast to clear its preview")
script_messages["adwisp-show"]()

-- Export a real one-pixel thumbfast BGRA fixture through the public shortcut.
local fixture_path = "tests/adwisp-thumbfast-fixture"
local fixture = assert(io.open(fixture_path .. ".bgra", "wb"))
local fixture_pixel = string.char(0x11, 0x22, 0x33, 0x44)
assert(fixture:write(fixture_pixel))
assert(fixture:close())
thumbfast_payload = {
    width = 1, height = 1, scale_factor = 1,
    disabled = false, available = true, thumbnail = fixture_path,
}
script_messages["thumbfast-info"]("{}")
mouse_x = hover_layout.timeline.x + hover_layout.timeline.width / 2
mouse_y = hover_layout.timeline.y
key_bindings["adwisp-mouse-move"].callback()
assert_equal(observed_state.preview_visible, true,
    "valid thumbfast metadata should activate the preview before export")
key_bindings["adwisp-thumbnail-export"].callback()
assert_equal(commands[#commands][1], "show-text",
    "successful thumbnail export should show confirmation")
local exported_filename = commands[#commands][2]:match("exported (.+)$")
assert_true(type(exported_filename) == "string",
    "successful thumbnail export should report its filename")
local exported = assert(io.open(exported_filename, "rb"))
local bitmap = exported:read("*a")
exported:close()
assert_equal(bitmap:sub(1, 2), "BM", "export shortcut should write a BMP file")
assert_equal(#bitmap, 58, "one-pixel BMP should contain its header and pixel")
assert_equal(bitmap:sub(55), fixture_pixel, "exported BMP should preserve BGRA pixels")
os.remove(exported_filename)
os.remove(fixture_path .. ".bgra")
mouse_x, mouse_y = 10, 10
key_bindings["adwisp-mouse-move"].callback()

-- A new drag replaces the previous drag instead of activating both.
mouse_x = volume_track.x + volume_track.width * 0.25
mouse_y = volume_hit.y + volume_hit.height / 2
key_bindings["adwisp-mouse-click"].callback({ event = "down" })
local volume_commands_before_switch = 0
for _, command in ipairs(commands) do
    if command[1] == "set" and command[2] == "volume" then
        volume_commands_before_switch = volume_commands_before_switch + 1
    end
end
mouse_x = layout.timeline.x + layout.timeline.width * 0.4
mouse_y = layout.timeline.y
key_bindings["adwisp-mouse-click"].callback({ event = "down" })
local seeks_before_switch_move = 0
for _, command in ipairs(commands) do
    if command[1] == "seek" then seeks_before_switch_move = seeks_before_switch_move + 1 end
end
mouse_x = volume_track.x + volume_track.width * 0.8
mouse_y = volume_hit.y + volume_hit.height / 2
key_bindings["adwisp-mouse-move"].callback()
local seeks_after_switch_move = 0
for _, command in ipairs(commands) do
    if command[1] == "seek" then seeks_after_switch_move = seeks_after_switch_move + 1 end
end
assert_true(seeks_after_switch_move > seeks_before_switch_move,
    "timeline drag should remain active after replacing volume drag")
local volume_commands_after_switch_move = 0
for _, command in ipairs(commands) do
    if command[1] == "set" and command[2] == "volume" then
        volume_commands_after_switch_move = volume_commands_after_switch_move + 1
    end
end
assert_equal(volume_commands_after_switch_move, volume_commands_before_switch,
    "timeline drag should replace volume drag")
key_bindings["adwisp-mouse-click"].callback({ event = "up" })

-- Timeline dragging should seek continuously and stop on mouse release.
mouse_x = layout.timeline.x + layout.timeline.width * 0.1
mouse_y = layout.timeline.y
key_bindings["adwisp-mouse-click"].callback({ event = "down" })
assert_equal(commands[#commands][1], "seek", "timeline drag start should seek")
assert_true(math.abs(commands[#commands][2] - 10) < 0.000001,
    "timeline drag start should seek to pointer")
mouse_x = layout.timeline.x + layout.timeline.width * 0.7
key_bindings["adwisp-mouse-move"].callback()
local movement_seek
for i = #commands, 1, -1 do
    if commands[i][1] == "seek" then
        movement_seek = commands[i]
        break
    end
end
assert_true(movement_seek ~= nil, "timeline drag movement should seek")
assert_true(math.abs(movement_seek[2] - 70) < 0.000001,
    "timeline drag should follow pointer")
key_bindings["adwisp-mouse-click"].callback({ event = "up" })
local seeks_after_release = 0
for _, command in ipairs(commands) do
    if command[1] == "seek" then seeks_after_release = seeks_after_release + 1 end
end
mouse_x = layout.timeline.x + layout.timeline.width * 0.9
key_bindings["adwisp-mouse-move"].callback()
local seeks_after_move = 0
for _, command in ipairs(commands) do
    if command[1] == "seek" then seeks_after_move = seeks_after_move + 1 end
end
assert_equal(seeks_after_move, seeks_after_release,
    "movement after timeline release should not issue another seek")


-- Hiding during a drag must cancel the interaction; showing again must not
-- resume a stale drag when the pointer moves.
script_messages["adwisp-show"]()
local drag_layout = Layout.compute(1280, 720)
mouse_x = drag_layout.timeline.x + drag_layout.timeline.width * 0.3
mouse_y = drag_layout.timeline.y
key_bindings["adwisp-mouse-click"].callback({ event = "down" })
assert_equal(commands[#commands][1], "seek", "drag setup should issue a seek")
script_messages["adwisp-hide"]()
local seeks_after_timeline_hide = 0
for _, command in ipairs(commands) do
    if command[1] == "seek" then seeks_after_timeline_hide = seeks_after_timeline_hide + 1 end
end
script_messages["adwisp-show"]()
mouse_x = drag_layout.timeline.x + drag_layout.timeline.width * 0.8
key_bindings["adwisp-mouse-move"].callback()
local seeks_after_timeline_move = 0
for _, command in ipairs(commands) do
    if command[1] == "seek" then seeks_after_timeline_move = seeks_after_timeline_move + 1 end
end
assert_equal(seeks_after_timeline_move, seeks_after_timeline_hide,
    "mouse movement after hide/show should not continue a stale timeline drag")
key_bindings["adwisp-mouse-click"].callback({ event = "up" })

-- Hiding during a volume drag should likewise cancel stale updates.
mouse_x = drag_layout.volume.track.x + drag_layout.volume.track.width * 0.3
mouse_y = drag_layout.volume.hit.y + drag_layout.volume.hit.height / 2
key_bindings["adwisp-mouse-click"].callback({ event = "down" })
script_messages["adwisp-hide"]()
local volume_sets_after_hide = 0
for _, command in ipairs(commands) do
    if command[1] == "set" and command[2] == "volume" then
        volume_sets_after_hide = volume_sets_after_hide + 1
    end
end
script_messages["adwisp-show"]()
mouse_x = drag_layout.volume.track.x + drag_layout.volume.track.width * 0.8
key_bindings["adwisp-mouse-move"].callback()
local volume_sets_after_move = 0
for _, command in ipairs(commands) do
    if command[1] == "set" and command[2] == "volume" then
        volume_sets_after_move = volume_sets_after_move + 1
    end
end
assert_equal(volume_sets_after_move, volume_sets_after_hide,
    "mouse movement after hide/show should not continue a stale volume drag")
key_bindings["adwisp-mouse-click"].callback({ event = "up" })

-- Failed theme reloads must preserve the last successfully loaded palette.
local valid_theme_path = os.tmpname()
local valid_theme_file = assert(io.open(valid_theme_path, "w"))
valid_theme_file:write("accent=#010203\n")
valid_theme_file:close()
option_fixture.theme_file = valid_theme_path
script_messages["adwisp-reload-theme"]()
assert_true(overlays[1].data:find("&H030201&", 1, true) ~= nil,
    "valid theme reload should apply the new accent color")

local invalid_theme_path = os.tmpname()
local invalid_theme_file = assert(io.open(invalid_theme_path, "w"))
invalid_theme_file:write("accent=not-a-color\n")
invalid_theme_file:close()
option_fixture.theme_file = invalid_theme_path
script_messages["adwisp-reload-theme"]()
assert_true(overlays[1].data:find("&H030201&", 1, true) ~= nil,
    "invalid theme reload should preserve the last valid palette")

option_fixture.theme_file = valid_theme_path .. ".missing"
script_messages["adwisp-reload-theme"]()
assert_true(overlays[1].data:find("&H030201&", 1, true) ~= nil,
    "missing theme file should preserve the last valid palette")
os.remove(valid_theme_path)
os.remove(invalid_theme_path)

local updates_before_escape = overlays[1].update_count
key_bindings["adwisp-dismiss-escape"].callback()
assert_equal(overlays[1].data, "", "Escape should dismiss and clear OSD data")
assert_equal(overlays[1].update_count, updates_before_escape + 1,
    "Escape should clear the visible overlay once")

script_messages["adwisp-hide"]()
assert_equal(overlays[1].data, "", "hide message should leave OSD data cleared")
assert_equal(overlays[1].update_count, updates_before_escape + 1,
    "hiding an already dismissed overlay should be cached")
events["end-file"]()
assert_equal(overlays[1].update_count, updates_before_escape + 1,
    "clearing an already hidden OSD should be cached")

-- Verbosity controls diagnostics without changing playback behavior.
option_fixture = package.loaded["mp.options"].last_options
option_fixture.log_level = "debug"
events["file-loaded"]()
local saw_file_loaded_debug = false
for _, message in ipairs(logs.info) do
    if message:find("Adwisp [debug]: file loaded", 1, true) then
        saw_file_loaded_debug = true
    end
end
assert_true(saw_file_loaded_debug, "debug mode should log file lifecycle events")
option_fixture.log_level = "quiet"
local info_count_before_quiet = #logs.info
events["end-file"]()
assert_equal(#logs.info, info_count_before_quiet,
    "quiet mode should suppress informational and debug messages")

-- Script messages reject unexpected payloads and expose a JSON state snapshot.
local warnings_before_invalid_message = #logs.warn
script_messages["adwisp-show"]("unexpected")
assert_equal(#logs.warn, warnings_before_invalid_message + 1,
    "script messages with unexpected arguments should be rejected")
assert_equal(observed_state.visible, false,
    "invalid script-message payloads should not change UI state")
local info_before_query = #logs.info
script_messages["adwisp-query"]()
assert_equal(#logs.info, info_before_query + 1,
    "state query should emit a response even when informational logging is quiet")
assert_true(logs.info[#logs.info]:find('"visible":false', 1, true) ~= nil,
    "state query should return a JSON snapshot of UI state")
assert_true(logs.info[#logs.info]:find('"speed":', 1, true) ~= nil,
    "state query should include playback speed")
assert_true(logs.info[#logs.info]:find('"loop_file":', 1, true) ~= nil,
    "state query should include file-loop state")

-- Optional idle hiding uses cancellable timers and a finite fade sequence.
option_fixture.idle_hide_timeout = 2
option_fixture.fade_duration = 0.12
local timers_before_idle = #timers
script_messages["adwisp-show"]()
assert_equal(observed_state.opacity, 0,
    "showing with idle-hide enabled should begin at transparent opacity")
local first_idle_timer = timers[timers_before_idle + 1]
for _ = 1, 6 do
    timers[#timers].callback()
end
assert_equal(observed_state.opacity, 1,
    "fade-in should reach full opacity after its finite steps")
assert_true(first_idle_timer.killed == false,
    "idle timer should remain active after the fade-in completes")
key_bindings["adwisp-focus-next"].callback()
assert_true(first_idle_timer.killed,
    "user interaction should cancel the previous idle timer")
first_idle_timer.callback()
assert_equal(observed_state.visible, true,
    "a stale idle timer must not hide the interface after interaction")
local renewed_idle_timer = timers[#timers]
renewed_idle_timer.callback()
assert_equal(observed_state.visible, true,
    "idle timeout should start a fade rather than hide immediately")
local stale_fade_timer = timers[#timers]
stale_fade_timer.callback()
assert_true(observed_state.opacity < 1 and observed_state.opacity > 0,
    "fade-out should reduce opacity in visible intermediate steps")
key_bindings["adwisp-focus-next"].callback()
assert_equal(observed_state.opacity, 1,
    "interaction during fade-out should restore full opacity")
stale_fade_timer.callback()
assert_equal(observed_state.visible, true,
    "a cancelled fade callback must not hide the active interface")
local final_idle_timer = timers[#timers]
final_idle_timer.callback()
for _ = 1, 6 do
    timers[#timers].callback()
end
assert_equal(observed_state.visible, false,
    "the OSD should hide after the complete idle fade-out")
assert_equal(observed_state.opacity, 1,
    "hidden OSD should reset opacity for the next show")

-- An active mouse drag suppresses the idle timeout until the pointer is released.
script_messages["adwisp-show"]()
for _ = 1, 6 do
    timers[#timers].callback()
end
mouse_x, mouse_y = 500, 600
key_bindings["adwisp-mouse-click"].callback({ event = "down" })
local drag_idle_timer = timers[#timers]
drag_idle_timer.callback()
assert_equal(observed_state.visible, true,
    "idle timeout should not hide the OSD during an active drag")
key_bindings["adwisp-mouse-click"].callback({ event = "up" })
script_messages["adwisp-hide"]()
assert_equal(observed_state.visible, false,
    "explicit hide should still dismiss the OSD after dragging")


-- Shutdown must invalidate pending callbacks and release OSD, drag, and
-- thumbfast state without relying on an end-file event.
script_messages["adwisp-show"]()
for _ = 1, 6 do timers[#timers].callback() end
thumbfast_payload = { width = 160, height = 90, disabled = false, available = true }
script_messages["thumbfast-info"]("{}")
local shutdown_layout = Layout.compute(1280, 720)
mouse_x = shutdown_layout.timeline.x + shutdown_layout.timeline.width / 2
mouse_y = shutdown_layout.timeline.y
key_bindings["adwisp-mouse-move"].callback()
assert_equal(observed_state.preview_visible, true,
    "shutdown setup should activate a thumbfast preview")
key_bindings["adwisp-focus-next"].callback()
key_bindings["adwisp-mouse-click"].callback({ event = "down" })
observers["time-pos"].callback("time-pos", 42)
local pending_position_timer = timers[#timers]
local updates_before_shutdown = overlays[1].update_count
events["shutdown"]()
assert_true(pending_position_timer.killed,
    "shutdown should cancel the pending playback timer")
assert_equal(observed_state.visible, false, "shutdown should mark the OSD hidden")
assert_equal(observed_state.opacity, 1, "shutdown should reset opacity")
assert_equal(observed_state.preview_visible, false,
    "shutdown should clear thumbfast preview state")
assert_equal(observed_state.hover_target, nil, "shutdown should clear hover state")
assert_equal(observed_state.focus_target, nil, "shutdown should clear keyboard focus")
assert_equal(overlays[1].data, "", "shutdown should clear the OSD overlay")
assert_equal(commands[#commands][1], "script-message-to",
    "shutdown should send a clear message to active thumbfast previews")
assert_equal(commands[#commands][3], "clear",
    "shutdown should clear the thumbfast preview")
pending_position_timer.callback()
assert_equal(overlays[1].update_count, updates_before_shutdown + 1,
    "a stale playback timer must not redraw after shutdown")

-- Shutdown must also be safe when the optional thumbfast adapter is unavailable.
thumbfast_payload = nil
script_messages["thumbfast-info"]("{}")
local commands_before_shutdown_without_thumbfast = #commands
events["shutdown"]()
assert_equal(observed_state.visible, false,
    "shutdown without thumbfast should leave the OSD hidden")
assert_equal(overlays[1].data, "",
    "shutdown without thumbfast should leave the overlay cleared")
for index = commands_before_shutdown_without_thumbfast + 1, #commands do
    assert_true(not (commands[index][1] == "script-message-to"
        and commands[index][2] == "thumbfast" and commands[index][3] == "clear"),
        "shutdown without thumbfast should not send adapter commands")
end


print("All mocked mpv API tests passed.")
