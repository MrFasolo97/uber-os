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

ufs.saveFs = function(mountPath)
  local FSDATA = oldfs.open(fsd.normalizePath(mountPath) .. "/" .. "UFSDATA", "w")
  local WRITEDATA = base64enc(fserialize(collectFiles(mountPath, {})))
  FSDATA.write(WRITEDATA)
  FSDATA.close()
end

ufs.loadFs = function(mountPath)
  local FSDATA = oldfs.open(fsd.normalizePath(mountPath) .. "/" .. "UFSDATA", "r")
  local READDATA = textutils.unserialize(base64dec(FSDATA.readAll()))
  FSDATA.close()
  return READDATA
end

ufs.list = function(mountPath, path)
  path = fs.normalizePath(path)
  if not fs.isDir(path) then
    error("Not a directory")
  end
  if path == "/" then path = "" end
  local p = oldfs.list(path)
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

ufs.exists = function(mountPath, path)
  path = fs.normalizePath(path)
  if string.sub(path, 1, 4) == "/rom" then
    return false
  end
  if path == "/UFSDATA" then
    return false
  end
  return oldfs.exists(path)
end

ufs.isDir = function(mountPath, path)
  path = fs.normalizePath(path)
  if string.sub(path .. "/", 1, 5) == "/rom/" then
    return false
  end
  if path == "/UFSDATA" then
    return false
  end
  return oldfs.isDir(path)
end

ufs.open = function(mountPath, path, mode)
  if fs.normalizePath(path) == "/UFSDATA" then error("Internal error") return end
  return oldfs.open(path, mode)
end

ufs.makeDir = function(mountPath, path)
  oldfs.makeDir(path)
end

ufs.move = function(mountPath, from, to)
  oldfs.move(from, to)
end

ufs.copy = function(mountPath, from, to)
  oldfs.copy(from, to)
end


ufs.delete = function(mountPath, path)
  oldfs.delete(path)
end

ufs = applyreadonly(ufs)
