--Build this package from inside UberOS
lua.include("min")
local SRC = {"udevd", "udev"}
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

local function build(source)
  if not source then for k, v in pairs(SRC) do build(v) end return end
  local f = fs.open(PWD .. "/" .. source .. EXTIN, "r")
  local c = f.readAll()
  f.close()
  c = minify(c)
  f = fs.open(PWD .. "/out/" .. source .. EXTOUT, "w")
  f.write(c)
  f.close()
end

local function install(root)
  root = root or ""
  pcall(fs.copy, PWD .. "/out/udev", root .. "/sbin/udev")
  pcall(fs.copy, PWD .. "/out/udevd", root .. "/etc/init.d/udevd")
end

if #argv == 0 then clean() prepare() build() return end

if argv[1] == "clean" then clean() return end
if argv[1] == "prepare" then prepare() return end
if argv[1] == "build" then build(argv[2]) return end
if argv[1] == "install" then install(argv[2]) return end
