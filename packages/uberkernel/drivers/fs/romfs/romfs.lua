--ROM File System Driver. Works with fsd.

local romfs = {}

romfs.list = function(mountPath, device, path)
    path = fsd.normalizePath(path)
    path = fsd.resolveLinks(path)
    path = fsd.stripPath(mountPath, path)
    local p = oldfs.list(device .. path)
    if path == "/" then path = "" end
    for i = 1, #p do
        if p[i] then
            local x = path .. "/" .. p[i]
        end
    end
    return p
end

romfs.getSize = function(mountPath, device, path)
    path = fsd.normalizePath(path)
    path = fsd.resolveLinks(path)
    path = fsd.stripPath(mountPath, path)
    return oldfs.getSize(device .. path)
end

romfs.exists = function(mountPath, device, path)
    path = fsd.normalizePath(path)
    path = fsd.resolveLinks(path)
    path = fsd.stripPath(mountPath, path)
    if mountPath == path then return true end
    return oldfs.exists(device .. path)
end

romfs.isDir = function(mountPath, device, path)
    path = fsd.normalizePath(path)
    path = fsd.resolveLinks(path)
    path = fsd.stripPath(mountPath, path)
    if mountPath == path then return true end
    return oldfs.isDir(device .. path)
end

romfs.open = function(mountPath, device, path, mode)
    path = fsd.resolveLinks(path)
    path = fsd.stripPath(mountPath, path)
    return oldfs.open(device .. path, mode)
end

romfs.makeDir = function(mountPath, device, path)
    path = fsd.resolveLinks(path)
    path = fsd.stripPath(mountPath, path)
    oldfs.makeDir(device .. path)
    fs.setNode(mountPath .. "/" .. path)
end

romfs.delete = function(mountPath, device, path)
    path = fsd.stripPath(mountPath, path)
    fsd.setNode(path, nil, nil, false)
    oldfs.delete(device .. path)
    fs.deleteNode(mountPath .. "/" .. path)
end

romfs = applyreadonly(romfs)
drivers.romfs = romfs
