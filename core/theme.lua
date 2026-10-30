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

local function fallback_palette()
    local palette = {}
    for key, value in pairs(Theme.fallback) do
        palette[key] = value
    end
    return palette
end

function Theme.load(path)
    if type(path) ~= "string" or path == "" then
        return fallback_palette(), "fallback"
    end

    local file, err = io.open(path, "r")
    if not file then
        return nil, "error", err
    end

    local palette = fallback_palette()
    local diagnostics = {}
    local valid_entries = 0
    local line_number = 0

    for line in file:lines() do
        line_number = line_number + 1
        line = line:gsub("^%s+", ""):gsub("%s+$", "")
        if line ~= "" and not line:match("^#") and not line:match("^;") then
            local key, value = line:match("^([%w_]+)%s*=%s*(.-)%s*$")
            if not key then
                diagnostics[#diagnostics + 1] = string.format(
                    "line %d: malformed palette entry", line_number)
            elseif not allowed[key] then
                diagnostics[#diagnostics + 1] = string.format(
                    "line %d: unknown palette key '%s'", line_number, key)
            elseif not valid_hex(value) then
                diagnostics[#diagnostics + 1] = string.format(
                    "line %d: invalid color for '%s'", line_number, key)
            else
                palette[key] = value:upper()
                valid_entries = valid_entries + 1
            end
        end
    end
    file:close()

    if valid_entries == 0 then
        return nil, "invalid", "no valid palette entries found", diagnostics
    end

    return palette, "file", nil, diagnostics
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
