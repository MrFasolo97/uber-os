--File System Driver

fsd = {}
fsdf = {}


local drivers = {}
local oldfs = fs
local nativefs = deepcopy(fs)

function fs.copy(from, to)
    if not fs.exists(from) then return end
    if fs.isDir(from) then
        if not fs.exists(to) then
            fs.makeDir(to)
        end
        local l = fs.list(from)
        for k, v in pairs(l) do
            fs.copy(fs.combine(from, v), fs.combine(to, v))
        end
    else
        local f = fs.open(from, "r")
        local t = fs.open(to, "w")
        t.write(f.readAll())
        f.close()
        t.close()
    end

end

function fs.move(from, to)
    if not fs.exists(from) then return end
    if fs.isDir(from) then
        if not fs.exists(to) then
            fs.makeDir(to)
        end
        local l = fs.list(from)
        for k, v in pairs(l) do
            fs.copy(fs.combine(from, v), fs.combine(to, v))
        end
    else
        local f = fs.open(from, "r")
        local t = fs.open(to, "w")
        t.write(f.readAll())
        f.close()
        t.close()
    end
    fs.delete(from)
end

local oldCopy = oldfs.copy
local oldMove = oldfs.move

fsd.loadFsDriver = function(drv)
    if thread and thread.getUID(coroutine.running()) ~= 0 then
        return false
    end
    kernel.log("Loading Filesystem driver " .. drv)
    if _G["loadfsdriver_" .. drv] then
        status, err = pcall(_G["loadfsdriver_" .. drv], oldfs, drivers)
        if not status then
            kernel.log("Loading Filesystem driver FAILED")
            return false
        end
        _G["loadfsdriver_" .. drv] = nil
        kernel.log("Loading Filesystem driver DONE")
        return true
    end
    status = os.run({oldfs = oldfs, drivers = drivers}, kernel.root .. "/lib/drivers/fs/" .. drv)
    if not status then
        kernel.log("Loading Filesystem driver FAILED")
        return false
    end
    kernel.log("Loading Filesystem driver DONE")
    return true
end

fsd.loadFsDriver("ufs")
fsd.loadFsDriver("devfs")
fsd.loadFsDriver("romfs")
fsd.loadFsDriver("ccfs")
fsd.loadFsDriver("tmpfs")

local nodes = {} --[[
NODE[path]:
owner = 0 (UID of owner)
perms = 755 (permissions)
[linkto] = /bin (symlink to)
]]

local mounts = {} --[[
MOUNT[mount point]:
fs = ufs (Filesystem)
dev = /dev/hdd (device)
]]

