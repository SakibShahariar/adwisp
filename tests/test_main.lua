-- mpv loads main.lua for directory-style scripts. Guard that it hands off to
-- the real adwisp.lua entry point instead of duplicating script logic.
package.path = "./?.lua;./?/init.lua;" .. package.path

local loaded_entry_point = false
package.preload["adwisp"] = function()
    loaded_entry_point = true
    return {}
end

dofile("main.lua")

if not loaded_entry_point then
    error("main.lua should load the adwisp entry point")
end

print("Entry point tests passed.")
