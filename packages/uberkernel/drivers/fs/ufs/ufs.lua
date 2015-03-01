--Uber File System Driver. Works with fsd.

local ufs = {}

local function collectFiles(dir, stripPath, table)
  if not table then table = {} end
  dir = fsd.normalizePath(dir)  
  local fixPath = fsd.stripPath(stripPath, dir)
  table[dir] = fsd.getInfo(dir)
  local err, files = pcall(fs.list, dir)
  if not err then return table end
  if dir == "/" then dir = "" end
  for k, v in pairs(files) do
    table[fsd.normalizePath(fixPath .. "/" .. v)] = fsd.getInfo(dir .. "/" .. v)
    if fs.isDir(dir .. "/" .. v) then collectFiles(dir .. "/" .. v, stripPath, table) end
  end
  return table
end

ufs.saveFs = function(mountPath, device)
  local p = fsd.normalizePath(device)
  if p == "/" then p = "" end
  local FSDATA = oldfs.open(p .. "/UFSDATA", "w")
  local WRITEDATA = "" 
  for k, v in pairs(collectFiles(mountPath, mountPath, {})) do
    WRITEDATA = WRITEDATA .. k .. ":" .. v.owner .. ":" .. v.perms .. ":"
    if v.linkto then WRITEDATA = WRITEDATA .. v.linkto end
    WRITEDATA = WRITEDATA .. "\n"
  end
  FSDATA.write(WRITEDATA)
  FSDATA.close()
end

ufs.loadFs = function(mountPath, device)
  local p = fsd.normalizePath(device)
  if p == "/" then p = "" end
  if not oldfs.exists(p .. "/UFSDATA") then ufs.saveFs(mountPath, device) end
  local FSDATA = oldfs.open(p .. "/UFSDATA", "r")
  local READDATA = FSDATA.readAll()
  FSDATA.close()
  local splitted = string.split(READDATA, "\n")
  local res = {}
  for k, v in pairs(splitted) do
    local tmp = string.split(v, ":")
    res[tmp[1]] = {
      owner = tonumber(tmp[2]),
      perms = tmp[3],
      linkto = tmp[4]
    }
    if tmp[4] == "" then
      res[tmp[1]].linkto = nil
    end
  end
  return res
end

ufs.list = function(mountPath, device, path)
  path = fsd.normalizePath(path)
  path = fsd.resolveLinks(path)
  path = fsd.stripPath(mountPath, path)
  if not fs.isDir(device .. path) then
    printError("Not a directory")
  end
  local p = oldfs.list(device .. path)
  if path == "/" then path = "" end
  for i = 1, #p do
    if p[i] then
      local x = path .. "/" .. p[i]
      if (x == "/rom") or (x == "/UFSDATA") then
        table.remove(p, i)
      end
    end
  end
  return p
end

ufs.exists = function(mountPath, device, path)
  path = fsd.normalizePath(path)
  if string.sub(device .. path, 1, 4) == "/rom" then
    return false
  end
  path = fsd.resolveLinks(path)
  path = fsd.stripPath(mountPath, path)
  if path == "/UFSDATA" then
    return false
  end
  if mountPath == path then return true end
  return oldfs.exists(device .. path)
end

ufs.isDir = function(mountPath, device, path)
  path = fsd.normalizePath(path)
  if string.sub(device .. path .. "/", 1, 5) == "/rom/" then
    return false
  end
  path = fsd.resolveLinks(path)
  path = fsd.stripPath(mountPath, path)
  if path == "/UFSDATA" then
    return false
  end
  if mountPath == path then return true end
  return oldfs.isDir(device .. path)
end

ufs.open = function(mountPath, device, path, mode)
  path = fsd.resolveLinks(path)
  path = fsd.stripPath(mountPath, path)
  if fsd.normalizePath(path) == "/UFSDATA" then printError("Internal error") return end
  return oldfs.open(device .. path, mode)
end

ufs.makeDir = function(mountPath, device, path)
  path = fsd.resolveLinks(path)
  path = fsd.stripPath(mountPath, path)
  if fsd.normalizePath(path) == "/UFSDATA" then printError("Internal error") return end
  oldfs.makeDir(device .. path)
  fs.setNode(mountPath .. "/" .. path)
end

ufs.move = function(mountPath, device, from, to)
  from = fsd.resolveLinks(from)
  to = fsd.resolveLinks(to)
  from = fsd.stripPath(mountPath, from)
  to = fsd.stripPath(mountPath, to)
  if fsd.normalizePath(to) == "/UFSDATA" then printError("Internal error") return end
  if fsd.normalizePath(from) == "/UFSDATA" then printError("Internal error") return end
  oldfs.move(device .. from, device .. to)
  fs.setNode(mountPath .. "/" .. to)
end

ufs.copy = function(mountPath, device, from, to)
  from = fsd.resolveLinks(from)
  to = fsd.resolveLinks(to)
  from = fsd.stripPath(mountPath, from)
  to = fsd.stripPath(mountPath, to)
  if fsd.normalizePath(to) == "/UFSDATA" then printError("Internal error") return end
  if fsd.normalizePath(from) == "/UFSDATA" then printError("Internal error") return end
  oldfs.copy(device .. from, device .. to)
  fs.setNode(mountPath .. "/" .. to)
end


ufs.delete = function(mountPath, device, path)
  path = fsd.stripPath(mountPath, path)
  if fsd.normalizePath(path) == "/UFSDATA" then printError("Internal error") return end
  fsd.setNode(path, nil, nil, false)
  oldfs.delete(device .. path)
  fs.deleteNode(mountPath .. "/" .. path)
end

ufs = applyreadonly(ufs) 
drivers.ufs = ufs
