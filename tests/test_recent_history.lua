package.path = "./?.lua;./?/init.lua;" .. package.path

local History = require "core.recent_history"

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error((message or "values differ") .. ": expected " .. tostring(expected)
            .. ", got " .. tostring(actual), 2)
    end
end

local function assert_true(value, message)
    if not value then error(message or "expected true", 2) end
end

assert_true(History.is_local_path("/home/user/Video.mkv"),
    "absolute Unix paths should be accepted")
assert_true(History.is_local_path("C:\\Media\\Video.mkv"),
    "Windows drive paths should be accepted")
assert_true(History.is_local_path("relative/video.mkv"),
    "relative local paths should be accepted")
assert_equal(History.is_local_path("https://example.test/video.mkv"), false,
    "network URLs should not enter local history")
assert_equal(History.is_local_path("rtsp://example.test/live"), false,
    "stream URLs should not enter local history")

local items = {}
items = History.record(items, "/media/one.mkv", "One", 2)
items = History.record(items, "/media/two.mkv", "Two", 2)
items = History.record(items, "/media/three.mkv", "Three", 2)
assert_equal(#items, 2, "history should respect its configured limit")
assert_equal(items[1].path, "/media/three.mkv", "new entries should be most recent")
assert_equal(items[2].path, "/media/two.mkv", "older entries should follow new entries")
items = History.record(items, "/media/two.mkv", "Two updated", 2)
assert_equal(#items, 2, "reopening an item should not duplicate it")
assert_equal(items[1].path, "/media/two.mkv", "reopened items should move to the top")
assert_equal(items[1].title, "Two updated", "reopened items should refresh their title")
local unchanged, recorded = History.record(items, "https://example.test/stream", "Stream", 2)
assert_equal(recorded, false, "network URLs should not be recorded")
assert_equal(#unchanged, 2, "rejected URLs should not change existing history")

local normalized = History.normalize({
    version = 1,
    items = {
        { path = "/a.mkv", title = "A" },
        { path = "/a.mkv", title = "Duplicate" },
        { path = "https://example.test/x", title = "Remote" },
        { path = "/b.mkv", title = "B\nTitle" },
        { path = 123, title = "Invalid" },
    },
}, 10)
assert_equal(#normalized, 2, "loading should discard duplicates and invalid paths")
assert_equal(normalized[2].title, "B Title", "titles should be sanitized")
local path_title = History.normalize({
    version = 1,
    items = { { path = "/private/video.mkv", title = "/private/video.mkv" } },
}, 1)
assert_equal(path_title[1].title, "video.mkv",
    "path-like media titles should not expose full paths in the menu")
assert_equal(#History.normalize({ version = 3, items = normalized }, 10), 0,
    "unsupported history versions should be ignored")
assert_equal(History.normalize({ version = 1, items = {
    { path = "/legacy.mkv", title = "Legacy", position = 75, duration = 100 },
} }, 10)[1].position, nil,
    "version-one history should migrate without trusting progress fields")

local progress_items = History.record({}, "/resume.mkv", "Resume", 10)
local recorded
progress_items, recorded = History.update_progress(progress_items,
    "/resume.mkv", 75, 200, 10)
assert_true(recorded, "known local history entries should accept progress updates")
assert_equal(progress_items[1].position, 75, "progress position should be stored")
assert_equal(progress_items[1].duration, 200, "progress duration should be stored")
assert_equal(History.resume_position(progress_items[1]), 75,
    "resume should expose a useful position")
progress_items = History.record(progress_items, "/resume.mkv", "Resume renamed", 10)
assert_equal(progress_items[1].position, 75,
    "recording a reopened file should preserve its resume position")
progress_items, recorded = History.update_progress(progress_items,
    "/resume.mkv", 192, 200, 10)
assert_true(recorded, "completion should update an existing entry")
assert_equal(progress_items[1].position, nil,
    "completed playback should clear the resume marker")
assert_equal(History.resume_position(progress_items[1]), nil,
    "completed playback should not offer a resume position")
local _, updated = History.update_progress(progress_items,
    "https://example.test/stream", 60, 100, 10)
assert_equal(updated, false, "network progress must be rejected")
local _, invalid_progress = History.update_progress(progress_items,
    "/resume.mkv", math.huge, 200, 10)
assert_equal(invalid_progress, false, "non-finite progress must be rejected")
assert_equal(History.resume_position({ position = 12, duration = 200 }), nil,
    "tiny playback starts should not be offered as resume points")

local store = {
    raw = "stored-history",
    payload = { version = 2, items = {
        { path = "/saved/one.mkv", title = "Saved One", position = 42, duration = 100 },
        { path = "/saved/two.mkv", title = "Saved Two" },
    } },
    written = nil,
    renamed = nil,
    removed = nil,
    size = 14,
}
local deps = {
    file_info = function(path)
        if path == "/history.json" and store.raw then
            return { is_file = true, size = store.size }
        end
        return nil
    end,
    open = function(_, mode)
        if mode == "rb" then
            return {
                read = function() return store.raw end,
                close = function() return true end,
            }
        end
        return {
            write = function(_, value) store.written = value; return true end,
            close = function() return true end,
        }
    end,
    parse_json = function() return store.payload end,
    format_json = function(payload)
        store.saved_payload = payload
        return "encoded-history"
    end,
    rename = function(source, destination)
        store.renamed = { source, destination }
        return true
    end,
    remove = function(path)
        store.removed = path
        return true
    end,
}

local loaded = History.load("/history.json", 10, deps)
assert_equal(#loaded, 2, "valid history should load")
assert_equal(loaded[1].path, "/saved/one.mkv", "history order should be retained")
store.size = 600 * 1024
assert_equal(#History.load("/history.json", 10, deps), 0,
    "oversized history files should be rejected before parsing")
store.size = 14
store.payload = { version = 99, items = loaded }
assert_equal(#History.load("/history.json", 10, deps), 0,
    "unsupported stored versions should not be loaded")

loaded[1].position, loaded[1].duration = 42, 100
store.payload = { version = 2, items = loaded }
assert_true(History.save("/history.json", loaded, 10, deps),
    "history should save through a temporary file and rename")
assert_equal(store.written, "encoded-history", "the encoded payload should be written")
assert_equal(store.renamed[1], "/history.json.tmp", "save should use a sibling temporary file")
assert_equal(store.renamed[2], "/history.json", "save should atomically replace the history file")
assert_equal(store.saved_payload.version, 2, "saved history should use the progress-aware version")
assert_equal(store.saved_payload.items[1].position, 42,
    "saving history should preserve playback progress")

assert_true(History.clear("/history.json", deps), "history should be removable")
assert_equal(store.removed, "/history.json", "clear should remove only the configured history file")
store.raw = nil
store.removed = nil
assert_true(History.clear("/history.json", deps),
    "clearing an already absent history file should be harmless")
assert_equal(store.removed, nil, "an absent history file should not trigger a remove call")

print("Recent history tests passed.")
