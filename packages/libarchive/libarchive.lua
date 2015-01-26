archive = {}

archive.pack = function(path, saveto)
  local x = fs.recursList(path)
  for k, v in pairs(x) do x[k] = fs.stripPath(path, v) end
  local files = {}
  for k, v in pairs(x) do
    if not fs.isDir(path .. v) then
      local f = fs.open(path .. v, "r")
      files[v] = f.readAll()
      f.close()
    else
      files[v] = true
    end
  end
  local f = fs.open(saveto, "w")
  f.write(textutils.serialize(files))
  f.close()
end

archive.unpack = function(from, path)
  local f = fs.open(from, "r")
  local a = f.readAll()
  f.close()
  local parsed = textutils.unserialize(a)
  for k, v in pairs(parsed) do
    if type(v) == "boolean" then --Directory
      fs.makeDir(path .. k)
    end
  end
  for k, v in pairs(parsed) do
    if type(v) ~= "boolean" then --File
      local file = fs.open(path .. k, "w")
      file.write(v)
      file.close()
    end
  end
end

archive = applyreadonly(archive)
