--DevFs Driver

local devfs = {}

function devfs.loadFs()
    if udev then
        return {}, true
    else
        printError("[devfs] udev not found!")
        return nil, false
    end
end

function devfs.getSize() return 0 end

function devfs.list(mountPath, device, path)
    return udev.getMnemonics()
end

function devfs.exists(mountPath, device, path)
    local files = udev.getMnemonics()
    path = oldfs.getName(path)
    for i = 1, #files do
        if files[i] == path then
            return true
        end
    end
    return false
end

function devfs.open(mountPath, device, path, mode)
    path = fs.normalizePath(path)
    if mode == "r" then
        local text = udev.readDevice(oldfs.getName(path))
        local handle = {
            currentLine = 1,
            text = text,
            lines = string.split(text, "\n"),
            close = function() end
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
            close = function() end,
            flush = function() end
        }
        local w = function(s)
            local handle = handle
            return udev.onWrite(oldfs.getName(path), s)
        end
        handle.write = w
        handle.writeLine = w
        return handle
    end
end

devfs = applyreadonly(devfs)
drivers.devfs = devfs
