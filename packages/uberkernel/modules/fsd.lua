--File System Driver

lua.include("copy")
lua.include("split")

fsd = {}
local fsdf = {}

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

local nodes = {}

local mounts = {}

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

function fsd.getInfo(path)
  path = fsd.normalizePath(path)
  if nodes[path] then
    return nodes[path]
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
    x(mountPath)
  end
end

function fsd.loadFs(mountPath)
  local x = getfenv()[fsd.getMount(mountPath).fs].loadFs
  if x then
    nodes = x(mountPath)
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

function fsd.setNode(node, owner, perms)
  if not nodes[node] then
    nodes[node] = {}
  end
  owner = owner or nodes[node].owner
  perms = perms or nodes[node].perms
  if nodes[node].owner == thread.getUID(coroutine.running()) then
    nodes[node].owner = owner
    nodes[node].perms = perms
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

------------------------------------------

function fsdf.list(path)
  path = fsd.normalizePath(path)
  if fsd.testPerms(path, thread.getUID(coroutine.running()), "x") then
    --Passing control to Filesystem
  else
    error("Access denied!")
  end
end

function fsdf.makeDir(path)
  path = fsd.normalizePath(path)
  if fsd.testPerms(oldfs.getDir(path), thread.getUID(coroutine.running()), "w") then
    --Passing control to Filesystem
  else
    error("Access denied")
  end
end

function fsdf.copy(from, to)
  from = fsd.normalizePath(from)
  to = fsd.normalizePath(to)
  if fsd.testPerms(from, thread.getUID(coroutine.running()), "r") and fsd.testPerms(to  , thread.getUID(coroutine.running()), "w") then
    --Passing control to Filesystem
  else
    error("Access denied!")
  end
end

function fsdf.move(from, to)
  from = fsd.normalizePath(from)
  to = fsd.normalizePath(to)
  if fsd.testPerms(oldfs.getDir(from), thread.getUID(coroutine.running()), "w") and fsd.testPerms(oldfs.getDir(to), thread.getUID(coroutine.running()), "w") then
    --Passing control to Filesystem
  else
    error("Access denied!")
  end
end

function fsdf.delete(path)
  path = fsd.normalizePath(path)
  if fsd.testPerms(oldfs.getDir(path), thread.getUID(coroutine.running()), "w") then
    --Passing control to Filesystem
  else
    error("Access denied!")
  end
end

function fsdf.open(path, mode)
  path = fsd.normalizePath(path)
  local modes = {r = "r", rb = "r", w = "w", wb = "w", a = "w", ab = "w"}
  if not modes[mode] then
    error("Invalid mode!")
  end
  if fsd.testPerms(path, thread.getUID(coroutine.running()), modes[mode]) then
    --Passing control to Filesystem
  else
    error("Access denied!")
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

for k, v in pairs(oldfs) do
  fsd[k] = function(...)
    if fsdf[k] then fsdf[k](unpack(arg)) end
    local mount, mountPath = fsd.getMount(arg[1])
    local retVal
    if getfenv()[mount.fs] and getfenv()[mount.fs][k] then
       retVal = getfenv()[mount.fs][k](mountPath, unpack(arg))
    else
      retVal = oldfs[k](unpack(arg))
    end
    return retVal
  end
end

fsd = applyreadonly(fsd)
