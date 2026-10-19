package.path = "./?.lua;./?/init.lua;" .. package.path

local observers = {}
local events = {}
local key_bindings = {}
local script_messages = {}
local commands = {}
local overlays = {}
local mouse_x, mouse_y = 0, 0

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
    msg = { info = function() end },
}

package.loaded.mp = mp
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
assert_true(key_bindings["adwisp-mouse-click"] ~= nil, "mouse click should be registered")
assert_true(script_messages["adwisp-show"] ~= nil, "show message should be registered")

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

-- Clicking the volume control should toggle mute.
mouse_x = layout.volume.x + 5
mouse_y = layout.volume.y + 5
key_bindings["adwisp-mouse-click"].callback()
assert_equal(commands[#commands][1], "cycle", "volume click should issue cycle")
assert_equal(commands[#commands][2], "mute", "volume click should toggle mute")

-- Clicks outside controls should not issue commands.
local command_count = #commands
mouse_x = 10
mouse_y = 10
key_bindings["adwisp-mouse-click"].callback()
assert_equal(#commands, command_count, "click outside controls should be ignored")

script_messages["adwisp-hide"]()
assert_equal(overlays[1].data, "", "hide message should clear OSD data")
assert_equal(overlays[1].update_count, 3, "hide message should update overlay")
events["end-file"]()
assert_equal(overlays[1].update_count, 3, "clearing an already hidden OSD should be cached")

print("All mocked mpv API tests passed.")
