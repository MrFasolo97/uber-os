--Build UberOS from inside UberOS
local PACKAGES = {"corelib", "coreutils", "fsdrv", "init", "libjson", "login", "luamin", "uberkernel", "uboot", "udev", "ush"}
local INSTALL_DIR = ""
local PWD = shell.dir()

local function populatefs()
  fs.makeDir(INSTALL_DIR .. "/bin")
  fs.makeDir(INSTALL_DIR .. "/boot")
  fs.makeDir(INSTALL_DIR .. "/dev")
  fs.makeDir(INSTALL_DIR .. "/etc")
  fs.makeDir(INSTALL_DIR .. "/home")
  fs.makeDir(INSTALL_DIR .. "/lib")
  fs.makeDir(INSTALL_DIR .. "/root")
  fs.makeDir(INSTALL_DIR .. "/sbin")
  fs.makeDir(INSTALL_DIR .. "/sys")
  fs.makeDir(INSTALL_DIR .. "/tmp")
  fs.makeDir(INSTALL_DIR .. "/var")
  fs.makeDir(INSTALL_DIR .. "/usr")
  fs.makeDir(INSTALL_DIR .. "/usr/share")
  fs.makeDir(INSTALL_DIR .. "/usr/bin")
  fs.makeDir(INSTALL_DIR .. "/usr/lib")
  fs.makeDir(INSTALL_DIR .. "/usr/local")
  fs.makeDir(INSTALL_DIR .. "/usr/src")
  fs.makeDir(INSTALL_DIR .. "/usr/include")
  fs.makeDir(INSTALL_DIR .. "/usr/pkg")
  fs.makeDir(INSTALL_DIR .. "/var/lib")
  fs.makeDir(INSTALL_DIR .. "/var/lock")
  fs.makeDir(INSTALL_DIR .. "/var/log")
  fs.makeDir(INSTALL_DIR .. "/etc/init.d")
  fs.makeDir(INSTALL_DIR .. "/lib/modules")
  fs.makeDir(INSTALL_DIR .. "/lib/drivers")
end

local function install(source)
  if not source then return end
  shell.setDir(PWD .. "/" .. source)
  shell.run("Build.lua clean")
  shell.run("Build.lua")
  shell.run("Build.lua install /" .. INSTALL_DIR)
  shell.run("Build.lua clean")
  shell.setDir(PWD)
end

local function configure()
  pcall(fs.copy, PWD .. "/CONFIG/etc/passwd", INSTALL_DIR .. "/etc/passwd")
  pcall(fs.copy, PWD .. "/CONFIG/etc/motd", INSTALL_DIR .. "/etc/motd")
  pcall(fs.copy, PWD .. "/CONFIG/etc/issue", INSTALL_DIR .. "/etc/issue")
  pcall(fs.copy, PWD .. "/CONFIG/etc/fstab", INSTALL_DIR .. "/etc/fstab")
  pcall(fs.copy, PWD .. "/CONFIG/etc/rc.d", INSTALL_DIR .. "/etc/rc.d")
end

local argv = { ... }

if #argv == 0 then

  if not lua then print("WARNING: Building unminified!") lua = {include = function() end} minify = function(a) return a end end

  local s = ""
  write("Enter directory to install: /")
  INSTALL_DIR = read()
  write("Enter packages to install(default=all): ")
  s = read()
  if string.len(s) == 0 then
    populatefs()
    for k, v in pairs(PACKAGES) do
      install(v)
      sleep(0.05) -- Too long without yielding can occur
    end
    configure()
  else
    populatefs()
    local pkg = ""
    for i = 1, string.len(s) do
      if string.sub(s, i, i) ~= " " then
        pkg = pkg .. string.sub(s, i, i)
      else
        install(pkg)
        pkg = ""
      end
    end
    configure()
  end
else
  if argv[1] == "populatefs" then INSTALL_DIR = argv[2] or "/" populatefs() end
  if argv[1] == "configure" then INSTALL_DIR = argv[2] or "/" configure() end
end
