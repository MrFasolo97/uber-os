--Uber Packaging Tool

local argv = { ... }

lua.include("luamin")

if #argv < 1 then
  error("Usage: upt install|remove|get|get-install|update|upgrade")
end

local function getPkgInfo(package, forcerepo)
  local DEPENDS, VERSION
  if not forcerepo and fs.exists("/var/lib/upt/" .. package) then
    local f = fs.open("/var/lib/upt/" .. package, "r")
    DEPENDS = string.split(f.readLine(), " ")
    VERSION = string.split(f.readLine(), ";")
    f.close()
    return DEPENDS, VERSION 
  end
  local f = fs.open("/var/lib/upt/database", "r")
  for k, v in pairs(string.split(f.readAll(), "\n")) do
    local x = string.split(v, " ")
    VERSION = string.split(x[2], ";")
    DEPENDS = string.split(x[3], ";") 
    if x[1] == package then break end
  end
  f.close()
  return DEPENDS, VERSION 
end

function listDeps(package, notinstalled)
  getPkgInfo(package)
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

local function recursCopy(from, to)
  local l = fs.list(from)
  for k, v in pairs(l) do
    if fs.isDir(from .. "/" .. v) then
      if fs.exists(to .. "/" .. v) then
      else
        fs.makeDir(to .. "/" .. v)
      end
      recursCopy(from .. "/" .. v, to .. "/" .. v)
    else
      if fs.exists(to .. "/" .. v) then fs.delete(to .. "/" .. v) end
      fs.copy(from .. "/" .. v, to .. "/" .. v)
    end
  end
end

local function getInstalledPackages()
  local x = fs.list("/var/lib/upt")
  local r = {}
  for k, v in pairs(x) do
    if v == "database" then else
      r[v] = true
    end
  end
  return r
end

local function buildDependencyTree(packages, tree)
  if not tree then 
    tree = {}
    for k, v in pairs(packages) do tree[v] = true end
  end
  for i = 1, #packages do
    DEPENDS, VERSION = getPkgInfo(packages[i])
    for k, v in pairs(DEPENDS) do
      if getInstalledPackages()[v] or tree[v] or v == "" then else
        tree[v] = true
        buildDependencyTree({v}, tree)
      end
    end
  end
  return tree
end

local function install(packages, dontcheck)
  if not fs.exists("/var/lib/upt/database") then error("Database not found. Run 'upt update' to download it.") end
  local oldDir = shell.dir()
  for i = 1, #packages do
    if fs.exists("/usr/pkg/" .. packages[i]) then
      recursCopy("/usr/pkg/" .. packages[i], "")
      DEPENDS, VERSION = getPkgInfo(packages[i])
      local flist = fs.recursList("/usr/pkg/" .. packages[i])
      local f = fs.open("/var/lib/upt/" .. packages[i], "w")
      f.writeLine(table.concat(DEPENDS, " "))
      f.writeLine(table.concat(VERSION, ";"))
      for j = #flist, 1, -1 do
        local x = fsd.stripPath("/tmp/" .. packages[i], flist[j])
        if not fs.isDir(x) then
          f.write(x .. "\n")
        end
      end
      f.write("//DIRLIST\n")
      for j = #flist, 1, -1 do
        local x = fsd.stripPath("/tmp/" .. packages[i], flist[j])
        if fs.isDir(x) then
          f.write(x .. "\n")
        end
      end
      f.close()
      print("Package " .. packages[i] .. " installed from /usr/pkg")
      return
    end
    if not fs.exists("/usr/src/" .. packages[i]) then
      error("Package " .. packages[i] .. " not found!")
    end
    print("Building package " .. packages[i])
    shell.setDir("/usr/src/" .. packages[i])
    shell.run("/usr/src/" .. packages[i] .. "/PKGINFO.lua")
    if not dontcheck then
      print("Checking dependencies...")
      for k, v in pairs(DEPENDS) do
        if not fs.exists("/var/lib/upt/" .. v) then
          error("Dependency " .. v .. " not satisfied!")
        end
        print("Dependency " .. v .. " ok")
      end
      print("All dependencies satisfied")
    end
    shell.run("/usr/src/" .. packages[i] .."/Build.lua")
    fs.makeDir("/tmp/" .. packages[i])
    print("Installing package " .. packages[i])
    shell.run("/usr/src/" .. packages[i] .."/Build.lua install /tmp/" .. packages[i])
    shell.run("/usr/src/" .. packages[i] .."/Build.lua install")
    print("Registring package " .. packages[i])
    local flist = fs.recursList("/tmp/" .. packages[i])
    local f = fs.open("/var/lib/upt/" .. packages[i], "w")
    f.writeLine(table.concat(DEPENDS, " "))
    f.writeLine(table.concat(VERSION, ";"))
    for j = #flist, 1, -1 do
      local x = fsd.stripPath("/tmp/" .. packages[i], flist[j])
      if not fs.isDir(x) then
        f.write(x .. "\n")
      end
    end
    f.write("//DIRLIST\n")
    for j = #flist, 1, -1 do
      local x = fsd.stripPath("/tmp/" .. packages[i], flist[j])
      if fs.isDir(x) then
        f.write(x .. "\n")
      end
    end
    f.close()
    fs.delete("/tmp/" .. packages[i])
    print("Installing package " .. packages[i] .. " done!")
  end
  shell.setDir(oldDir)
