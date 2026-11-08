package.path = "./?.lua;./?/init.lua;" .. package.path

local Cache = require "core.video_thumbnail_cache"

local function assert_true(value, message)
    assert(value, message)
end

local function assert_equal(actual, expected, message)
    assert(actual == expected, string.format("%s (expected %s, got %s)",
        message, tostring(expected), tostring(actual)))
end

local removed = {}
local cache = Cache.new(2, 200, {
    remove = function(path)
        removed[#removed + 1] = path
        return true
    end,
})
local key_a = assert(Cache.key("/media/a.mkv", 100, 10))
local key_b = assert(Cache.key("/media/b.mkv", 200, 20))
local key_c = assert(Cache.key("/media/c.mkv", 300, 30))

assert_equal(Cache.key("/media/a.mkv", nil, 10), nil,
    "cache keys require file size metadata")
assert_equal(Cache.key("/media/a.mkv", 100, math.huge), nil,
    "cache keys reject non-finite modification times")
assert_equal(Cache.get(cache, key_a), nil, "new cache should miss")

assert_true(Cache.put(cache, key_a, {
    source_path = "/media/a.mkv", thumbnail_path = "/tmp/a.bgra",
    bytes = 100, width = 72, height = 36,
}), "valid thumbnail should enter cache")
assert_equal(Cache.get(cache, key_a).thumbnail_path, "/tmp/a.bgra",
    "cache hit should return the stored thumbnail path")
assert_true(Cache.put(cache, key_b, {
    source_path = "/media/b.mkv", thumbnail_path = "/tmp/b.bgra", bytes = 80,
}), "second thumbnail should enter cache")
assert_equal(Cache.get(cache, key_a).thumbnail_path, "/tmp/a.bgra",
    "cache hits should refresh least-recently-used order")
assert_true(Cache.put(cache, key_c, {
    source_path = "/media/c.mkv", thumbnail_path = "/tmp/c.bgra", bytes = 80,
}), "third thumbnail should fit after LRU eviction")
local count, bytes = Cache.stats(cache)
assert_equal(count, 2, "entry count should respect the configured bound")
assert_equal(bytes, 180, "byte count should track the retained thumbnails")
assert_equal(Cache.get(cache, key_b), nil, "least-recently-used entry should be evicted")
assert_true(#removed == 1 and removed[1] == "/tmp/b.bgra",
    "eviction should remove the corresponding temporary thumbnail file")

local changed_key = assert(Cache.key("/media/a.mkv", 101, 11))
assert_equal(Cache.invalidate_stale(cache, "/media/a.mkv", changed_key), 1,
    "changed source metadata should invalidate stale cached artwork")
assert_equal(Cache.get(cache, key_a), nil, "stale key should no longer hit")
assert_true(Cache.put(cache, changed_key, {
    source_path = "/media/a.mkv", thumbnail_path = "/tmp/a-new.bgra", bytes = 50,
}), "updated file should accept a fresh thumbnail")
assert_equal(Cache.invalidate_path(cache, "/media/a.mkv"), 1,
    "path invalidation should remove every version of a source file")
assert_equal(Cache.get(cache, changed_key), nil, "invalidated path should miss")

assert_equal(Cache.put(cache, key_a, {
    source_path = "/media/a.mkv", thumbnail_path = "/tmp/too-large.bgra", bytes = 201,
}), false, "oversized thumbnails should be rejected")
assert_equal(Cache.put(cache, key_a, {
    source_path = "/media/a.mkv", thumbnail_path = "/tmp/invalid.bgra", bytes = 0,
}), false, "empty thumbnails should be rejected")

Cache.clear(cache)
count, bytes = Cache.stats(cache)
assert_equal(count, 0, "clear should empty the cache")
assert_equal(bytes, 0, "clear should reset cache byte accounting")
assert_true(#removed >= 3, "clear and invalidation should clean temporary files")

print("Video thumbnail cache tests passed.")
