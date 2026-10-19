package.path = "./?.lua;./?/init.lua;" .. package.path

local observers = {}
local events = {}
local key_bindings = {}
local script_messages = {}
local commands = {}
local overlays = {}
local mouse_x, mouse_y = 0, 0
local thumbfast_payload

local mp = {
    get_script_directory = function() return "." end,
    observe_property = function(name, property_type, callback)
        observers[name] = { type = property_type, callback = callback }
    end,
    register_event = function(name, callback)
        events[name] = callback
    end,
    add_key_binding = function(key, name, callback)
        key_bindings[name] = { key = key, callback = callback }
    end,
    register_script_message = function(name, callback)
        script_messages[name] = callback
    end,
    commandv = function(...)
        commands[#commands + 1] = { ... }
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
    get_mouse_pos = function()
        return mouse_x, mouse_y
    end,
    msg = { info = function() end, warn = function() end },
}

package.loaded.mp = mp
package.loaded["mp.utils"] = {
    parse_json = function() return thumbfast_payload end,
}
package.loaded["mp.options"] = {
    read_options = function(options)
        assert(options.seek_step == 5, "default seek step should be five seconds")
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
assert_true(observers.pause ~= nil, "pause property should be observed")
assert_true(observers["time-pos"] ~= nil, "playback position should be observed")
assert_true(observers["osd-dimensions"] ~= nil, "OSD dimensions should be observed")
assert_true(events["file-loaded"] ~= nil, "file-loaded event should be registered")
assert_true(events["end-file"] ~= nil, "end-file event should be registered")
assert_true(key_bindings["adwisp-toggle"] ~= nil, "toggle key should be registered")
assert_true(key_bindings["adwisp-dismiss-escape"] ~= nil, "Escape dismiss shortcut should be registered")
assert_true(key_bindings["adwisp-mouse-click"] ~= nil, "mouse click should be registered")
assert_true(key_bindings["adwisp-mouse-move"] ~= nil, "mouse move should be registered")
assert_true(key_bindings["adwisp-volume-up"] ~= nil, "volume-up shortcut should be registered")
assert_true(key_bindings["adwisp-volume-down"] ~= nil, "volume-down shortcut should be registered")
assert_true(key_bindings["adwisp-playlist-prev"] ~= nil, "playlist-prev shortcut should be registered")
assert_true(key_bindings["adwisp-playlist-next"] ~= nil, "playlist-next shortcut should be registered")
assert_true(key_bindings["adwisp-mute-toggle"] ~= nil, "mute toggle shortcut should be registered")
assert_true(script_messages["adwisp-show"] ~= nil, "show message should be registered")
assert_true(script_messages["thumbfast-info"] ~= nil, "thumbfast info message should be registered")

-- Property callbacks should update state and safely render while the UI is hidden.
observers.pause.callback("pause", true)
observers["time-pos"].callback("time-pos", 12)
observers.duration.callback("duration", 60)
observers["media-title"].callback("media-title", "Test video")
assert_equal(overlays[1].update_count, 1,
    "hidden OSD should clear its initial empty overlay only once")

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

key_bindings["adwisp-playlist-prev"].callback()
assert_equal(commands[#commands][1], "playlist-prev", "Ctrl+Left should go to previous playlist item")
assert_equal(commands[#commands][2], "weak", "previous shortcut should use weak mode")
key_bindings["adwisp-playlist-next"].callback()
assert_equal(commands[#commands][1], "playlist-next", "Ctrl+Right should go to next playlist item")
assert_equal(commands[#commands][2], "weak", "next shortcut should use weak mode")

-- Keyboard volume shortcuts should adjust by the configured step and unmute.
key_bindings["adwisp-volume-down"].callback()
assert_equal(commands[#commands - 1][1], "set", "volume-down should set volume")
assert_equal(commands[#commands - 1][2], "volume", "volume-down should target volume")
assert_equal(commands[#commands - 1][3], 95, "volume-down should reduce volume by five")
assert_equal(commands[#commands][2], "mute", "volume adjustment should clear mute")
assert_equal(commands[#commands][3], "no", "volume adjustment should unmute playback")
key_bindings["adwisp-volume-up"].callback()
assert_equal(commands[#commands - 1][3], 100, "volume-up should increase volume by five")

-- Mouse clicks should seek proportionally along the shared timeline geometry.
local Layout = require "core.layout"
local layout = Layout.compute(1280, 720)
mouse_x = layout.timeline.x + layout.timeline.width / 2
mouse_y = layout.timeline.y
key_bindings["adwisp-mouse-click"].callback()
assert_equal(commands[#commands][1], "seek", "timeline click should issue seek")
assert_equal(commands[#commands][2], 50, "timeline midpoint should seek to 50 percent")
assert_equal(commands[#commands][3], "absolute-percent",
    "timeline click should use absolute-percent mode")

-- Clicking the playback control should toggle pause.
mouse_x = layout.playback.x + 5
mouse_y = layout.playback.y + 5
key_bindings["adwisp-mouse-click"].callback()
assert_equal(commands[#commands][1], "cycle", "playback click should issue cycle")
assert_equal(commands[#commands][2], "pause", "playback click should target pause")

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

-- Clicking the volume control should set volume proportionally and unmute.
mouse_x = layout.volume.x + layout.volume.width * 0.75
mouse_y = layout.volume.y + 5
key_bindings["adwisp-mouse-click"].callback()
assert_equal(commands[#commands - 1][1], "set", "volume click should set volume")
assert_equal(commands[#commands - 1][2], "volume", "volume click should target volume")
assert_equal(commands[#commands - 1][3], 75, "volume click should map to percentage")
assert_equal(commands[#commands][1], "set", "volume click should ensure audio is unmuted")
assert_equal(commands[#commands][2], "mute", "volume click should target mute state")
assert_equal(commands[#commands][3], "no", "volume click should unmute playback")

-- Mouse-down starts volume dragging and mouse movement updates the slider.
mouse_x = layout.volume.x + layout.volume.width * 0.2
mouse_y = layout.volume.y + 5
key_bindings["adwisp-mouse-click"].callback({ event = "down" })
assert_equal(commands[#commands - 1][3], 20, "drag start should set volume at pointer")
mouse_x = layout.volume.x + layout.volume.width * 0.6
key_bindings["adwisp-mouse-move"].callback()
assert_equal(commands[#commands - 1][3], 60, "drag movement should update volume")
key_bindings["adwisp-mouse-click"].callback({ event = "up" })
local after_drag = #commands
mouse_x = layout.volume.x + layout.volume.width * 0.9
key_bindings["adwisp-mouse-move"].callback()
assert_equal(#commands, after_drag,
    "mouse movement after drag release should not continue changing volume")

-- Volume values should clamp at both ends of the slider.
mouse_x = layout.volume.x
mouse_y = layout.volume.y + 5
key_bindings["adwisp-mouse-click"].callback()
assert_equal(commands[#commands - 1][3], 0, "volume below slider should clamp to zero")
mouse_x = layout.volume.x + layout.volume.width
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

-- thumbfast supplies thumbnail dimensions; Adwisp requests previews only on timeline hover.
thumbfast_payload = { width = 160, height = 90, disabled = false, available = true }
script_messages["thumbfast-info"]("{}")
mouse_x = hover_layout.timeline.x + hover_layout.timeline.width / 2
mouse_y = hover_layout.timeline.y
key_bindings["adwisp-mouse-move"].callback()
assert_equal(commands[#commands][1], "script-message-to",
    "timeline hover should send a thumbfast script message")
assert_equal(commands[#commands][2], "thumbfast", "preview should target thumbfast")
assert_equal(commands[#commands][3], "thumb", "preview should use thumbfast thumb command")
assert_equal(commands[#commands][4], 30, "timeline midpoint should preview midpoint time")
assert_true(type(commands[#commands][5]) == "number", "preview should provide x coordinate")
assert_true(type(commands[#commands][6]) == "number", "preview should provide y coordinate")

mouse_x = 10
mouse_y = 10
key_bindings["adwisp-mouse-move"].callback()
assert_equal(commands[#commands][1], "script-message-to",
    "leaving timeline should send a thumbfast clear message")
assert_equal(commands[#commands][2], "thumbfast", "clear should target thumbfast")
assert_equal(commands[#commands][3], "clear", "leaving timeline should clear preview")

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


key_bindings["adwisp-dismiss-escape"].callback()
assert_equal(overlays[1].data, "", "Escape should dismiss and clear OSD data")

script_messages["adwisp-show"]()
assert_true(overlays[1].data ~= "", "show message should restore visible OSD")
script_messages["adwisp-hide"]()
assert_equal(overlays[1].data, "", "hide message should clear OSD data")
assert_equal(overlays[1].update_count, 6, "hide message should update overlay")
events["end-file"]()
assert_equal(overlays[1].update_count, 6, "clearing an already hidden OSD should be cached")

print("All mocked mpv API tests passed.")