end

local function remove(packages)
  if not fs.exists("/var/lib/upt/database") then error("Database not found. Run 'upt update' to download it.") end
  for i = 1, #packages do
    if not fs.exists("/var/lib/upt/" .. packages[i]) then
      error("Package " .. packages[i] .. " not found!")
    end
    print("Removing package " .. packages[i])
    local f = fs.open("/var/lib/upt/" .. packages[i], "r")
    f.readLine()
    f.readLine()
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

local function update()
  print("Updating package list...")
  local r = http.get("https://raw.githubusercontent.com/TsarN/uber-os/master/repo/repo.db")
  if not r then error("Failed to get package list!") end
  local f = fs.open("/var/lib/upt/database", "w")
  f.write(r.readAll())
  r.close()
  f.close()
  print("Package list updated")
end

local function get(packages)
  if not fs.exists("/var/lib/upt/database") then error("Database not found. Run 'upt update' to download it.") end
  if not http then error("Http API not enabled") end
  local pkglist
  if not fs.exists("/var/lib/upt/database") then update() end
  local flist = fs.open("/var/lib/upt/database", "r")
  pkglist = string.split(flist.readAll(), "\n")
  for k, v in pairs(pkglist) do pkglist[k] = string.split(v, " ")[1] end
  flist.close()
  for i = 1, #packages do
    local flag = true
    for k, v in pairs(pkglist) do
      if packages[i] == v then
        flag = false
      end
    end
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
    if fs.exists("/usr/pkg/" .. packages[i]) then fs.delete("/usr/pkg/" .. packages[i]) end
    fs.makeDir("/usr/pkg/" .. packages[i])
    archive.unpack("/tmp/" .. packages[i], "/usr/pkg/" .. packages[i])
    fs.delete("/tmp/" .. packages[i])
    print("Downloading package " .. packages[i] .. " done!")
  end
end

local function getInstall(packages)
  if not fs.exists("/var/lib/upt/database") then error("Database not found. Run 'upt update' to download it.") end
  local flist = fs.open("/var/lib/upt/database", "r")
  pkglist = string.split(flist.readAll(), "\n")
  for k, v in pairs(pkglist) do pkglist[k] = string.split(v, " ")[1] end
  flist.close()
  for i = 1, #packages do
    local flag = true
    for k, v in pairs(pkglist) do
      if packages[i] == v then
        flag = false
      end
    end
    if flag then error("Package not found!") end
  end
  print("Building dependency tree...")
  local tree = buildDependencyTree(packages)
  print("Following packages will be installed/upgraded:")
  for k, v in pairs(tree) do
    write(k .. ":")
    DEPENDS, VERSION = getPkgInfo(k, true)
    write(table.concat(VERSION, ".") .. " ")
  end
  print()
  write("Confirm? [Y/n]: ")
  local x = read()
  if x == "n" or x == "N" then return end
  for k, v in pairs(tree) do get({k}) end
  for k, v in pairs(tree) do install({k}, true) end
end

local function upgrade()
  local p = getInstalledPackages()
  local toupg = {}
  for k, v in pairs(p) do
    DEPENDS1, VERSION1 = getPkgInfo(k, true)
    DEPENDS, VERSION = getPkgInfo(k)
    local flag = false
    for i = 1, 3 do
      if VERSION1[i] > VERSION[i] then flag = true break end
    end
    if flag then
      table.insert(toupg, k)
    end
  end
  getInstall(toupg)
end

local p = {}

for i = 2, #argv do table.insert(p, argv[i]) end

if argv[1] == "install" then 
  if #argv < 2 then
    error("Usage: upt install <package1> [package2] ...")
  end
  install(p)
end

if argv[1] == "update" then 
  update()
end

if argv[1] == "upgrade" then 
  upgrade()
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
  getInstall(p)
end
