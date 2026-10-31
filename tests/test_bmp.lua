package.path = "./?.lua;./?/init.lua;" .. package.path

local BMP = require "core.bmp"

local function read_u32(value, offset)
    local a, b, c, d = value:byte(offset, offset + 3)
    return a + b * 256 + c * 65536 + d * 16777216
end

local pixel = string.char(0x11, 0x22, 0x33, 0x44)
local image = assert(BMP.encode_bgra(1, 1, pixel))
assert(image:sub(1, 2) == "BM", "encoder should write a BMP signature")
assert(read_u32(image, 3) == 58, "file header should contain the exact file size")
assert(read_u32(image, 11) == 54, "pixel data should start after the 54-byte header")
assert(read_u32(image, 15) == 40, "encoder should use a BITMAPINFOHEADER")
assert(read_u32(image, 19) == 1, "width should be stored in the header")
assert(read_u32(image, 23) == 4294967295,
    "negative height should preserve top-down preview row order")
assert(read_u32(image, 31) == 0, "encoder should use uncompressed BI_RGB pixels")
assert(read_u32(image, 35) == 4, "image byte count should match the BGRA frame")
assert(image:sub(55) == pixel, "BGRA pixels should be preserved without channel reordering")

local multi = assert(BMP.encode_bgra(2, 2, string.rep(pixel, 4)))
assert(#multi == 70, "two-by-two BGRA image should have the expected file size")
assert(BMP.encode_bgra(0, 1, pixel) == nil, "zero-sized images should be rejected")
assert(BMP.encode_bgra(4097, 1, string.rep(pixel, 4097)) == nil,
    "excessively large dimensions should be rejected")
assert(BMP.encode_bgra(1, 1, "") == nil, "incomplete pixel data should be rejected")
assert(BMP.encode_bgra(1, 1, {}) == nil, "non-string pixel data should be rejected")

print("All BMP encoder tests passed.")
