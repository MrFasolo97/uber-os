--Uber Packaging Tool

local argv = { ... }

if #argv < 1 then
  error("Usage: upt install|remove|get|get-install")
end

local function install()
  if #argv < 2 then
    error("Usage: upt install <package1> [package2] ...")
  end
  local oldDir = shell.dir()
  for i = 2, #argv do
    if not fs.exists("/usr/src/" .. argv[i]) then
      error("Package " .. argv[i] .. " not found!")
    end
    print("Building package " .. argv[i])
    shell.setDir("/usr/src/" .. argv[i])
    shell.run("/usr/src/" .. argv[i] .."/Build.lua")
    fs.makeDir("/var/cache/" .. argv[i])
    print("Installing package " .. argv[i])
    shell.run("/usr/src/" .. argv[i] .."/Build.lua install /var/cache/" .. argv[i])
    shell.run("/usr/src/" .. argv[i] .."/Build.lua install")
    print("Registring package " .. argv[i])
    local flist = fs.recursList("/var/cache/" .. argv[i])
    --print(textutils.serialize(flist)) 
    local f = fs.open("/var/lib/upt/" .. argv[i], "w")
    for j = #flist, 1, -1 do
      local x = fsd.stripPath("/var/cache/" .. argv[i], flist[j])
      if not fs.isDir(x) then
        f.write(x .. "\n")
      end
      --print("Not a dir: " .. x)
    end
    f.write("//DIRLIST\n")
    for j = #flist, 1, -1 do
      local x = fsd.stripPath("/var/cache/" .. argv[i], flist[j])
      if fs.isDir(x) then
        f.write(x .. "\n")
      end
      --print("A dir: " .. x)
    end
    f.close()
    fs.delete("/var/cache/" .. argv[i])
    print("Installing package " .. argv[i] .. " done!")
  end
  shell.setDir(oldDir)
end

local function remove()
  if #argv < 2 then
    error("Usage: upt remove <package1> [package2] ...")
  end
  for i = 2, #argv do
    if not fs.exists("/var/lib/upt/" .. argv[i]) then
      error("Package " .. argv[i] .. " not found!")
    end
    print("Removing package " .. argv[i])
    local f = fs.open("/var/lib/upt/" .. argv[i], "r")
    local x = f.readLine()
    local d = false
    while x do
      if x == "//DIRLIST" then
        x = f.readLine()
        d = true
        if not x then break end
      end
      if not d then
        fs.delete(x)
      else
        if #fs.list(x) == 0 then
          fs.delete(x)
        end
      end
      x = f.readLine()
    end
    f.close()
    fs.delete("/var/lib/upt/" .. argv[i])
    print("Removing package " .. argv[i] .. " done!")
  end
end

local function gitGetDir(gitPath, stripPath, path)
  path = fsd.normalizePath(path)
  gitPath = fsd.normalizePath(gitPath)
  local request = http.get("https://api.github.com/repos/TsarN/uber-os/contents" .. gitPath)
  local decoded = JSON:decode(request.readAll())
  for k, v in pairs(decoded) do
    if v.type == "dir" then
      fs.makeDir(path .. fsd.stripPath(stripPath, gitPath .. "/" .. v.name))
      gitGetDir(gitPath .. "/" .. v.name, stripPath, path)
    else
      local f = fs.open(path .. fsd.stripPath(stripPath, gitPath .. "/" .. v.name), "w")
      print("Downloading " .. gitPath .. "/" .. v.name)
      local r = http.get("https://raw.githubusercontent.com/TsarN/uber-os/master" .. gitPath .. "/" .. v.name)
      if not r then error("Cannot get file!") end
      f.write(r.readAll())
      r.close()
      f.close()
    end
  end
end

local function get()
  if #argv < 2 then
    error("Usage: upt get <package1> [package2] ...")
  end
  lua.include("libjson")
  print("Getting package list")
  if not http then error("Http API not enabled") end
  local request = http.get("https://api.github.com/repos/TsarN/uber-os/contents/packages")
  if not request then error("Cannot get package list. Make sure, that you have api.github.com whitelisted!") end
  local decoded = JSON:decode(request.readAll())
  request.close()
  local plist = {}
  for k, v in pairs(decoded) do
    if (v.name ~= "CONFIG") and (v.name ~= "Build.lua") then
      table.insert(plist, v.name)
    end
  end
  for i = 2, #argv do
    print("Downloading package " .. argv[i])
    gitGetDir("/packages/" .. argv[i], "/packages", "/usr/src")
    print("Downloading package " .. argv[i] .. " done!")
  end
end

if argv[1] == "install" then install() end

if argv[1] == "remove" then remove() end

if argv[1] == "get" then get() end

if argv[1] == "get-install" then
  get() install()
  for i = 2, #argv do
    print("Cleaning up " .. argv[i])
    fs.delete("/usr/src/" .. argv[i])
  end
end
