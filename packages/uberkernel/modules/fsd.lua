--File System Driver

lua.include("copy")
lua.include("split")

fsd = {}
fsdf = {}

local loadFsDriver = function(drv)
  kernel.log("Loading Filesystem driver " .. drv)
  shell.run(kernel.root .. "/lib/drivers/fs/" .. drv)
  kernel.log("Loading Filesystem driver DONE")
end

loadFsDriver("ufs")
loadFsDriver("devfs")
loadFsDriver("romfs")
loadFsDriver("ccfs")

local oldfs = deepcopy(fs)

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

function fsd.normalizePath(path)
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
  return path
end

function fsd.resolveLinks(path)
  path = fsd.normalizePath(path)
  local components = string.split(path, "/")
  local newpath = "/"
  for i = 1, #components do
    local v = components[i]
    local node = fsd.getInfo(newpath .. v, true)
    if node.linkto then
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
    error("Access denied!")
  end
end

function fsd.delLink(name, path)
  if testPerms(name, thread.getUID(coroutine.running()), "w") then
    fsd.setNode(name, nil, nil, false)
  else
    error("Access denied!")
  end
end

function fsd.stripPath(base, full)
  if base == full then return "/" end
  local l
  l = fsd.normalizePath(string.sub(fsd.normalizePath(full), #fsd.normalizePath(base) + 1, #fsd.normalizePath(full)))
  return l
end

function fsd.recursList(path, cache)
  if not cache then cache = {} end
  path = fsd.normalizePath(path)
  local l = fs.list(path)
  for k, v in pairs(l) do
    local p = fsd.normalizePath(path .. "/" .. v)
    table.insert(cache, p)
    if fs.isDir(p) then
      fsd.recursList(p, cache)
    end
  end
  return cache
end

function fsd.getMount(path)
  path = fsd.normalizePath(path)
  local components = string.split(path, "/")
  for i = 2, #components do
    components[i] = components[i - 1] .. "/" .. components[i]
  end
  components[1] = "/"
  local skip = false
  for i = #components, 1, -1 do
    for j, v in pairs(mounts) do
      if components[i] == j then
        if skip and (j ~= "/") then skip = false else return v, j end
      end
    end
  end
end

function fsd.getInfo(path, dontresolve)
  path = fsd.normalizePath(path)
  if nodes[path] then
    return nodes[path]
  end
  if not dontresolve then
    path = fsd.resolveLinks(path)
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
      return nodes[components[i]]
    end
  end
  return {owner = 0, perms = 777}
end

function fsd.saveFs(mountPath)
  local x = getfenv()[fsd.getMount(mountPath).fs].saveFs
  if x then
    x(mountPath, fsd.getMount(mountPath).dev)
  end
end

function fsd.loadFs(mountPath)
  local x = getfenv()[fsd.getMount(mountPath).fs].loadFs
  if x then
    local tmp = x(mountPath, fsd.getMount(mountPath).dev)
    if mountPath == "/" then mountPath = "" end
    for k, v in pairs(tmp) do
      nodes[mountPath .. k] = v
    end
  end
end

function fsd.deleteNode(node)
  if not nodes[node] then return end
  if nodes[node].onwer == thread.getUID(coroutine.running()) then
    nodes[node] = nil
  else
    error("Access denied!")
  end
end

function fsd.setNode(node, owner, perms, linkto)
  node = fs.normalizePath(node)
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
  if fsd.getInfo(node).owner == thread.getUID(coroutine.running()) then
    nodes[node].owner = owner
    nodes[node].perms = perms
    nodes[node].linkto = linkto
  else
    error("Access denied!")
  end
end

function fsd.mount(dev, fs, path)
  if thread then
    if thread.getUID(coroutine.running()) ~= 0 then error("Superuser is required to mount filesystem") end
  end
  if not getfenv()[fs] then
    kernel.log("Unable to mount " .. dev .. " as " .. fs .. " on " .. path .. " : Driver not loaded")
    return false
  end
  if dev == "__ROOT_DEV__" then dev = ROOT_DIR end
  path = fsd.normalizePath(path)
  if mounts[path] then error("Filesystem is already mounted") end
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
    if thread.getUID(coroutine.running()) ~= 0 then error("Superuser is required to unmount filesystem") end
  end
  path = fsd.normalizePath(path)
  kernel.log("Unmounting at " .. path)
  fsd.saveFs(path)
  mounts[path] = nil
end

function fsd.umountDev(dev)
  if thread then
    if thread.getUID(coroutine.running()) ~= 0 then error("Superuser is required to unmount filesystem") end
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

function fsdf.list(path)
  path = fsd.normalizePath(path)
  if fsd.testPerms(path, thread.getUID(coroutine.running()), "x") then
    return true
  else
    return false, "Access denied!"
  end
end

function fsdf.makeDir(path)
  path = fsd.normalizePath(path)
  if fsd.testPerms(oldfs.getDir(path), thread.getUID(coroutine.running()), "w") then
    return true
  else
    return false, "Access denied"
  end
end

function fsdf.copy(from, to)
  from = fsd.normalizePath(from)
  to = fsd.normalizePath(to)
  if fsd.testPerms(from, thread.getUID(coroutine.running()), "r") and fsd.testPerms(to  , thread.getUID(coroutine.running()), "w") then
    return true
  else
    return false, "Access denied!"
  end
end

function fsdf.move(from, to)
  from = fsd.normalizePath(from)
  to = fsd.normalizePath(to)
  if fsd.testPerms(oldfs.getDir(from), thread.getUID(coroutine.running()), "w") and fsd.testPerms(oldfs.getDir(to), thread.getUID(coroutine.running()), "w") then
    return true
  else
    return false, "Access denied!"
  end
end

function fsdf.delete(path)
  path = fsd.normalizePath(path)
  if fsd.testPerms(oldfs.getDir(path), thread.getUID(coroutine.running()), "w") then
    return true
  else
    return false, "Access denied!"
  end
end

function fsdf.open(path, mode)
  path = fsd.normalizePath(path)
  local modes = {r = "r", rb = "r", w = "w", wb = "w", a = "w", ab = "w"}
  if not modes[mode] then
    return false, "Invalid mode!"
  end
  if fsd.testPerms(path, thread.getUID(coroutine.running()), modes[mode]) then
    return true
  else
    return false, "Access denied!"
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

local parentHandlers = {} --{["exists"] = true, ["isDir"] = true, ["getDir"] = true}

for k, v in pairs(oldfs) do
  fsd[k] = function(...)
    local status, err
    if fsdf[k] then 
      status, err = fsdf[k](unpack(arg))
    else
      status = true
    end
    if not status then
      error(err)
      return false
    end
    local mount, mountPath
    if parentHandlers[k] then
      mount, mountPath = fsd.getMount(fsd.resolveLinks(arg[1]))
      mount, mountPath = fsd.getMount(oldfs.getDir(mountPath))
    else
      mount, mountPath = fsd.getMount(fsd.resolveLinks(arg[1]))
    end
    local retVal
    if getfenv()[mount.fs] and getfenv()[mount.fs][k] then
       retVal = getfenv()[mount.fs][k](mountPath, fsd.normalizePath(mount.dev), unpack(arg))
    else
      retVal = oldfs[k](unpack(arg))
    end
    return retVal
  end
end

local oldSetDir = shell.setDir

shell.setDir = function(dir)
  if not thread then return oldSetDir(dir) end
  if fsd.testPerms(dir, thread.getUID(coroutine.running), "x") then
    return oldSetDir(dir)
  else
    error("Access denied!")
  end
end

fsd = applyreadonly(fsd) _G["fsd"] = fsd
