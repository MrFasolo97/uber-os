--UberKernel
KERNEL_DIR = fs.getDir(shell.getRunningProgram())
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

local threadMan = function()
  kernel.log("Starting thread manager")

  lua.include("copy")

  local threads = {}
  local starting = {}
  local eventFilter = nil
  local initRan = false
  local daemons = {}
  local isPanic = false
  thread = {["kerneld"] = 0}

  local newStdin = function()
    return {isStdin = true}
  end

  local newStdout = function()
    return {isStdout = true}
  end

  rawset(thread, "onPanic", function(k)
    if k == kernelCoroutine then
      isPanic = true
    end
  end)

  rawset(thread, "newPID", function()
    if not initRan then
      initRan = true
      return 1
    end
    local flag = true
    while true do
      local pid = math.random(2, 32767)
      for i = 1, #threads do
        if threads[i].pid == pid then
          flag = false
          break
        end
      end
      if flag then
        return pid
      end
    end
  end)
   
  rawset(thread, "startThread", function(fn, blockTerminate, desc, uid, stdin, stdout, daemon)
    if thread.getUID(coroutine.running()) ~= 0 then
      daemon = nil
    end
    local newpid = thread.newPID()
    if not uid then
      uid = 0
    end
    if not ((newpid == 1) or (uid == thread.getUID(coroutine.running())) or
      (0 == thread.getUID(coroutine.running()))) then
      uid = thread.getUID(coroutine.running())
    end
    table.insert(starting, {
      cr = coroutine.create(fn),
      blockTerminate = blockTerminate or false,
      error = nil,
      dead = false,
      filter = nil,
      kill = 0,
      pid = newpid,
      lastevent = kernel.getLastEvent(),
      ppid = thread.getPID(coroutine.running()),
      desc = desc or "",
      uid = uid,
      stdin = stdin or newStdin(),
      stdout = stdout or newStdout(),
      daemon = daemon
    })
    return newpid, starting[#starting]
  end)

  rawset(thread, "runFile", function(file, blockTerminate, pause, uid, stdin, stdout, daemon)
    local pid, t = thread.startThread(function()
      shell.run(file)
    end, blockTerminate or true, daemon or file, uid or thread.getUID(coroutine.running()), stdin, stdout, daemon)
    if daemon and (thread.getUID(coroutine.running()) == 0) then
      t.ppid = 1
    end
    if pause then
      while true do
        local event, e1, e2, e3, e4, e5 = kernel.pullEvent()
        if (event == "THREADDEAD") and (e1 == pid) then
          return
        end
      end
    else
      return pid
    end
  end)

  rawset(thread, "runDaemon", function(file, name)
    if thread.getUID(coroutine.running()) ~= 0 then
      kernel.log("Cannot start daemon " .. name .. " - Access denied!")
      return 
    end
    if daemons[name] then
      kernel.log("Daemon " .. name .. " is already running.")
      return
    end
    local pid = thread.runFile(file, true, false, nil, nil, nil, name)
    daemons[name] = pid
    fs.open("/var/lock/" .. name, "w").close()
    kernel.log("Daemon " .. name .. " started")
  end)

  rawset(thread, "stopDaemon", function(name)
    if thread.getUID(coroutine.running()) ~= 0 then
      kernel.log("Cannot stop daemon " .. name .. " - Access denied!")
      return
    end
    if not daemons[name] then
      kernel.log("Daemon " .. name .. " is not running.")
      return
    end
    thread.kill(daemons[name], 2)
    daemons[name] = nil
    fs.delete("/var/lock/" .. name)
    kernel.log("Daemon " .. name .. " stopped")
  end)

  rawset(thread, "getDaemonStatus", function(name)
    if daemons[name] then
      return "running"
    else
      return "stopped"
    end
  end)

  rawset(thread, "getLastEvent", function(pid)
    if pid == 0 then
      return 0
    end
    local x = thread.status(pid).lastEvent
    if x then
      return x
    else
      return 0
    end
  end)

  rawset(thread, "setLastEvent", function(pid, newLastEvent)
    thread.status(pid).lastEvent = newLastEvent
  end)

  rawset(thread, "kill", function(pid, level)
    if pid == 1 then
      kernel.log("Failed to kill init")
      return 
    end

    for i = 1, #threads do
      if threads[i].pid == pid then
        if (threads[i].uid == thread.getUID(coroutine.running())) or
        (thread.getUID(coroutine.running()) == 0) then
          threads[i].kill = level
        else
          kernel.log("Failed to kill process " .. pid .. " - Access Denied")
        end
      end
    end
  end)

  rawset(thread, "isKilled", function(cr)
    for i = 1, #threads do
      if threads[i].cr == cr then
        return threads[i].kill
      end
    end
    for i = 1, #starting do
      if starting[i].cr == cr then
        return starting[i].kill
      end
    end
    return 0
  end)

  rawset(thread, "getPID", function(cr)
    for i = 1, #threads do
      if threads[i].cr == cr then
        return threads[i].pid
      end
    end
    for i = 1, #starting do
      if starting[i].cr == cr then
        return starting[i].pid
      end
    end
    return 0
  end)

  rawset(thread, "getUID", function(cr)
    for i = 1, #threads do
      if threads[i].cr == cr then
        return threads[i].uid
      end
    end
    for i = 1, #starting do
      if starting[i].cr == cr then
        return starting[i].uid
      end
    end
    return 0
  end)


  rawset(thread, "getRunningThreads", function(cr)
    return threads
  end)

  rawset(thread, "status", function(pid)
    for i = 1, #threads do
      if threads[i].pid == pid then
        return threads[i]
      end
    end
    return nil
  end)

  local oldPrint = print
  local oldWrite = write
  local oldRead = read

  print = function( ... )
    local fOut = thread.status(thread.getPID(coroutine.running())).stdout
    if fOut.isStdout then
      oldPrint(unpack(arg))
    else
      fOut.writeLine(table.concat(arg, ""))
    end
  end

  write = function(data)
    local fOut = thread.status(thread.getPID(coroutine.running())).stdout
    if fOut.isStdout then
      oldWrite(data)
    else
      fOut.write(data)
    end
  end

  read = function(mask, history)
    local y = thread.status(thread.getPID(coroutine.running()))
    local fIn = y.stdin
    local x
    if fIn.isStdin then
      x = oldRead(mask, history)
    else
      x = fIn.readLine()
    end
    return x
  end

  local function tick(t, evt, ...)
    if isPanic then while true do coroutine.yield() end end
    if t.dead then return end
    if t.filter ~= nil and evt ~= t.filter then return end
    if evt == "terminate" and t.blockTerminate then return end
   
    coroutine.resume(t.cr, evt, ...)
    t.dead = (coroutine.status(t.cr) == "dead")
    if t.dead and t.pid ~= 1 then
      local clone = deepcopy(daemons)
      for k, v in pairs(daemons) do
        if k == t.daemon then
          kernel.log("Daemon " .. t.daemon .. " stopped")
          clone[k] = nil
        end
      end
      daemons = clone
      kernel.sendEvent("THREADDEAD", t.pid)
      if not t.stdout.isStdout then
        t.stdout.close()
      end
      if not t.stdin.isStdin then
        t.stdin.close()
      end
    end
  end
   
  local function tickAll()
    if isPanic then while true do coroutine.yield() end end
    if #starting > 0 then
      local clone = starting
      starting = {}
      for _,v in ipairs(clone) do
        table.insert(threads, v)
      end
      for _,v in ipairs(clone) do
        tick(v)
      end
    end
    local e
    if eventFilter then
      e = {eventFilter(coroutine.yield())}
    else
      e = {coroutine.yield()}
    end
    local dead = nil
    for k,v in ipairs(threads) do
      tick(v, unpack(e))
      if v.dead then
        if dead == nil then dead = {} end
        table.insert(dead, k - #dead)
      end
    end
    if dead ~= nil then
      for _,v in ipairs(dead) do
        table.remove(threads, v)
      end
    end
  end
   
  rawset(thread, "setGlobalEventFilter", function(fn)
    if eventFilter ~= nil then error("This can only be set once!") end
    eventFilter = fn
    rawset(thread, "setGlobalEventFilter", nil)
  end)

  thread = applyreadonly(thread)

  if type(threadMain) == "function" then
    thread.startThread(threadMain)
  else
    thread.startThread(function() 
      kernel.log("Starting init")
      shell.run("/sbin/init")
    end, true, "init", uid)
  end
   
  while #threads > 0 or #starting > 0 do
    tickAll()
  end
   
  kernel.log("Exiting thread manager")
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
    if oldfs.exists(ROOT_DIR .. "/var/log/kernel_log") then
      logFile = oldfs.open(ROOT_DIR .. "/var/log/kernel_log", "a")
    else
      logFile = oldfs.open(ROOT_DIR .. "/var/log/kernel_log", "w")
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
    if coroutine.running() ~= kernelCoroutine then
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

kernel.LISTMODULES = function()
  return fs.list(ROOT_DIR .. "/lib/modules")
end

kernel.LISTFLAGS = function()
  return {"Debug", "Silent", "NoPanic", "Log"}
end

local function start()
  kernel.log("Boot directory = /" .. KERNEL_DIR)
  kernel.log("Root directory = /" .. ROOT_DIR)
  if fs.exists("/" .. KERNEL_DIR .. "/var/log/kernel_log") then
    fs.delete("/" .. KERNEL_DIR .. "/var/log/kernel_log")
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
  threadMan()
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

