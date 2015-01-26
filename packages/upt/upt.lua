--Uber Packaging Tool

local argv = { ... }

lua.include("luamin")

if #argv < 1 then
  error("Usage: upt install|remove|get|get-install")
end

function listDeps(package, notinstalled)
  notinstalled = true
  shell.run("/usr/src/" .. package .. "/PKGINFO.lua")
  local d = {}
  for k, v in pairs(DEPENDS) do
    if notisntalled then
      if not fs.exists("/var/lib/upt/" .. v) then
        table.insert(d, v)
      end
    else
      table.insert(d, v)
    end
  end
  return d
end

local function install(packages)
  local oldDir = shell.dir()
  for i = 1, #packages do
    if not fs.exists("/usr/src/" .. packages[i]) then
      error("Package " .. packages[i] .. " not found!")
    end
    print("Building package " .. packages[i])
    shell.setDir("/usr/src/" .. packages[i])
    shell.run("/usr/src/" .. packages[i] .. "/PKGINFO.lua")
    print("Checking dependencies...")
    for k, v in pairs(DEPENDS) do
      if not fs.exists("/var/lib/upt/" .. v) then
        error("Dependency " .. v .. " not satisfied!")
      end
      print("Dependency " .. v .. " ok")
    end
    print("All dependencies satisfied")
    shell.run("/usr/src/" .. packages[i] .."/Build.lua")
    fs.makeDir("/tmp/" .. packages[i])
    print("Installing package " .. packages[i])
    shell.run("/usr/src/" .. packages[i] .."/Build.lua install /tmp/" .. packages[i])
    shell.run("/usr/src/" .. packages[i] .."/Build.lua install")
    print("Registring package " .. packages[i])
    local flist = fs.recursList("/tmp/" .. packages[i])
    --print(textutils.serialize(flist)) 
    local f = fs.open("/var/lib/upt/" .. packages[i], "w")
    for j = #flist, 1, -1 do
      local x = fsd.stripPath("/tmp/" .. packages[i], flist[j])
      if not fs.isDir(x) then
        f.write(x .. "\n")
      end
      --print("Not a dir: " .. x)
    end
    f.write("//DIRLIST\n")
    for j = #flist, 1, -1 do
      local x = fsd.stripPath("/tmp/" .. packages[i], flist[j])
      if fs.isDir(x) then
        f.write(x .. "\n")
      end
      --print("A dir: " .. x)
    end
    f.close()
    fs.delete("/tmp/" .. packages[i])
    print("Installing package " .. packages[i] .. " done!")
  end
  shell.setDir(oldDir)
end

local function remove(packages)
  for i = 1, #packages do
    if not fs.exists("/var/lib/upt/" .. packages[i]) then
      error("Package " .. packages[i] .. " not found!")
    end
    print("Removing package " .. packages[i])
    local f = fs.open("/var/lib/upt/" .. packages[i], "r")
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
    fs.delete("/var/lib/upt/" .. packages[i])
    print("Removing package " .. packages[i] .. " done!")
  end
end

local function get(packages)
  lua.include("libjson")
  if not http then error("Http API not enabled") end
  for i = 1, #packages do
    if flag then error("Package not found!") end
    print("Downloading package " .. packages[i])
    local r = http.get("https://raw.githubusercontent.com/TsarN/uber-os/master/repo/" .. packages[i] .. ".utar")
    if not r then error("Failed to download " .. packages[i] .. "! Make sure, that you have raw.githubusercontent.com whitelisted or try again later.") end
    print("Saving package " .. packages[i])
    local f = fs.open("/tmp/" .. packages[i], "w") 
    f.write(r.readAll())
    f.close()
    r.close()
    print("Unpacking package " .. packages[i])
    lua.include("libarchive")
    if fs.exists("/usr/src/" .. packages[i]) then fs.delete("/usr/src/" .. packages[i]) end
    fs.makeDir("/usr/src/" .. packages[i])
    archive.unpack("/tmp/" .. packages[i], "/usr/src/" .. packages[i])
    fs.delete("/tmp/" .. packages[i])
    print("Downloading package " .. packages[i] .. " done!")
  end
end

local function getInstall(package)
  if fs.exists("/var/lib/upt/" .. package) then return end --Quick fix
  get({package})
  fs.open("/var/lib/upt/" .. package, "w").close()
  local d = listDeps(package, true)
  for k, v in pairs(d) do
    getInstall(v)
  end
  install({package})
end

local p = {}

for i = 2, #argv do table.insert(p, argv[i]) end

if argv[1] == "install" then 
  if #argv < 2 then
    error("Usage: upt install <package1> [package2] ...")
  end
  install(p)
end

if argv[1] == "remove" then 
  if #argv < 2 then
    error("Usage: upt remove <package1> [package2] ...")
  end
  remove(p)
end

if argv[1] == "get" then 
  if #argv < 2 then
    error("Usage: upt get <package1> [package2] ...")
  end
  get(p)
end

if argv[1] == "get-install" then
  if #argv < 2 then
    error("Usage: upt get-install <package1> [package2] ...")
  end
  for k, v in pairs(p) do fs.delete("/var/lib/upt/" .. v) getInstall(v) end
end
