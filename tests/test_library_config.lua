package.path = "./?.lua;./?/init.lua;" .. package.path

local LibraryConfig = require "core.library_config"

assert(LibraryConfig.is_valid_path("/media/Videos"), "absolute POSIX paths should be accepted")
assert(LibraryConfig.is_valid_path("C:\\Videos"), "absolute Windows drive paths should be accepted")
assert(LibraryConfig.is_valid_path("\\\\server\\share"), "UNC paths should be accepted")
assert(not LibraryConfig.is_valid_path("Videos"), "relative paths should be rejected")
assert(not LibraryConfig.is_valid_path("https://example.com"), "remote URLs should be rejected")
assert(not LibraryConfig.is_valid_path("/media/Bad\nFolder"), "control characters should be rejected")

local normalized = LibraryConfig.normalize({
    version = 1,
    roots = { "/media/Movies", "/media/Movies", "relative", "/mnt/USB" },
    favorites = { "/media/Movies/Drama", "/media/Movies/Drama", "https://bad" },
})
assert(#normalized.roots == 2 and normalized.roots[2] == "/mnt/USB",
    "normalization should remove invalid and duplicate roots")
assert(#normalized.favorites == 1,
    "normalization should remove invalid and duplicate favorites")
assert(#LibraryConfig.normalize({ version = 2, roots = { "/media" } }).roots == 0,
    "unsupported versions should fail safely")

local config, added = LibraryConfig.add_root(normalized, "/media/Anime")
assert(added and #config.roots == 3, "a valid root should be added")
local duplicate, duplicate_added = LibraryConfig.add_root(config, "/media/Anime")
assert(not duplicate_added and #duplicate.roots == 3,
    "duplicate roots should not be added")
local invalid, invalid_added = LibraryConfig.add_root(config, "relative")
assert(not invalid_added and #invalid.roots == 3, "invalid roots should be rejected")
local removed, did_remove = LibraryConfig.remove_root(config, "/mnt/USB")
assert(did_remove and #removed.roots == 2, "configured roots should be removable")

local pinned, did_pin = LibraryConfig.toggle_favorite(removed, "/media/Movies/Drama")
assert(did_pin and #pinned.favorites == 2, "folders should be pinnable")
local unpinned, did_unpin = LibraryConfig.toggle_favorite(pinned, "/media/Movies/Drama")
assert(not did_unpin and #unpinned.favorites == 1,
    "toggling an existing favorite should unpin it")

local locations = LibraryConfig.locations({
    roots = { "/media/Movies" },
    favorites = { "/media/Movies", "/media/Movies/Drama" },
})
assert(#locations == 2 and locations[1].location_type == "root"
    and locations[2].location_type == "favorite",
    "location list should deduplicate roots and favorites while preserving their type")
assert(locations[2].path == "/media/Movies/Drama",
    "favorite entries should retain their original path")

local store = { payload = { version = 1, roots = { "/media/Movies" },
    favorites = { "/media/Movies/Drama" } }, raw = '{"version":1}', size = 20 }
local deps = {
    file_info = function(path)
        if path == "/library.json" then return { is_file = true, size = store.size } end
    end,
    open = function(_, mode)
        if mode == "rb" then
            return { read = function() return store.raw end, close = function() return true end }
        end
        return {
            write = function(_, value) store.written = value; return true end,
            close = function() return true end,
        }
    end,
    parse_json = function() return store.payload end,
    format_json = function(value) store.saved = value; return "encoded-library" end,
    rename = function(source, destination)
        store.renamed = { source, destination }
        return true
    end,
    remove = function(path) store.removed = path; return true end,
}
local loaded = LibraryConfig.load("/library.json", deps)
assert(#loaded.roots == 1 and #loaded.favorites == 1,
    "valid local configuration should load")
store.size = 129 * 1024
assert(#LibraryConfig.load("/library.json", deps).roots == 0,
    "oversized configuration should be rejected before parsing")
store.size = 20
assert(LibraryConfig.save("/library.json", normalized, deps),
    "configuration should save through a temporary file and atomic rename")
assert(store.written == "encoded-library"
    and store.renamed[1] == "/library.json.tmp"
    and store.renamed[2] == "/library.json",
    "save should write a temporary file and atomically replace the destination")
assert(store.saved.version == 1 and #store.saved.roots == 2,
    "saved payload should be versioned and normalized")

local failed = {
    open = function() return nil end,
    format_json = deps.format_json,
    rename = deps.rename,
    remove = deps.remove,
}
local saved, err = LibraryConfig.save("/library.json", normalized, failed)
assert(saved == false and type(err) == "string",
    "storage failures should be reported")

print("All library-config tests passed.")
