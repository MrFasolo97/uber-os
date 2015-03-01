--Uber Packaging Tool

local argv = { ... }

lua.include("luamin")

if #argv < 1 then
  print("Usage: upt install|force-install|remove|get|get-install|update|upgrade|force-upgrade|list|list-installed")
  return
end

local db = {}
local tree = {}
local repourls = {}
local repopkgs = {}

local function parseDatabase()
  if not fs.exists("/var/lib/upt/db/general") then printError("Database not found") error() end
  db = {}
  tree = {}
  repourls = {}
  repopkgs = {}
  print("Parsing database...")
  local gen = fs.open("/var/lib/upt/db/general", "r")
  local databases = string.split(gen.readAll(), "\n")
  gen.close()
  for _, repo in pairs(databases) do
    local tmp = string.split(repo, " ")
    local name = tmp[1]
    local url = tmp[2]
    repourls[name] = url
    tree[url] = {}
    if not fs.exists("/var/lib/upt/db/" .. name .. ".db") then
      printError("Database not found. Run 'upt update' to download it.")
      error()
    end
    local f = fs.open("/var/lib/upt/db/" .. name .. ".db", "r")
    local isDir = false
    for k, v in pairs(string.split(f.readAll(), "\n")) do
      if v == "//DIRLIST" then isDir = true else
        if isDir then
          local x = string.split(v:sub(3), "/")
          local y = tree[url]
          local fullPath = ""
          for K, V in pairs(x) do
            fullPath = fullPath .. "/" .. V
            if not y[V] then 
              if fullPath == v:sub(2) and v:sub(1, 1) == "F" then
                y[V] = true
                break
              else
                y[V] = {}
              end
            end
            y = y[V]
          end
        else
          local x = string.split(v, " ")
          db[x[1]] = {}
          for _, d in pairs({db[x[1]]}) do
            d.VERSION = x[2]
            d.DEPENDS = string.split(x[3], ";")
            d.REPO = name
          end
        end
      end
    end
    f.close()
  end
  print("Parsing database done!")
end

local function getPkgInfo(package, forcerepo)
  local DEPENDS, VERSION
  if not forcerepo and fs.exists("/var/lib/upt/" .. package) then
    local f = fs.open("/var/lib/upt/" .. package, "r")
    DEPENDS = string.split(f.readLine(), " ")
    VERSION = f.readLine()
    f.close()
    return DEPENDS, VERSION 
  end
  return db[package].DEPENDS, db[package].VERSION 
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
    if v == "db" then else
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
  local oldDir = shell.dir()
  local todo = {}
  for k, v in pairs(packages) do
    todo[v] = true
  end
  for i = 1, #packages do
    sleep(0.05)
    if fs.exists("/usr/pkg/" .. packages[i]) then
      recursCopy("/usr/pkg/" .. packages[i], "")
      DEPENDS, VERSION = getPkgInfo(packages[i])
      local flist = fs.recursList("/usr/pkg/" .. packages[i])
      local f = fs.open("/var/lib/upt/" .. packages[i], "w")
      f.writeLine(table.concat(DEPENDS, " "))
      f.writeLine(VERSION)
      for j = #flist, 1, -1 do
        local x = fsd.stripPath("/usr/pkg/" .. packages[i], flist[j])
        if not fs.isDir(x) then
          f.write(x .. "\n")
        end
      end
      f.write("//DIRLIST\n")
      for j = #flist, 1, -1 do
        local x = fsd.stripPath("/usr/pkg/" .. packages[i], flist[j])
        if fs.isDir(x) then
          f.write(x .. "\n")
        end
      end
      f.close()
      print("Package " .. packages[i] .. " installed from /usr/pkg")
      return
    end
    if not fs.exists("/usr/src/" .. packages[i]) then
      printError("Package " .. packages[i] .. " not found!") return
    end
    print("Building package " .. packages[i])
    shell.setDir("/usr/src/" .. packages[i])
    shell.run("/usr/src/" .. packages[i] .. "/PKGINFO.lua")
    if not dontcheck then
      print("Checking dependencies...")
      for k, v in pairs(DEPENDS) do
        if not fs.exists("/var/lib/upt/" .. v) and not todo[v] then
          printError("Dependency " .. v .. " not satisfied!")
          shell.setDir(oldDir)
          return
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
    f.writeLine(VERSION)
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
  print()
  write("Confirm? [Y/n]: ")
  local x = read()
  if x == "n" or x == "N" then return end
  for i = 1, #packages do
    if not fs.exists("/var/lib/upt/" .. packages[i]) then
      printError("Package " .. packages[i] .. " not found!") return
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
  local gen = fs.open("/var/lib/upt/db/general", "r")
  local databases = string.split(gen.readAll(), "\n")
  gen.close()
  for k, v in pairs(databases) do
    local tmp = string.split(v, " ")
    local name = tmp[1]
    local url = tmp[2]
    local r = http.get(url .. "/" .. name .. ".db")
    if not r then printError("Failed to get " .. name) return end
    local f = fs.open("/var/lib/upt/db/" .. name .. ".db", "w")
    f.write(r.readAll())
    r.close()
    f.close()
    print(name .. " updated")
  end
  print("Package list updated")
