--ROM Filesystem (access to /rom)

lua.include("copy")

local oldfs = deepcopy(fs)
romfs = {}

romfs.open = function(mountPath, path, mode)
  mountPath = fsd.normalizePath(mountPath)
  path = fsd.normalizePath(path)
  local lPath = fsd.normalizePath(string.sub(path, #mountPath + 2, #path))
  return oldfs.open("/rom" .. lPath, mode)
end

romfs.list = function(mountPath, path)
  mountPath = fsd.normalizePath(mountPath)
  path = fsd.normalizePath(path)
  local lPath = fsd.normalizePath(string.sub(path, #mountPath + 2, #path))
  return oldfs.list("/rom" .. lPath)
end

romfs.isReadOnly = function(mountPath, path)
  mountPath = fsd.normalizePath(mountPath)
  path = fsd.normalizePath(path)
  local lPath = fsd.normalizePath(string.sub(path, #mountPath + 2, #path))
  return oldfs.isReadOnly("/rom" .. lPath)
end

romfs.move = function(mountPath, path)
  error("Filesystem is Read Only!")
end

romfs.copy = function(mountPath, path, to)
  error("Copying is not yet implemented!")
end

romfs.delete = function(mountPath, path, to)
  error("Filesystem is Read Only")
end

romfs.isDir = function(mountPath, path)
  mountPath = fsd.normalizePath(mountPath)
  path = fsd.normalizePath(path)
  local lPath = fsd.normalizePath(string.sub(path, #mountPath + 2, #path))
  return oldfs.isDir("/rom" .. lPath)
end

romfs.exists = function(mountPath, path)
  mountPath = fsd.normalizePath(mountPath)
  path = fsd.normalizePath(path)
  local lPath = fsd.normalizePath(string.sub(path, #mountPath + 2, #path))
  return oldfs.exists("/rom" .. lPath)
end

romfs = applyreadonly(romfs)