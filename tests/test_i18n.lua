package.path = "./?.lua;./?/init.lua;" .. package.path

local I18n = require "core.i18n"

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error((message or "values differ") .. ": expected " .. tostring(expected)
            .. ", got " .. tostring(actual), 2)
    end
end

local function assert_true(value, message)
    if not value then error(message or "expected true", 2) end
end

local parsed = I18n.parse([[
# English defaults may be overridden by UTF-8 values.
play = Start
pause=Stop
volume = Lautstärke
menu.title = Recently played
; ignored comment
malformed line
empty=
bad key=value
]])
assert_equal(parsed.play, "Start", "simple keys should parse")
assert_equal(parsed.pause, "Stop", "whitespace around separators should be ignored")
assert_equal(parsed.volume, "Lautstärke", "UTF-8 translations should be preserved")
assert_equal(parsed["menu.title"], "Recently played", "dotted keys should parse")
assert_equal(parsed.malformed, nil, "malformed lines should be ignored")
assert_equal(parsed.empty, nil, "empty values should fall back to English")
assert_equal(I18n.t(parsed, "play", "Play"), "Start",
    "translations should override fallback strings")
assert_equal(I18n.t(parsed, "missing", "Fallback"), "Fallback",
    "missing translations should use the English fallback")
assert_equal(I18n.t({}, "missing"), "missing",
    "a missing fallback should return the key")

local store = {
    contents = "play=Lire\npause=Arrêter\n",
    size = 20,
    opened = nil,
}
local deps = {
    file_info = function(path)
        if path == "/locale.conf" then
            return { is_file = true, size = store.size }
        end
        return nil
    end,
    open = function(path, mode)
        store.opened = { path, mode }
        return {
            read = function() return store.contents end,
            close = function() return true end,
        }
    end,
}
local loaded = I18n.load("/locale.conf", deps)
assert_equal(loaded.play, "Lire", "valid locale files should load")
assert_equal(store.opened[1], "/locale.conf", "locale loader should open only the configured file")
assert_equal(store.opened[2], "rb", "locale files should be read-only")

store.size = 70 * 1024
assert_equal(next(I18n.load("/locale.conf", deps)), nil,
    "oversized locale files should be rejected")
assert_equal(next(I18n.load("", deps)), nil,
    "empty locale paths should disable translation loading")
assert_equal(next(I18n.load("/missing.conf", deps)), nil,
    "missing locale files should fall back to English")

local config = assert(io.open("script-opts/adwisp.conf", "r"))
local config_text = config:read("*a")
config:close()
assert_true(config_text:find("locale_file=", 1, true) ~= nil,
    "the default script options should expose a locale-file setting")

print("Localization tests passed.")
