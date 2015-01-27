--ComputerCraft File System Driver. Works with fsd.

ccfs = {}

local oldfs = deepcopy(fs)

ccfs.list = function(mountPath, device, path)
  path = fsd.normalizePath(path)
  path = fsd.resolveLinks(path)
  path = fsd.stripPath(mountPath, path)
  if not fs.isDir(device .. path) then
    error("Not a directory")
  end
  local p = oldfs.list(device .. path)
  if path == "/" then path = "" end
  for i = 1, #p do
    if p[i] then
      local x = path .. "/" .. p[i]
    end
  end
  return p
end

ccfs.exists = function(mountPath, device, path)
  path = fsd.normalizePath(path)
  path = fsd.resolveLinks(path)
  path = fsd.stripPath(mountPath, path)
  if mountPath == path then return true end
  return oldfs.exists(device .. path)
end

ccfs.isDir = function(mountPath, device, path)
  path = fsd.normalizePath(path)
  path = fsd.resolveLinks(path)
  path = fsd.stripPath(mountPath, path)
  if mountPath == path then return true end
  return oldfs.isDir(device .. path)
end

ccfs.open = function(mountPath, device, path, mode)
  path = fsd.resolveLinks(path)
  path = fsd.stripPath(mountPath, path)
  return oldfs.open(device .. path, mode)
end

ccfs.makeDir = function(mountPath, device, path)
  path = fsd.resolveLinks(path)
  path = fsd.stripPath(mountPath, path)
  oldfs.makeDir(device .. path)
  fs.setNode(mountPath .. "/" .. path)
end

ccfs.move = function(mountPath, device, from, to)
  from = fsd.resolveLinks(from)
  to = fsd.resolveLinks(to)
  from = fsd.stripPath(mountPath, from)
  to = fsd.stripPath(mountPath, to)
  oldfs.move(device .. from, device .. to)
  fs.setNode(mountPath .. "/" .. to)
end

ccfs.copy = function(mountPath, device, from, to)
  from = fsd.resolveLinks(from)
  to = fsd.resolveLinks(to)
  from = fsd.stripPath(mountPath, from)
  to = fsd.stripPath(mountPath, to)
  oldfs.copy(device .. from, device .. to)
  fs.setNode(mountPath .. "/" .. to)
end


ccfs.delete = function(mountPath, device, path)
  path = fsd.stripPath(mountPath, path)
  fsd.setNode(path, nil, nil, false)
  oldfs.delete(device .. path)
  fs.deleteNode(mountPath .. "/" .. path)
end

ccfs = applyreadonly(ccfs) _G["ccfs"] = ccfs