end

local function getDir(remotePath, stripPath, path, t, remoteUrl)
  path = fsd.normalizePath(path)
  remotePath = fsd.normalizePath(remotePath)
  t = t or tree[remoteUrl][remotePath:sub(2)]
  for k, v in pairs(t) do
    if type(v) == "table" then
      fs.makeDir(path .. fsd.stripPath(stripPath, remotePath .. "/" .. k))
      getDir(remotePath .. "/" .. k, stripPath, path, v, remoteUrl)
    else
      local f = fs.open(path .. fsd.stripPath(stripPath, remotePath .. "/" .. k), "w")
      print("Downloading " .. remoteUrl .. "/packages" .. remotePath .. "/" .. k)
      local r = http.get(remoteUrl .. "/packages" .. remotePath .. "/" .. k)
      if not r then printError("Cannot get file!") thread.kill(coroutine.running(), "TERM") end
      f.write(r.readAll())
      r.close()
      f.close()
    end
  end
end

local function get(packages)
  for i = 1, #packages do
    local flag = true
    for k, v in pairs(db) do
      if packages[i] == k then
        flag = false
      end
    end
    if flag then printError("Package not found!") return end
    print("Downloading package " .. packages[i])
    --[[local r = http.get("https://raw.githubusercontent.com/TsarN/uber-os/master/repo/" .. packages[i] .. ".utar")
    if not r then printError("Failed to download " .. packages[i] .. "! Make sure, that you have raw.githubusercontent.com whitelisted or try again later.") return end
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
    fs.delete("/tmp/" .. packages[i])]]

    getDir(packages[i], "/", "/usr/src", nil, repourls[db[packages[i]].REPO])

    print("Downloading package " .. packages[i] .. " done!")
  end
end

local function getInstall(packages)
  for i = 1, #packages do
    local flag = true
    for k, v in pairs(db) do
      if packages[i] == k then
        flag = false
      end
    end
    if flag then printError("Package not found!") return end
  end
  print("Building dependency tree...")
  local tree = buildDependencyTree(packages)
  print("Following packages will be installed/upgraded:")
  for k, v in pairs(tree) do
    write(k .. ":")
    DEPENDS, VERSION = getPkgInfo(k, true)
    write(VERSION .. " ")
  end
  print()
  write("Confirm? [Y/n]: ")
  local x = read()
  if x == "n" or x == "N" then return end
  for k, v in pairs(tree) do get({k}) end
  for k, v in pairs(tree) do install({k}, true) end
end

local function upgrade(force)
  local p = getInstalledPackages()
  local toupg = {}
  for k, v in pairs(p) do
    DEPENDS1, VERSION1 = getPkgInfo(k, true)
    DEPENDS, VERSION = getPkgInfo(k)
    local flag = false
    if VERSION1 > VERSION then flag = true break end
    if force and VERSION1 ~= VERSION then flag = true break end
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
    print("Usage: upt install <package1> [package2] ...") return
  end
  parseDatabase()
  install(p)
end

if argv[1] == "force-install" then 
  if #argv < 2 then
    print("Usage: upt force-install <package1> [package2] ...") return
  end
  parseDatabase()
  install(p, true)
end

if argv[1] == "update" then 
  update()
end

if argv[1] == "upgrade" then 
  parseDatabase()
  upgrade()
end

if argv[1] == "force-upgrade" then
  parseDatabase()
  upgrade(true)
end

if argv[1] == "remove" then 
  if #argv < 2 then
    print("Usage: upt remove <package1> [package2] ...") return
  end
  parseDatabase()
  remove(p)
end

if argv[1] == "get" then 
  if #argv < 2 then
    print("Usage: upt get <package1> [package2] ...") return
  end
  parseDatabase()
  get(p)
end

if argv[1] == "get-install" then
  if #argv < 2 then
    print("Usage: upt get-install <package1> [package2] ...") return
  end
  parseDatabase()
  getInstall(p)
end

if argv[1] == "list" then
  parseDatabase()
  local s = ""
  for k, v in pairs(db) do
    s = s .. v.REPO .. "/" .. k .. " " .. v.VERSION .. "\n"
  end
  textutils.pagedPrint(s)
end

if argv[1] == "list-installed" then
  local s = ""
  for k, v in pairs(getInstalledPackages()) do
    local f = fs.open("/var/lib/upt/" .. k, "r")
    f.readLine()
    s = s .. k .. " " .. table.concat(string.split(f.readLine(), ";"), ".") .. "\n"
  end
  textutils.pagedPrint(s)
end
