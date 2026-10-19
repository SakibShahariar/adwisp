-- Adwisp palette loading and ASS color conversion.
-- Palette files use semantic key=value pairs with #RRGGBB values.

local Theme = {}

Theme.fallback = {
    background = "#30251E",
    surface = "#30251E",
    text = "#FAF7F3",
    muted = "#DBD2C8",
    accent = "#9B7653",
    on_accent = "#FFFFFF",
}

local allowed = {
    background = true,
    surface = true,
    text = true,
    muted = true,
    accent = true,
    on_accent = true,
}

local function valid_hex(value)
    return type(value) == "string" and value:match("^#%x%x%x%x%x%x$") ~= nil
end

local function ass_color(hex)
    local red = hex:sub(2, 3)
    local green = hex:sub(4, 5)
    local blue = hex:sub(6, 7)
    return "&H" .. blue .. green .. red .. "&"
end

function Theme.load(path)
    local palette = {}
    for key, value in pairs(Theme.fallback) do
        palette[key] = value
    end

    if type(path) ~= "string" or path == "" then
        return palette, "fallback"
    end

    local file, err = io.open(path, "r")
    if not file then
        return palette, "fallback", err
    end

    for line in file:lines() do
        line = line:gsub("^%s+", ""):gsub("%s+$", "")
        if line ~= "" and not line:match("^#") and not line:match("^;") then
            local key, value = line:match("^([%w_]+)%s*=%s*(.-)%s*$")
            if key and allowed[key] and valid_hex(value) then
                palette[key] = value:upper()
            end
        end
    end
    file:close()

    return palette, "file"
end

function Theme.to_ass(palette)
    local result = {}
    for key, fallback in pairs(Theme.fallback) do
        local value = palette and palette[key] or fallback
        if not valid_hex(value) then value = fallback end
        result[key] = ass_color(value)
    end
    return result
end

return Theme
