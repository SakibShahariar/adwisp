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
assert_equal(#History.normalize({ version = 2, items = normalized }, 10), 0,
    "unsupported history versions should be ignored")

local store = {
    raw = "stored-history",
    payload = { version = 1, items = {
        { path = "/saved/one.mkv", title = "Saved One" },
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
    open = function(path, mode)
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

store.payload = { version = 1, items = loaded }
assert_true(History.save("/history.json", loaded, 10, deps),
    "history should save through a temporary file and rename")
assert_equal(store.written, "encoded-history", "the encoded payload should be written")
assert_equal(store.renamed[1], "/history.json.tmp", "save should use a sibling temporary file")
assert_equal(store.renamed[2], "/history.json", "save should atomically replace the history file")
assert_equal(store.saved_payload.version, 1, "saved history should carry a version")

assert_true(History.clear("/history.json", deps), "history should be removable")
assert_equal(store.removed, "/history.json", "clear should remove only the configured history file")
store.raw = nil
store.removed = nil
assert_true(History.clear("/history.json", deps),
    "clearing an already absent history file should be harmless")
assert_equal(store.removed, nil, "an absent history file should not trigger a remove call")

print("Recent history tests passed.")