function fsd.normalizePath(path, resolvelinks)
    if not path then return "/" end
    path = string.gsub(path, "/+", "/")
    if path == "" then return "/" end
    if string.sub(path, 1, 1) ~= "/" then
        path = "/" .. path
    end
    if path == "/" then
        return "/"
    end
    if string.sub(path, #path, #path) == "/" then
        path = string.sub(path, 1, #path - 1)
    end
    path = "/" .. oldfs.combine("", path)
    if resolvelinks then return fsd.resolveLinks(path) else return path end
end

function fsd.normalizePerms(perms)
    local tmp = tostring(perms)
    local arr = {}
    for i = 1, 3 do
        local n = tonumber(string.sub(tmp, i, i))
        if n == 0 then arr[i] = "---" end
        if n == 1 then arr[i] = "--x" end
        if n == 2 then arr[i] = "-w-" end
        if n == 3 then arr[i] = "-wx" end
        if n == 4 then arr[i] = "r--" end
        if n == 5 then arr[i] = "r-x" end
        if n == 6 then arr[i] = "rw-" end
        if n == 7 then arr[i] = "rwx" end
    end
    return arr
end

function fsd.testPerms(path, user, perm)
    local info = fsd.getInfo(path)
    local norm = fsd.normalizePerms(info.perms)
    if user == info.owner then
        if perm == "r" then return string.sub(norm[1], 1, 1) == "r" end
        if perm == "w" then return string.sub(norm[1], 2, 2) == "w" end
        if perm == "x" then return string.sub(norm[1], 3, 3) == "x" end
    else
        if perm == "r" then return string.sub(norm[3], 1, 1) == "r" end
        if perm == "w" then return string.sub(norm[3], 2, 2) == "w" end
        if perm == "x" then return string.sub(norm[3], 3, 3) == "x" end
    end
end


function fsd.resolveLinks(path, exceptlast)
    path = fsd.normalizePath(path)
    local components = string.split(path, "/")
    local newpath = "/"
    for i = 1, #components do
        local v = components[i]
        local node = fsd.getInfo(newpath .. v, true)
        if node.linkto and (not exceptlast or i < #components) then
            newpath = fsd.normalizePath(node.linkto) .. "/"
        else
            newpath = newpath .. v .. "/"
        end
    end
    return fsd.normalizePath(newpath)
end

function fsd.newLink(name, path)
    if testPerms(name, thread.getUID(coroutine.running()), "w") then
        fsd.setNode(name, nil, nil, path)
    else
        printError("Access denied")
    end
end

function fsd.delLink(name)
    if testPerms(name, thread.getUID(coroutine.running()), "w") then
        fsd.setNode(name, nil, nil, false)
    else
        printError("Access denied")
    end
end

function fsd.stripPath(base, full)
    if base == full then return "/" end
    local l
    l = fsd.normalizePath(string.sub(fsd.normalizePath(full), #fsd.normalizePath(base) + 1, #fsd.normalizePath(full)))
    return l
end

function fsd.recursList(path, cache, include_start, force, dontfollow)
    if not cache then
        if include_start then
            cache = {fsd.normalizePath(path)}
        else
            cache = {}
        end
    end
    path = fsd.normalizePath(path)
    local l = fs.list(path, force)
    if not l then
        return cache
    end
    for k, v in pairs(l) do
        local p = fsd.normalizePath(path .. "/" .. v)
        table.insert(cache, p)
        if not (fsd.getInfo(p).linkto and dontfollow) then
            if fs.isDir(p) then
                fsd.recursList(p, cache)
            end
        end
    end
    return cache
end

function fsd.getMount(path, parent)
    path = fsd.normalizePath(path)
    if parent and mounts[path] then
        path = nativefs.getDir(path)
    end
    local components = string.split(path, "/")
    for i = 2, #components do
        components[i] = components[i - 1] .. "/" .. components[i]
    end
    components[1] = "/"
    local skip = false
    for i = #components, 1, -1 do
        for j, v in pairs(mounts) do
            if components[i] == j then
                if skip and (j ~= "/") then skip = false else return deepcopy(v), j end
            end
        end
    end
end

function fsd.getInfo(path, dontresolve)
    path = fsd.normalizePath(path)
    if path == "/" then
        return {owner = 0, perms = 755}
    end
    if not dontresolve then
        path = fsd.resolveLinks(path, true)
    end
    if nodes[path] then
        return deepcopy(nodes[path])
    end
    local components = string.split(path, "/")
    for i = 1, #components do
        if i > 1 then
            components[i] = components[i - 1] .. "/" .. components[i]
        end
    end
    components[1] = "/"
    for i = #components, 1, -1 do
        if nodes[components[i]] then
            return deepcopy(nodes[components[i]])
        end
    end
    return {owner = 0, perms = 777}
end

function fsd.saveFs(mountPath)
    local x = drivers[fsd.getMount(mountPath).fs].saveFs
    if x then
        x(mountPath, fsd.getMount(mountPath).dev)
    end
end

local function count_char(str, char)
    local count = 0
    for i = 0, #str do
        if char == str:sub(i, i) then
            count = count + 1
        end
    end
    return count
end

function fsd.find(wildcard, dontfollow)
    local lpath = ""
    wildcard = fsd.normalizePath(wildcard)
    if wildcard == "/" then return {} end
    for k, v in pairs(string.split(wildcard, "/")) do
        if string.match(v, "%*") then
            break
        else
            lpath = lpath .. v .. "/"
        end
    end
    local l
    if not fs.exists(lpath) then return {} end
    if fs.isDir(lpath) then
        l = fsd.recursList(lpath, nil, true, false, dontfollow)
    else
        return {lpath}
    end
    local z = count_char(wildcard, "/")
    wildcard = wildcard:gsub("%*", ".*")
    wildcard = fsd.normalizePath(wildcard)
    local result = {}
    for k, v in pairs(l) do
        if count_char(v, "/") == z then
            if string.match(v, "^" .. wildcard .. "$") and v ~= "/" then
                table.insert(result, v)
            end
        end
    end
    return result
end

function fsd.loadFs(mountPath)
    local x = drivers[fsd.getMount(mountPath).fs].loadFs
    if x then
        local tmp = x(mountPath, fsd.getMount(mountPath).dev)
        if mountPath == "/" then mountPath = "" end
        for k, v in pairs(tmp) do
            nodes[mountPath .. k] = v
        end
    end
end

function fsd.sync() 
    for k, v in pairs(mounts) do
        fsd.saveFs(k)
    end
end

function fsd.deleteNode(node)
    node = fsd.normalizePath(node)
    if not nodes[node] then return end
    if fsd.testPerms(oldfs.getDir(node), thread.getUID(coroutine.running()), "w") then 
        nodes[node] = nil
    else
        printError("Access denied")
    end
end

function fsd.setNode(node, owner, perms, linkto)
    node = fs.normalizePath(node, true)
    if node == "/" then
        nodes["/"] = {owner = 0, perms = 755}
        return
    end
    if not nodes[node] then
        nodes[node] = deepcopy(fsd.getInfo(node))
    end
    owner = owner or nodes[node].owner
    perms = perms or nodes[node].perms
    if linkto == false then
        linkto = nil
        elseif linkto == nil then
            if nodes[node].linkto then
                linkto = fs.normalizePath(nodes[node].linkto)
            end
        else
            linkto = fs.normalizePath(linkto)
        end
        if fsd.getInfo(node).owner == thread.getUID(coroutine.running()) or 
            thread.getUID(coroutine.running()) == 0 then
            nodes[node].owner = owner
            nodes[node].perms = perms
            nodes[node].linkto = linkto
        else
            printError("Access denied")
        end
    end

    function fsd.mount(dev, fs, path)
        if thread then
            if thread.getUID(coroutine.running()) ~= 0 then printError("Superuser is required to mount filesystem") end
        end
        if not drivers[fs] then
            kernel.log("Unable to mount " .. dev .. " as " .. fs .. " on " .. path .. " : Driver not loaded")
            return false
        end
        if dev == "__ROOT_DEV__" then dev = ROOT_DIR end
        path = fsd.normalizePath(path)
        if mounts[path] then printError("Filesystem is already mounted") end
        kernel.log("Mounting " .. dev .. " as " .. fs .. " on " .. path)
        mounts[path] = {
            ["fs"] = fs,
            ["dev"] = dev
        }
        fsd.loadFs(path, dev)
        return true
    end

    function fsd.umountPath(path)
        if thread then
            if thread.getUID(coroutine.running()) ~= 0 then printError("Superuser is required to unmount filesystem") end
        end
        path = fsd.normalizePath(path)
        kernel.log("Unmounting at " .. path)
        fsd.saveFs(path)
        mounts[path] = nil
    end

    function fsd.umountDev(dev)
        if thread then
            if thread.getUID(coroutine.running()) ~= 0 then printError("Superuser is required to unmount filesystem") end
        end
        path = fsd.normalizePath(path)
        kernel.log("Unmounting " .. dev)
        for k, v in pairs(mounts) do
            if v.dev == dev then
                fsd.saveFs(k)
                mounts[k] = nil
            end
        end
    end

    function fsd.getMounts()
        return deepcopy(mounts)
    end

    function fsd.pipe()
        local readpipe, writepipe
        readpipe = {}
        writepipe = {}
        local currentChar = 1
        local text = ""
        function readpipe.close() end
        function writepipe.close() end
        function readpipe.flush() end
        function writepipe.flush() end
        function readpipe.readAll()
            currentChar = #text + 1
            return string.sub(text, currentChar, #text)
        end
        function readpipe.readLine()
            local x = string.sub(text, currentChar, #text)
            x = string.sub(x, 1, string.find(x, "\n"))
            currentChar = #x + 1
            return x
        end
        function writepipe.write(str)
            text = text .. str
        end
        function writepipe.writeLine(str)
            text = text .. str .. "\n"
        end
        return readpipe, writepipe
    end

    ------------------------------------------


    function fsdf.list(path, force)
        path = fsd.normalizePath(path, true)
        if fsd.testPerms(path, thread.getUID(coroutine.running()), "x") or (thread.getUID(coroutine.running()) == 0 and force) then
            return true
        else
            return false, "Access denied"
        end
    end

    function fsdf.makeDir(path)
        path = fsd.normalizePath(path, true)
        if fsd.testPerms(oldfs.getDir(path), thread.getUID(coroutine.running()), "w") then
            return true
        else
            return false, "Access denied"
        end
    end

    function fsdf.copy(from, to)
        from = fsd.normalizePath(from, true)
        to = fsd.normalizePath(to, true)
        if fsd.testPerms(from, thread.getUID(coroutine.running()), "r") and fsd.testPerms(to, thread.getUID(coroutine.running()), "w") then
            return true
        else
            return false, "Access denied"
        end
    end

    function fsdf.move(from, to)
        from = fsd.normalizePath(from, true)
        to = fsd.normalizePath(to, true)
        if fsd.testPerms(oldfs.getDir(from), thread.getUID(coroutine.running()), "w") and fsd.testPerms(oldfs.getDir(to), thread.getUID(coroutine.running()), "w") then
            return true
        else
            return false, "Access denied"
        end
    end

    function fsdf.delete(path)
        path = fsd.normalizePath(path)
        if (fsd.testPerms(fsd.resolveLinks(oldfs.getDir(path), true), thread.getUID(coroutine.running()), "w")) then
            fsd.deleteNode(fsd.resolveLinks(path, true))
            if mounts[path] then
                fsd.umountPath(path)
            end
            return true
        else
            return false, "Access denied"
        end
    end

    function fsdf.open(path, mode)
        path = fsd.normalizePath(path, true)
        local modes = {r = "r", rb = "r", w = "w", wb = "w", a = "w", ab = "w"}
        if not modes[mode] then
            return false, "Invalid mode!"
        end
        if fsd.testPerms(path, thread.getUID(coroutine.running()), modes[mode]) then
            return true
        else
            return false, "Access denied"
        end
    end

    --Mounting filesystems

    local fstab = fs.open(kernel.root .. "/etc/fstab", "r")
    for k, v in pairs(string.split(fstab.readAll(), "\n")) do
        local x = string.split(v, " ")
        fsd.mount(x[1], x[3], x[2])
    end
    fstab.close()

    if not mounts["/"] then
        kernel.panic("Unable to mount root filesystem")
    end

    local parentHandlers = {["exists"] = true, ["delete"] = true, ["isDir"] = true}

    for k, v in pairs(oldfs) do
        if not fsd[k] then
            fsd[k] = function(...)
                local status, err
                if fsdf[k] then 
                    status, err = fsdf[k](unpack(arg))
                else
                    status = true
                end
                if not status then
                    printError(err)
                    return false, err
                end
                local mount, mountPath
                if parentHandlers[k] then
                    mount, mountPath = fsd.getMount(fsd.resolveLinks(arg[1]), true)
                else
                    mount, mountPath = fsd.getMount(fsd.resolveLinks(arg[1]))
                end
                local retVal
                if k == "copy" or k == "move" then
                    if fs.isDir(arg[2]) then
                        arg[2] = fsd.normalizePath(arg[2]) .. "/"  .. oldfs.getName(arg[1])
                    end
                end
                if drivers[mount.fs] and drivers[mount.fs][k] then
                    retVal = drivers[mount.fs][k](mountPath, fsd.normalizePath(mount.dev), unpack(arg))
                else
                    retVal = oldfs[k](unpack(arg))
                end
                return retVal
            end
        end
    end

    --[[local oldSetDir = shell.setDir

    shell.setDir = function(dir)
        if not thread then return oldSetDir(dir) end
        if fsd.testPerms(dir, thread.getUID(coroutine.running), "x") then
            return oldSetDir(dir)
        else
            printError("Access denied")
        end
    end]]

    kernel.registerHook("acpi_shutdown", fsd.sync)
    kernel.registerHook("acpi_reboot", fsd.sync)

    fsd = applyreadonly(fsd) _G["fsd"] = fsd
