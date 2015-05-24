--Lua functions

lua = {}
local libPaths = {"/lib", "/usr/lib", "/usr/local/lib"}

function lua.include(lib)
    local result
    for i = 1, #libPaths do
        if fs.exists(libPaths[i] .. "/" .. lib .. ".lua") then
            local status
            status = loadfile(libPaths[i] .. "/" .. lib .. ".lua")
            if status then
                result = status()
                kernel.log("Loaded library: " .. lib .. ".lua")
                return result
            else
                kernel.log("Failed to load library: " .. lib .. ".lua")
                printError("Failed to load library: " .. lib .. ".lua")
                return nil
            end
        end
    end
end

lua = applyreadonly(lua) _G["lua"] = lua
