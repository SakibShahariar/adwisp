package.path = "./?.lua;./?/init.lua;" .. package.path

local VideoLibrary = require "core.video_library"

assert(VideoLibrary.is_supported_video("movie.MKV"), "video extensions should be case-insensitive")
assert(VideoLibrary.is_supported_video("clip.webm"), "WebM should be supported")
assert(not VideoLibrary.is_supported_video("cover.jpg"), "image files should not enter the video library")
assert(not VideoLibrary.is_supported_video("notes.txt"), "unrelated files should be filtered")
assert(not VideoLibrary.is_supported_video("no-extension"), "extensionless files should be filtered")

local filesystem = {
    ["/media"] = { is_dir = true },
    ["/media/Films"] = { is_dir = true },
    ["/media/films"] = { is_dir = true },
    ["/media/Linked"] = { is_dir = true }, -- Simulated directory symlink target; never recursively traversed.
    ["/media/a.mkv"] = { is_file = true, size = 1024, mtime = 200 },
    ["/media/B.MP4"] = { is_file = true, size = 2048, mtime = 300 },
    ["/media/photo.png"] = { is_file = true, size = 20 },
    ["/media/broken.mkv"] = false,
}
local readdir_calls = 0
local names = {
    "photo.png", "B.MP4", "Films", "a.mkv", "broken.mkv",
    ".", "..", "sub/escape.mkv", "films", "Linked",
}
local deps = {
    file_info = function(path) return filesystem[path] end,
    readdir = function(path, filter)
        readdir_calls = readdir_calls + 1
        assert(path == "/media", "scan should enumerate only the requested directory")
        assert(filter == "normal", "scan should request normal filesystem entries only")
        return names
    end,
    join_path = function(parent, name) return parent .. "/" .. name end,
    split_path = function(path)
        if path == "/" then return "/", "" end
        local parent = path:match("^(.*)/[^/]+$")
        if parent == "" then parent = "/" end
        return parent or path, path:match("([^/]+)$") or path
    end,
}

local scan = assert(VideoLibrary.begin_scan("/media", deps, 100))
assert(#scan.names == 7, "dot entries and unsafe path names should be discarded")
assert(scan.done == false, "directory scan should begin incrementally")
local done = VideoLibrary.scan_chunk(scan, deps, 2)
assert(done == false and scan.next_index == 3,
    "scan chunks should process only the requested number of entries")
done = VideoLibrary.scan_chunk(scan, deps, 2)
assert(done == false, "scan should remain pending while candidates remain")
done = VideoLibrary.scan_chunk(scan, deps, 2)
assert(done == false, "directory symlink target should be handled as a normal bounded entry")
done = VideoLibrary.scan_chunk(scan, deps, 2)
assert(done == true and scan.done == true, "scan should finish after bounded chunks")

assert(#scan.entries == 5, "only directories and supported video files should be retained")
assert(scan.entries[1].kind == "directory" and scan.entries[1].name == "Films",
    "directories should sort before video files and sort case-insensitively")
assert(scan.entries[2].kind == "directory" and scan.entries[2].name == "films",
    "directory sort ties should be deterministic")
assert(scan.entries[3].kind == "directory" and scan.entries[3].name == "Linked",
    "directory symlink targets should be shown as navigable folders")
assert(scan.entries[4].name == "a.mkv" and scan.entries[5].name == "B.MP4",
    "video entries should sort by displayed filename")
assert(readdir_calls == 1,
    "the model should never recurse into directory symlink targets during a parent scan")
assert(scan.entries[4].size == 1024 and scan.entries[4].mtime == 200,
    "available metadata should be retained")
assert(VideoLibrary.selection(scan, 4).path == "/media/a.mkv",
    "selection should map to the original full path")
assert(VideoLibrary.selection(scan, 99) == nil,
    "out-of-range selections should return nil")

local limited = assert(VideoLibrary.begin_scan("/media", deps, 3))
assert(limited.truncated and #limited.names == 3,
    "large folders should cap metadata processing and report truncation")
assert(VideoLibrary.scan_chunk(limited, deps, 10) == true,
    "limited scan should finish")
assert(#limited.entries <= 3, "limited scan should never process more than the configured cap")

local parent = VideoLibrary.parent_path("/media/Films", deps)
assert(parent == "/media", "parent navigation should use the platform path helper")
assert(VideoLibrary.parent_path("/", deps) == nil,
    "filesystem root should not navigate above itself")
assert(VideoLibrary.begin_scan("https://example.com", deps) == nil,
    "remote URLs must not be accepted as local library roots")
assert(VideoLibrary.begin_scan("/missing", deps) == nil,
    "missing directories should fail safely")
assert(VideoLibrary.begin_scan("/media/a.mkv", deps) == nil,
    "files must not be accepted as directories")

local inaccessible = {
    file_info = deps.file_info,
    join_path = deps.join_path,
    readdir = function() return nil, "permission denied" end,
}
assert(VideoLibrary.begin_scan("/media", inaccessible) == nil,
    "unreadable directories should return an error")
assert(VideoLibrary.scan_chunk({}, deps, 5) == true,
    "invalid scan state should fail safely")

local view_entries = {
    { name = "Movies", kind = "directory" },
    { name = "Winter 1080p.mkv", kind = "video", size = 400, mtime = 100 },
    { name = "winter 4K.mkv", kind = "video", size = 900, mtime = 300 },
    { name = "Winter unknown.mkv", kind = "video" },
    { name = "Summer 1080p.mkv", kind = "video", size = 200, mtime = 200 },
}
local matching = VideoLibrary.view(view_entries, "WINTER 1080p", "name")
assert(#matching == 1 and matching[1] == view_entries[2],
    "multi-token search should match filenames and preserve source references")
local recent = VideoLibrary.view(view_entries, "", "recent")
assert(recent[1] == view_entries[1] and recent[2] == view_entries[3]
    and recent[3] == view_entries[5] and recent[4] == view_entries[2]
    and recent[5] == view_entries[4], "recent sort should put newest known timestamps first")
local summary = VideoLibrary.summary(view_entries, false, false)
assert(summary.videos == 4 and summary.folders == 1 and summary.complete,
    "summary should count only the supplied completed snapshot")
local partial = VideoLibrary.summary(view_entries, false, true)
assert(partial.videos == 4 and partial.folders == 1 and not partial.complete and partial.truncated,
    "truncated snapshots must be marked partial")
local loading = VideoLibrary.summary(view_entries, true, false)
assert(loading.loading and not loading.complete, "loading counts must not be presented as final")
local modified = VideoLibrary.view(view_entries, "", "modified")
assert(modified[1] == view_entries[1]
    and modified[2] == view_entries[3] and modified[3] == view_entries[5]
    and modified[4] == view_entries[2] and modified[5] == view_entries[4],
    "modified sort should be newest-first, directories first, and missing metadata last")
local largest = VideoLibrary.view(view_entries, "", "size")
assert(largest[1] == view_entries[1]
    and largest[2] == view_entries[3] and largest[3] == view_entries[2]
    and largest[4] == view_entries[5] and largest[5] == view_entries[4],
    "size sort should be largest-first and put missing sizes last")
assert(#VideoLibrary.view(view_entries, "not present", "name") == 0,
    "unmatched search should return an empty view")
local cleared_view = VideoLibrary.view(view_entries, "  ", "name")
assert(#cleared_view == #view_entries and cleared_view[1] == view_entries[1],
    "clearing search should restore all entries")
assert(view_entries[2].name == "Winter 1080p.mkv" and view_entries[2].index == nil,
    "search and sorting must not mutate source entries")

print("All video-library tests passed.")
