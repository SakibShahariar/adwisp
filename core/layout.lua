-- Adwisp layout calculations.
-- Pure geometry: no mpv dependency, so hit-testing can share these values later.

local Layout = {}

function Layout.compute(width, height)
    if type(width) ~= "number" or type(height) ~= "number"
        or width <= 0 or height <= 0 then
        return nil
    end

    local panel_width = math.min(560, math.max(1, width - 32))
    local panel_height = math.min(156, math.max(1, height - 32))
    local x = math.floor((width - panel_width) / 2)
    local y = math.max(16, math.floor(height - panel_height - 42))
    local padding = math.min(22, math.floor(panel_width * 0.06))
    local inner_x = x + padding
    local bar_x = inner_x
    local bar_y = y + math.min(104, math.floor(panel_height * 0.67))
    local bar_width = math.max(1, panel_width - padding * 2)

    return {
        width = width,
        height = height,
        panel = { x = x, y = y, width = panel_width, height = panel_height },
        title = { x = inner_x, y = y + 18 },
        playback = { x = inner_x, y = y + 51, width = 96, height = 32 },
        volume = { x = inner_x + 112, y = y + 51, width = 120, height = 32 },
        timeline = {
            x = bar_x, y = bar_y, width = bar_width, height = 6,
            hit_x = bar_x, hit_y = bar_y - 10, hit_width = bar_width, hit_height = 26,
        },
        progress_label = { x = bar_x, y = bar_y + 22 },
        time_label = { x = bar_x + bar_width - 100, y = bar_y + 22 },
        playlist = { x = inner_x, y = y + 132, width = panel_width - padding * 2, height = 20 },
    }
end

return Layout
