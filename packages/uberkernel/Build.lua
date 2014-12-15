--Build this package from inside UberOS
lua.include("min")
local SRC = {"thread", "uberkernel", "kerneld"}
local SRC_MODULES = {"fsd", "lua", "users"}
local PWD = shell.dir()
local EXTIN = ".lua"
local EXTOUT = ""
local argv = { ... }

local function clean()
  fs.delete(PWD .. "/out")
end

local function prepare()
  fs.makeDir(PWD .. "/out")
end

local function build(source, module)
  if not source then for k, v in pairs(SRC) do build(v) end end
  if not source then for k, v in pairs(SRC_MODULES) do build(v, true) end return end
  local f
  if not module then 
    f = fs.open(PWD .. "/" .. source .. EXTIN, "r")
  else
    f = fs.open(PWD .. "/modules/" .. source .. EXTIN, "r")
  end
  local c = f.readAll()
  f.close()
  c = minify(c)
  f = fs.open(PWD .. "/out/" .. source .. EXTOUT, "w")
  f.write(c)
  f.close()
end

local function install(root)
  root = root or ""
  pcall(fs.copy, PWD .. "/out/uberkernel", root .. "/boot/uberkernel")
  pcall(fs.copy, PWD .. "/out/thread", root .. "/sbin/thread")
  pcall(fs.copy, PWD .. "/out/kerneld", root .. "/etc/init.d/kerneld")
  for k, v in pairs(SRC_MODULES) do
     pcall(fs.copy, PWD .. "/out/" .. v, root .. "/lib/modules/" .. v)
  end
end

if #argv == 0 then clean() prepare() build() return end

if argv[1] == "clean" then clean() return end
if argv[1] == "prepare" then prepare() return end
if argv[1] == "build" then build(argv[2]) return end
if argv[1] == "install" then install(argv[2]) return end
