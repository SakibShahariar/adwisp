package.path = "./?.lua;./?/init.lua;" .. package.path

local Preferences = require "core.preferences"

local seek = Preferences.validate("seek_step", "12.5")
assert(seek == 12.5, "seek step should accept finite numeric values")
local volume = Preferences.validate("volume_step", "8")
assert(volume == 8, "volume step should accept whole-number values")
assert(Preferences.validate("seek_step", "0") == nil,
    "seek step should reject values below its supported range")
assert(Preferences.validate("seek_step", "nan") == nil,
    "seek step should reject non-finite values")
assert(Preferences.validate("volume_step", "1.5") == nil,
    "volume step should reject fractional values")
assert(Preferences.validate("volume_step", "101") == nil,
    "volume step should reject values above its supported range")
assert(Preferences.validate("thumbnail_preview", "yes") == true,
    "thumbnail preview should accept yes")
assert(Preferences.validate("thumbnail_preview", "off") == false,
    "thumbnail preview should accept off")
assert(Preferences.validate("thumbnail_preview", "maybe") == nil,
    "thumbnail preview should reject ambiguous values")
assert(Preferences.validate("theme_file", "/tmp/palette.conf") == "/tmp/palette.conf",
    "theme file should accept a bounded path")
assert(Preferences.validate("theme_file", "/tmp/bad\npath") == nil,
    "theme file should reject control characters")
assert(Preferences.validate("unknown", "value") == nil,
    "unknown setting names should be rejected")

local normalized = Preferences.normalize({
    version = 1,
    settings = {
        seek_step = 15,
        volume_step = 5,
        thumbnail_preview = false,
        theme_file = "/tmp/palette.conf",
        unknown = "ignored",
        bad_value = 99,
    },
})
assert(normalized.seek_step == 15 and normalized.volume_step == 5,
    "valid numeric preferences should survive normalization")
assert(normalized.thumbnail_preview == false,
    "boolean preferences should survive normalization")
assert(normalized.theme_file == "/tmp/palette.conf",
    "theme path should survive normalization")
assert(normalized.unknown == nil and normalized.bad_value == nil,
    "unknown preferences should be ignored")
assert(next(Preferences.normalize({ version = 2, settings = normalized })) == nil,
    "unsupported preference versions should be ignored")

local store = {
    raw = '{"version":1,"settings":{}}',
    payload = { version = 1, settings = normalized },
    written = nil,
    renamed = nil,
    removed = nil,
    size = 64,
}
local deps = {
    file_info = function(path)
        if path == "/prefs.json" and store.raw then
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
    format_json = function(value)
        store.saved = value
        return "encoded-preferences"
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

local loaded = Preferences.load("/prefs.json", deps)
assert(loaded.seek_step == 15 and loaded.thumbnail_preview == false,
    "valid persisted preferences should load")
store.size = 65 * 1024
assert(next(Preferences.load("/prefs.json", deps)) == nil,
    "oversized preference files should be rejected before parsing")
store.size = 64
assert(Preferences.save("/prefs.json", normalized, deps),
    "preferences should save through a temporary file and atomic rename")
assert(store.written == "encoded-preferences",
    "encoded preferences should be written to the temporary file")
assert(store.renamed[1] == "/prefs.json.tmp"
    and store.renamed[2] == "/prefs.json",
    "preference save should atomically replace the destination")
assert(store.saved.version == 1 and store.saved.settings.seek_step == 15,
    "saved payload should contain the normalized versioned settings")

local failed = {
    open = function() return nil end,
    format_json = deps.format_json,
    rename = deps.rename,
    remove = deps.remove,
}
local ok, err = Preferences.save("/prefs.json", normalized, failed)
assert(ok == false and type(err) == "string",
    "storage failures should return actionable errors")

print("All preferences tests passed.")
