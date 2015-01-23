--Uber File System Driver. Works with fsd.

ufs = {}

local oldfs = deepcopy(fs)
lua.include("base64")
lua.include("fixserialize")

local function collectFiles(dir, table)
  if not table then table = {} end
  dir = fs.normalizePath(dir)  
  table[dir] = fs.getInfo(dir)
  local err, files = pcall(fs.list, dir)
  if not err then return table end
  if dir == "/" then dir = "" end
  for k, v in pairs(files) do
    table[dir .. "/" .. v] = fs.getInfo(dir .. "/" .. v)
    if fs.isDir(dir .. "/" .. v) then collectFiles(dir .. "/" .. v, table) end
  end
  return table
end

ufs.saveFs = function(mountPath, device)
  local p = fsd.normalizePath(device)
  if p == "/" then p = "" end
  local FSDATA = oldfs.open(p .. "/UFSDATA", "w")
  local WRITEDATA = base64enc(fserialize(collectFiles(mountPath, {})))
  FSDATA.write(WRITEDATA)
  FSDATA.close()
end

ufs.loadFs = function(mountPath, device)
  local p = fsd.normalizePath(device)
  if p == "/" then p = "" end
  if not oldfs.exists(p .. "/UFSDATA") then ufs.saveFs(mountPath, device) end
  local FSDATA = oldfs.open(p .. "/UFSDATA", "r")
  local READDATA = textutils.unserialize(base64dec(FSDATA.readAll()))
  FSDATA.close()
  return READDATA
end

ufs.list = function(mountPath, device, path)
  path = fs.normalizePath(path)
  if not fs.isDir(device .. path) then
    error("Not a directory")
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
  path = fs.normalizePath(path)
  if string.sub(device .. path, 1, 4) == "/rom" then
    return false
  end
  if path == "/UFSDATA" then
    return false
  end
  return oldfs.exists(path)
end

ufs.isDir = function(mountPath, device, path)
  path = fs.normalizePath(path)
  if string.sub(device .. path .. "/", 1, 5) == "/rom/" then
    return false
  end
  if path == "/UFSDATA" then
    return false
  end
  return oldfs.isDir(device .. path)
end

ufs.open = function(mountPath, device, path, mode)
  if fs.normalizePath(path) == "/UFSDATA" then error("Internal error") return end
  return oldfs.open(device .. path, mode)
end

ufs.makeDir = function(mountPath, device, path)
  oldfs.makeDir(device .. path)
end

ufs.move = function(mountPath, device, from, to)
  oldfs.move(device .. from, device .. to)
end

ufs.copy = function(mountPath, device, from, to)
  oldfs.copy(device .. from, device .. to)
end


ufs.delete = function(mountPath, device, path)
  oldfs.delete(device .. path)
end

ufs = applyreadonly(ufs)
