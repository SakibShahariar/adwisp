package.path = "./?.lua;./?/init.lua;" .. package.path

local MenuFilter = require "core.menu_filter"
local UnicodeCasefold = require "core.unicode_casefold"

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error((message or "values differ") .. ": expected " .. tostring(expected)
            .. ", got " .. tostring(actual), 2)
    end
end

local function assert_true(value, message)
    if not value then error(message or "expected true", 2) end
end

local items = {
    { title = "Arrival", filename = "arrival.mkv", lang = "eng", codec = "aac" },
    { title = "", filename = "Nocturne.mkv", lang = "eng", codec = "flac" },
    { title = "Arrival", filename = "arrival-extended.mkv", lang = "jpn", codec = "opus" },
    { title = "Spirited Away", filename = "spirited-away.mkv", lang = "jpn", codec = "aac" },
}

local arrival = MenuFilter.filter(items, " ARRIVAL ", { "title", "filename" })
assert_equal(#arrival, 2, "case-insensitive title search should preserve duplicate titles")
assert_equal(arrival[1].index, 1, "first duplicate should retain its original index")
assert_equal(arrival[2].index, 3, "second duplicate should retain its original index")
assert_true(arrival[1].item == items[1] and arrival[2].item == items[3],
    "filtered rows should preserve references to their original items")

local metadata_fallback = MenuFilter.filter(items, "NOC ENG", {
    "title", "filename", "lang", "codec",
})
assert_equal(#metadata_fallback, 1,
    "all query terms should match across visible metadata fields")
assert_equal(metadata_fallback[1].index, 2,
    "metadata fallback should map to the original item with an empty title")

local codec_matches = MenuFilter.filter(items, "AAC", { "title", "filename", "codec" })
assert_equal(#codec_matches, 2, "codec metadata should be searchable when supplied")
assert_equal(codec_matches[1].index, 1, "first codec match should retain its source index")
assert_equal(codec_matches[2].index, 4, "second codec match should retain its source index")

local no_matches = MenuFilter.filter(items, "not-present", { "title", "filename" })
assert_equal(#no_matches, 0, "unmatched queries should return an empty result list")

local cleared = MenuFilter.filter(items, "  \n\t ", { "title", "filename" })
assert_equal(#cleared, #items, "clearing the query should restore every source item")
for index, result in ipairs(cleared) do
    assert_equal(result.index, index, "cleared results should preserve original ordering")
    assert_true(result.item == items[index], "cleared results should retain original item references")
end

local strings = MenuFilter.filter({ "Alpha", "beta" }, "BETA")
assert_equal(#strings, 1, "string menu entries should be searchable")
assert_equal(strings[1].index, 2, "string entries should preserve their source index")

local numbers = MenuFilter.filter({ 42, 99 }, "42")
assert_equal(#numbers, 1, "numeric metadata should be searchable as text")
assert_equal(numbers[1].index, 1, "numeric entries should preserve their source index")

local default_fields = MenuFilter.filter({
    { label = "English subtitles", lang = "eng" },
    { name = "French audio", codec = "aac" },
}, "FRENCH")
assert_equal(#default_fields, 1, "default visible metadata fields should be searchable")
assert_equal(default_fields[1].index, 2, "default field matching should retain source index")

local invalid_items = MenuFilter.filter(nil, "anything")
assert_equal(#invalid_items, 0, "invalid item collections should fail safely")
local no_query = MenuFilter.filter(items, nil, { "title" })
assert_equal(#no_query, #items, "a missing query should behave like a cleared search")

assert_equal(UnicodeCasefold.fold("Straße"), "strasse",
    "German sharp s should expand to ss")
assert_equal(UnicodeCasefold.fold("ΟΣ"), "οσ",
    "Greek final sigma should fold to ordinary sigma")
assert_equal(UnicodeCasefold.fold("İ"), "i̇",
    "Turkish capital dotted I should fold to i plus combining dot")
assert_equal(UnicodeCasefold.fold("ﬃ"), "ffi",
    "the ffi ligature should expand to three letters")
assert_equal(UnicodeCasefold.fold("𐐀"), "𐐨",
    "supplementary-plane Deseret letters should be case folded")
assert_equal(UnicodeCasefold.fold(string.char(0xFF) .. "A"),
    string.char(0xFF) .. "a", "malformed UTF-8 bytes should be preserved safely")

local unicode_matches = MenuFilter.filter({
    { title = "Straße" },
    { title = "ΟΣ" },
    { title = "İstanbul" },
    { title = "ﬃle" },
    { title = "𐐀" },
}, "STRASSE")
assert_equal(#unicode_matches, 1,
    "menu filtering should use full Unicode case folding for query and item text")
assert_equal(unicode_matches[1].index, 1,
    "Unicode case-folded results should retain their original source index")
assert_true(MenuFilter.matches("οσ", "ΟΣ"),
    "Greek final and ordinary sigma should compare case-insensitively")
assert_true(MenuFilter.matches("𐐨", "𐐀"),
    "supplementary-plane letters should match case-insensitively")

assert_equal(items[1].title, "Arrival", "filtering must not mutate source titles")
assert_equal(items[2].filename, "Nocturne.mkv",
    "filtering must not mutate metadata fallback fields")
assert_true(items[1].index == nil,
    "filtering must not attach filtered indices to source objects")

print("All menu filter tests passed.")
