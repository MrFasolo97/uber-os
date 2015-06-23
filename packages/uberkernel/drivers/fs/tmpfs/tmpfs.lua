--Temporary File System Driver. Works with fsd.

local tmpfs = {}
local mountPaths = {}

tmpfs.loadFs = function(mountPath)
    if not mountPaths[mountPath] then
        mountPaths[mountPath] = {files = {}, dirs = {}}
    end
    return {}, true
end

tmpfs.getSize = function() return 0 end

tmpfs.list = function(mountPath, device, path)
    if not mountPaths[mountPath] then
        mountPaths[mountPath] = {files = {}, dirs = {}}
    end
    path = fsd.normalizePath(path)
    path = fsd.resolveLinks(path)
    path = fsd.stripPath(mountPath, path)
    if path == "/" then path = "" end
    local r = {}
    for k, v in pairs(mountPaths[mountPath].dirs) do
        if v then
            local z = k:match("^" .. path .. "/([^/]*)$") 
            if z then table.insert(r, z) end
        end
    end
    for k, v in pairs(mountPaths[mountPath].files) do
        if v then
            local z = k:match("^" .. path .. "/([^/]*)$") 
            if z then table.insert(r, z) end
        end
    end
    return r
end

tmpfs.exists = function(mountPath, device, path)
    if not mountPaths[mountPath] then
        mountPaths[mountPath] = {files = {}, dirs = {}}
    end
    path = fsd.normalizePath(path)
    path = fsd.resolveLinks(path)
    if mountPath == path then return true end
    path = fsd.stripPath(mountPath, path)
    if mountPaths[mountPath].files[path] then return true end
    if mountPaths[mountPath].dirs[path] then return true end
    return false
end

tmpfs.isDir = function(mountPath, device, path)
    if not mountPaths[mountPath] then
        mountPaths[mountPath] = {files = {}, dirs = {}}
    end
    path = fsd.normalizePath(path)
    path = fsd.resolveLinks(path)
    if mountPath == path then return true end
    path = fsd.stripPath(mountPath, path)
    if mountPaths[mountPath].dirs[path] then return true end
    return false
end

tmpfs.open = function(mountPath, device, path, mode)
    if not mountPaths[mountPath] then
        mountPaths[mountPath] = {files = {}, dirs = {}}
    end
    if fs.isDir(path) then return end
    path = fsd.resolveLinks(path)
    path = fsd.stripPath(mountPath, path)
    if not mode:match("^[rwa]$") then printError("Incorrect or unsupported mode") return end
    if mode == "r" then
        if not mountPaths[mountPath].files[path] then return end
        local text = tostring(mountPaths[mountPath].files[path])
        local handle = {
            currentLine = 1,
            text = text,
            lines = string.split(text, "\n"),
            close = function() end,
            flush = function() end
        }
        local readLine = function()
            local handle = handle
            if handle.currentLine > #handle.lines then
                return nil
            end
            handle.currentLine = handle.currentLine + 1
            return handle.lines[handle.currentLine - 1]
        end
        local readAll = function()
            local handle = handle
            return table.concat(handle.lines, "\n", handle.currentLine)
        end
        handle.readLine = readLine
        handle.readAll = readAll
        return handle
    else
        local handle = {
            text = ""
        }
        if mode == "a" then handle.text = mountPaths[mountPath].files[path] end
        local close = function()
            local handle = handle
            mountPaths[mountPath].files[path] = handle.text
        end
        local write = function(w)
            local handle = handle
            handle.text = handle.text .. w
        end
        local writeLine = function(w)
            local handle = handle
            handle.text = handle.text .. w .. "\n"
        end
        handle.close = close
        handle.flush = flush
        handle.write = write
        handle.writeLine = writeLine
        return handle
    end
end

tmpfs.makeDir = function(mountPath, device, path)
    if not mountPaths[mountPath] then
        mountPaths[mountPath] = {files = {}, dirs = {}}
    end
    path = fsd.resolveLinks(path)
    path = fsd.stripPath(mountPath, path)
    mountPaths[mountPath].dirs[path] = true, path
end

tmpfs.delete = function(mountPath, device, path)
    if not mountPaths[mountPath] then
        mountPaths[mountPath] = {files = {}, dirs = {}}
    end
    path = fsd.stripPath(mountPath, path)
    mountPaths[mountPath].files[path] = nil
    mountPaths[mountPath].dirs[path] = nil
    local nfiles = {}
    local ndirs = {}
    for k, v in pairs(mountPaths[mountPath].files) do
        if not k:match("^" .. path .. "/.*$") then
            nfiles[k] = v
        end
    end
    for k, v in pairs(mountPaths[mountPath].dirs) do
        if not k:match("^" .. path .. "/.*$") then
            ndirs[k] = v
        end
    end
    mountPaths[mountPath].files = nfiles
    mountPaths[mountPath].dirs = ndirs
end

tmpfs = applyreadonly(tmpfs)
drivers.tmpfs = tmpfs
