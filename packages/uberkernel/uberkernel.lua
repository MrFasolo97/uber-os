--UberKernel
KERNEL_DIR = fs.getDir(shell.getRunningProgram())
ROOT_DIR   = fs.getDir(KERNEL_DIR)
local oldprint = print
local oldwrite = write
local oldread  = read
local kernelCoroutine = coroutine.running()

--Unloading CraftOS APIs
os.unloadAPI("io")
local olderror = error

error = function(msg)
  if not msg then olderror() return end
  if term.isColor() then
    term.setTextColor(colors.red)
    print(msg)
    term.setTextColor(colors.white)
    olderror()
  else
    print(msg)
    olderror()
  end
end

argv = { ... }
local absoluteReadOnly = {readonlytable}

local ttys = {} --6 ttys that actually windows
local curTty = 0

local oldfs = fs

--Boot flags
local fDebug = false
local fSilent = false
local fNoPanic = false
local fLog = false

local eventStack = {}

local loadedModules = {}

local threadManager = nil

function applyreadonly(table)
  local tmp = {}
  setmetatable(tmp, {
    __index = table,
    __newindex = function(table, key, value)
      error("Attempt to modify read-only table")
    end,
    __metatable = false
  })
  absoluteReadOnly[#absoluteReadOnly + 1] = tmp
  return tmp
end

local function initTtys()
  local w, h = term.getSize()
  for i = 1, 6 do
    ttys[i] = window.create(term.native(), 1, 1, w, h, false)
  end
end

function setTty(tty)
  if (tty < 1) or (tty > 6) then
    error("Invalid TTY")
  end
  for i = 1, 6 do ttys[i].setVisible(false) end
  ttys[tty].setVisible(true)
  term.redirect(ttys[tty])
  curTty = tty
end

function getTty()
  return curTty
end

local oldrawset = rawset
rawset = function(table, index, value)
  for i = 1, #absoluteReadOnly do
    if (table == absoluteReadOnly[i]) or (index == absoluteReadOnly[i]) then
      error("Attempt to modify read-only table")
      return 
    end
  end
  oldrawset(table, index, value)
end

local oldPullEvent = os.pullEvent
local oldPullEventRaw = os.pullEventRaw
kernel = {}
kernel.root = ROOT_DIR
kernel.panic = function(msg)
  write("[" .. os.clock() .. "] Kernel panic: " .. msg)
  if fNoPanic then
    print(" ... no panic is active! Contining...")
  else
    if thread then
      thread.onPanic(kernelCoroutine)
    else
    while true do
      coroutine.yield()
    end
    end
  end
end

kernel.log = function(msg)
  local logmsg = "[" .. os.clock() .. "] " .. msg
  if not fSilent then
    oldwrite(logmsg .. "\n")
  end
  local logFile 
  if fLog then
    if oldfs.exists("/" .. KERNEL_DIR .. "/log") then
      logFile = oldfs.open("/" .. KERNEL_DIR .. "/log", "a")
    else
      logFile = oldfs.open("/" .. KERNEL_DIR .. "/log", "w")
    end
    logFile.write(logmsg .. "\n")
    logFile.close()
  end
end

kernel.loadModule = function(module, panic)
  for i = 1, #loadedModules do
    if loadedModules[i] == module then
      return true
    end
  end
  kernel.log("Loading module " .. module)
  status, err = pcall(shell.run, ROOT_DIR .. "/lib/modules/" .. module)
  if status then
    kernel.log("Loading module DONE")
    table.insert(loadedModules, module)
    return true
  else
    kernel.log("Loading module FAILED")
    if panic then
      kernel.panic("Failed to load module " .. module .. "\nError: " .. err)
    else
      error("Failed to load module" .. module .. "\nError: " .. err)
    end
  end
end

kernel.getLastEvent = function()
  return #eventStack
end

kernel.pullEvent = function()
  local lastEvent = #eventStack
  while #eventStack <= lastEvent do
    lastEvent = thread.getLastEvent(thread.getPID(coroutine.running()))
    sleep(0.05)
  end
  thread.setLastEvent(thread.getPID(coroutine.running()), lastEvent + 1)
  return eventStack[lastEvent + 1].event,
         eventStack[lastEvent + 1].a,
         eventStack[lastEvent + 1].b,
         eventStack[lastEvent + 1].c,
         eventStack[lastEvent + 1].d,
         eventStack[lastEvent + 1].e
end

kernel.sendEvent = function(event, a, b, c, d, e)
  if event == "THREADDEAD" then
    if coroutine.running() ~= threadManager then
      kernel.log("Fake THREADDEAD event")
      return false
    end
  end
  eventStack[#eventStack + 1] = {
    ["event"] = event,
    ["a"] = a,
    ["b"] = b,
    ["c"] = c,
    ["d"] = d,
    ["e"] = e
  }
  return true
end

kernel.registerThreadManager = function(cr)
  if not threadManager then
    threadManager = cr
  end
end

kernel.LISTMODULES = function()
  return fs.list(ROOT_DIR .. "/lib/modules")
end

kernel.LISTFLAGS = function()
  return {"Debug", "Silent", "NoPanic", "Log"}
end

local function start()
  kernel.log("Boot directory = /" .. KERNEL_DIR)
  kernel.log("Root directory = /" .. ROOT_DIR)
  if fs.exists("/" .. KERNEL_DIR .. "/log") then
    fs.delete("/" .. KERNEL_DIR .. "/log")
  end
  if fs.exists(ROOT_DIR .. "/tmp") and fs.isDir(ROOT_DIR .. "/tmp") then
    for k, v in pairs(fs.list(ROOT_DIR .. "/tmp")) do
      fs.delete(ROOT_DIR .. "/tmp/" .. v)
    end
    for k, v in pairs(fs.list(ROOT_DIR .. "/var/lock")) do
      fs.delete(ROOT_DIR .. "/tmp/" .. v)
    end
  end

  -- Setup paths
  local sPath = ".:" .. ROOT_DIR .."/bin:" .. ROOT_DIR .. "/sbin:" .. ROOT_DIR .. "/etc/init.d"
  shell.setPath( sPath )
  shell.setPath = nil

  -- Setup aliases
  shell.setAlias( "ls", ROOT_DIR .. "/bin/ls")
  shell.setAlias( "cp", ROOT_DIR .. "/bin/cp" )
  shell.setAlias( "mv", ROOT_DIR .. "/bin/mv" )
  shell.setAlias( "rm", ROOT_DIR .. "/bin/rm" )
  shell.setAlias( "clr", ROOT_DIR .. "/bin/clear" )
  shell.setAlias( "sh", ROOT_DIR .. "/bin/ush")

  os.pullEventRaw = function(a)
    if thread then
      local k = thread.isKilled(coroutine.running())
      if k >= 2 then
        kernel.log("Killed process. PID = " .. thread.getPID(coroutine.running()))
        error() --Kill Process
      end
      if k == 1 then
        return "terminate"
      end
    end
    return oldPullEventRaw(a)
  end
  
  os.pullEvent = os.pullEventRaw
  initTtys()
  local modules
  if #argv <= 1 then
    kernel.loadModule("lua", true) --Main dependency
    modules = fs.list(ROOT_DIR .. "/lib/modules")
  else
    modules = {}
    for i = 2, #argv do
      if string.sub(argv[i], 1, 1) == "m" then
        table.insert(modules, string.sub(argv[i], 2, #argv[i]))
      end
    end
  end
  for i = 1, #modules do
    kernel.loadModule(modules[i], true)
  end
  if fsd then
    fs = fsd
    loadfile = newloadfile
  end
  shell.run(ROOT_DIR .. "/sbin/thread")
end

local function stop()
  os.pullEvent = oldPullEvent
  os.pullEventRaw = oldPullEventRaw
end

kernel = applyreadonly(kernel)

if #argv == 0 then
  return
end

if argv[1] == "start" then
  if #argv > 1 then
    for i = 2, #argv do
      if argv[i] == "fDebug" then fDebug = true end
      if argv[i] == "fNoPanic" then fNoPanic = true end
      if argv[i] == "fLog" then fLog = true end
      if argv[i] == "fSilent" then fSilent = true end
    end
  end
  start()
  return
end

if argv[1] == "unload" then
  stop()
  return
end

if argv[1] == "restart" then
  os.reboot()
end

if argv[1] == "stop" then
  os.shutdown()
end

