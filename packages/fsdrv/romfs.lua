--ROM Filesystem (access to /rom)

lua.include("copy")

local oldfs = deepcopy(fs)
romfs = {}

romfs.open = function(mountPath, device, path, mode)
  mountPath = fsd.normalizePath(mountPath)
  path = fsd.normalizePath(path)
  local lPath = fsd.normalizePath(string.sub(path, #mountPath + 2, #path))
  return oldfs.open("/rom" .. lPath, mode)
end

romfs.list = function(mountPath, device, path)
  mountPath = fsd.normalizePath(mountPath)
  path = fsd.normalizePath(path)
  local lPath = fsd.normalizePath(string.sub(path, #mountPath + 2, #path))
  return oldfs.list("/rom" .. lPath)
end

romfs.isReadOnly = function(mountPath, device, path)
  mountPath = fsd.normalizePath(mountPath)
  path = fsd.normalizePath(path)
  local lPath = fsd.normalizePath(string.sub(path, #mountPath + 2, #path))
  return oldfs.isReadOnly("/rom" .. lPath)
end

romfs.move = function(mountPath, device, path)
  error("Filesystem is Read Only!")
end

romfs.copy = function(mountPath, device, path, to)
  error("Copying is not yet implemented!")
end

romfs.delete = function(mountPath, device, path, to)
  error("Filesystem is Read Only")
end

romfs.isDir = function(mountPath, device, path)
  mountPath = fsd.normalizePath(mountPath)
  path = fsd.normalizePath(path)
  local lPath = fsd.normalizePath(string.sub(path, #mountPath + 2, #path))
  return oldfs.isDir("/rom" .. lPath)
end

romfs.exists = function(mountPath, device, path)
  mountPath = fsd.normalizePath(mountPath)
  path = fsd.normalizePath(path)
  local lPath = fsd.normalizePath(string.sub(path, #mountPath + 2, #path))
  return oldfs.exists("/rom" .. lPath)
end

romfs = applyreadonly(romfs) _G["romfs"] = romfs
