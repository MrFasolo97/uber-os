--UberKernel
KERNEL_DIR = fs.getDir(shell.getRunningProgram()) --Kernel directory path
local kernelConsole = false --Show the debug console

local argv = { ... } --Kernel arguments

--STD stream

local newStdin = function() --Create new stdin stream
  return {
    isStdin = true,
    close = function() end,
    flush = function() end,
    readLine = read,
    readAll = function()
      local z = ""
      while true do
        local x = read()
        if x == "\\eof" then break end
        z = z .. "\n" .. x
      end
      return z
    end
  }
end

local newStdout = function() --Create new stdout stream
  return {
    isStdout = true,
    close = function() end,
    flush = function() end,
    write = function(x) write(x) end,
    writeLine = function(x) write(x .. "\n") end
  }
end

local newStderr = function() --Create new stderr stream
  return {
    isStderr = true,
    close = function() end,
    flush = function() end,
    write = function(x) printError(x) end,
    writeLine = function(x) printError(x) end
  }
end


--Stock functions and APIs

local oldprint = print
local oldwrite = write
local oldread  = read
local olderror = error
local oldPrintError = printError
local nativefs = fs
local kernelCoroutine = coroutine.running()

--Thread manager
local threads = {} --Currently running threads
local starting = {} --Threads, that are just started
local eventFilter = nil --Event filter, yet unused
local initRan = false --First process ran?
local daemons = {} --Currently running deamons (PIDs)
local isPanic = false --Is kernel in panic

kernel = {} --Main class

local absoluteReadOnly = {} --Read-only tables

--Boot flags
local fDebug = false
local fSilent = false
local fNoPanic = false
local fLog = false
local fNoModeSet = false

local loadedModules = {} --Already loaded modules

function applyreadonly(table) --Make a table read-only
  local tmp = {}
  setmetatable(tmp, {
    __index = table,
    __newindex = function(table, key, value)
      if thread then
        if thread.getUID(coroutine.running()) ~= 0 then
          error("Attempt to modify read-only table") --Allowing root to crash system. This is ok.
        end
      end
    end,
    __metatable = false
  })
  absoluteReadOnly[#absoluteReadOnly + 1] = tmp
  return tmp
end

local oldrawset = rawset
rawset = function(table, index, value)
  for i = 1, #absoluteReadOnly do
    if (table == absoluteReadOnly[i]) or (table[index] == absoluteReadOnly[i]) then
      if thread then
        if thread.getUID(coroutine.running()) ~= 0 then
          error("Attempt to modify read-only table") --Allowing root to crash system. This is ok.
        end
      end
      return 
    end
  end
  oldrawset(table, index, value)
end

  
local function showKernelConsole() --Show kernel debug console
  term.setTextColor(colors.white)
  term.setBackgroundColor(colors.black)
  term.clear()
  term.setCursorPos(1, 1)
  oldprint("Kernel debug console <CTRL>+T")
  oldprint("Type 'exit' to leave, 'help' for available commands")
  local s = ""
  local history = {}
  while s ~= "exit" do
    oldwrite("> ")
    s = oldread(nil, history)
    if s == "exit" then
      kernelConsole = false
      return
    end
    if s == "help" then
      oldprint("exit, help, reboot, shutdown, saferb, killbutinit, killall, kill, rbtocraftos, umountall, ps")
    end
    if s == "reboot" then os.reboot() end
    if s == "shutdown" then os.shutdown() end
    if s == "saferb" then
      os.reboot()
    end
    if s == "killbutinit" then
      starting = {}
      threads = {threads[1]}
    end
    if s == "killall" then
      starting = {}
      threads = {}
    end
    if s == "rbtocraftos" then
      fs.move(ROOT_DIR .. "/startup", ROOT_DIR .. "/.startup_backup")
      local x = fs.open(ROOT_DIR .. "/startup", "w")
      x.write("ROOT_DIR=fs.getDir(shell.getRunningProgram())\
      fs.delete(ROOT_DIR .. '/startup')\
      fs.move(ROOT_DIR .. '/.startup_backup', ROOT_DIR .. '/startup')\
      print('Be careful! UberOS will start on next reboot!')")
      x.close()
      os.reboot()
    end
    if s == "umountall" then
      oldprint("WIP")
    end
    if s == "ps" then
      for k, v in pairs(threads) do
        oldprint(v.pid, " ", v.desc, " ", v.uid)
      end
    end
    if string.sub(s, 1, 1) == ":" then loadstring(string.sub(s, 2, #s))() end
    if string.sub(s, 1, 5) == "kill " then
      if #s <= 5 then
        oldprint("Usage: kill <PID>")
      end
      local pid = tonumber(string.sub(s, 6, #s))
      for k, v in pairs(threads) do if v.pid == pid then 
        table.remove(threads, k)
        break 
      end end
    end
    table.insert(history, s)
  end
  kernelConsole = false
end

local threadMan = function() --Start the thread manager
  kernel.log("Starting thread manager")

  lua.include("copy")

  thread = {} --Main thread manager class

  rawset(thread, "newPID", function() --Generate new PID
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

  rawset(thread, "setUID", function(pid, uid, passwd) --Change UID of process
    local t = thread.status(pid or thread.getPID(coroutine.running()))
    if thread.getUID(coroutine.running()) == 0 or users.login(users.getUsernameByUID(uid), passwd) then
      t.uid = uid
    end
  end)
   
  rawset(thread, "startThread", function(fn, reserved, desc, uid, stdin, stdout, stderr, daemon) --Run the thread
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
      cr = coroutine.create(fn), --Process coroutine
      blockTerminate = true, --Unused
      error = nil, --Is process errored
      dead = false, --Is process dead
      filter = nil, --Event filter(unused)
      kill = 0, --Kill status
      pid = newpid, --Process ID
      ppid = thread.getPID(coroutine.running()), --Parent Process ID
      desc = desc or "", --Description
      uid = uid, --UID of user, running process
      paused = false, --Is process paused
      stdin = stdin or newStdin(), --Stdin stream for process
      stdout = stdout or newStdout(), --Stdout stream for process
      stderr = stderr or newStderr(), --Stderr stream for process
      daemon = daemon
    })
    return newpid, starting[#starting]
  end)

  rawset(thread, "runFile", function(file, reserved, pause, uid, stdin, stdout, stderr, daemon) --Start file
    local pid, t = thread.startThread(function()
      shell.run(file)
    end, nil, daemon or file, uid or thread.getUID(coroutine.running()), stdin, stdout, stderr, daemon)
    if daemon and (thread.getUID(coroutine.running()) == 0) then
      t.ppid = 1
    end
    if pause then
      thread.status(thread.getPID(coroutine.running())).paused = true
      coroutine.yield()
    else
      return pid
    end
  end)

  rawset(thread, "runDaemon", function(file, name) --Start daemon
    if thread.getUID(coroutine.running()) ~= 0 then
      kernel.log("Cannot start daemon " .. name .. " - Access denied!")
      return 
    end
    if daemons[name] then
      kernel.log("Daemon " .. name .. " is already running.")
      return
    end
    local pid, t = thread.runFile(file, nil, false, nil, nil, nil, nil, name)
    daemons[name] = pid
    fs.open("/var/lock/" .. name, "w").close()
    kernel.log("Daemon " .. name .. " started")
    os.sleep(0)
  end)

  rawset(thread, "stopDaemon", function(name) --Stop daemon
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

  rawset(thread, "getDaemonStatus", function(name) --Get daemon status (running or stopped)
    if daemons[name] then
      return "running"
    else
      return "stopped"
    end
  end)
  rawset(thread, "kill", function(pid, level) --Kill process
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

  rawset(thread, "isKilled", function(cr) --Is process killed
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

  rawset(thread, "getPID", function(cr) --Return PID of coroutine
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

  rawset(thread, "getUID", function(cr) --Return UID of coroutine
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


  rawset(thread, "getRunningThreads", function(cr) --Return running threads
    return threads
  end)

  rawset(thread, "status", function(pid) --Get process status
    for i = 1, #threads do
      if threads[i].pid == pid then
        if thread.getUID(coroutine.running()) ~= 0 and
          threads[i].uid ~= thread.getUID(coroutine.running()) then
          error("Cannot get status: Access denied!")
        end
        return threads[i]
      end
    end
    return nil
  end)

  print = function( ... ) --Print override
    local x = thread.status(thread.getPID(coroutine.running()))
    local fOut = x.stdout
    if fOut.isStdout then
      oldprint(unpack(arg))
    else
      fOut.writeLine(table.concat(arg, ""))
    end
  end

  write = function(data) --Write override
    local fOut = thread.status(thread.getPID(coroutine.running())).stdout
    if fOut.isStdout then
      oldwrite(data)
    else
      fOut.write(data)
    end
  end

  read = function(mask, history) --Read override
    local y = thread.status(thread.getPID(coroutine.running()))
    local fIn = y.stdin
    local x
    if fIn.isStdin then
      x = oldread(mask, history)
    else
      x = fIn.readLine()
    end
    return x
  end

  printError = function(msg) --Error override
    local y = thread.status(thread.getPID(coroutine.running()))
    local fErr = y.stderr
    if not fErr.isStderr then
      fErr.write(msg .. "\n")
    else
      oldPrintError(msg)
    end
  end

  local function tick(t, evt, ...) --Resume process
    if kernelConsole then showKernelConsole() return end
    if isPanic then while true do os.sleep(0) end end
    if t.dead then return end
    if t.paused then return end
    if t.filter ~= nil and evt ~= t.filter then return end
    if evt == "terminate" then return end
   
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
      thread.status(t.ppid).paused = false
      tick(thread.status(t.ppid), "resume_event")
      if not t.stdout.isStdout then
        t.stdout.close()
      end
      if not t.stdin.isStdin then
        t.stdin.close()
      end
      if not t.stderr.isStderr then
        t.stderr.close()
      end
    end
  end
   
  local function tickAll() --Main routine
    if isPanic then while true do os.sleep(0) end end
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
    if eventFilter and not flag then
      e = {eventFilter(coroutine.yield())}
    else
      e = {coroutine.yield()}
    end
    if e[1] == "terminate" then
      kernelConsole = not kernelConsole
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

  thread = applyreadonly(thread) _G["thread"] = thread

  _G = applyreadonly(_G, true)

  if type(threadMain) == "function" then
    thread.startThread(threadMain)
  else
    _G["print"] = print
    _G["read"] = read
    _G["write"] = write
    _G["printError"] = printError
    thread.startThread(function() 
        kernel.log("Starting init")
        shell.run("/sbin/init")
    end, nil, "init", uid)
  end
   
  while #threads > 0 or #starting > 0 do
    tickAll()
  end
   
  kernel.log("Exiting thread manager")

end

  local oldPullEvent = os.pullEvent
  local oldPullEventRaw = os.pullEventRaw
  kernel.root = ROOT_DIR
  kernel.panic = function(msg)
    if thread then
      if thread.getUID(coroutine.running()) ~= 0 then
        return false
      end
    end
    write("[" .. os.clock() .. "] Kernel panic: " .. (msg or ""))
    if fNoPanic then
      print(" ... no panic is active! Contining...")
    else
      isPanic = true
      while true do
        sleep(0)
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
    if nativefs.exists(ROOT_DIR .. "/var/log/kernel_log") then
      logFile = nativefs.open(ROOT_DIR .. "/var/log/kernel_log", "a")
    else
      logFile = nativefs.open(ROOT_DIR .. "/var/log/kernel_log", "w")
    end
    logFile.write(logmsg .. "\n")
    logFile.close()
  end
end

kernel.loadModule = function(module, panic)
  if _G[module] then return true end
  if _G["loadmodule_" .. module] then
    kernel.log("Loading module " .. module)
    status, err = pcall(_G["loadmodule_" .. module])
    if status then
      kernel.log("Loading module DONE")
      table.insert(loadedModules, module)
      _G["loadmodule_" .. module] = nil
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

local function start()
  if (multishell or window) and not fNoModeSet then
    local s = {"/" .. shell.getRunningProgram()}
    for i = 1, #argv do
      s[i + 1] = argv[i]
    end
    os.sleep(0)
    local a = _G["printError"]
    function _G.printError()
      _G["printError"] = a
      term.redirect(term.native())
      _G["multishell"] = nil
      _G["window"] = nil
      term.setBackgroundColor(colors.black)
      term.setTextColor(colors.white)
      term.clear()
      term.setCursorPos(1, 1)
      os.run({}, "/rom/programs/shell", unpack(s))
    end
    os.queueEvent("terminate")
    return
  end
  kernel.log("Boot directory = /" .. KERNEL_DIR)
  kernel.log("Root directory = /" .. ROOT_DIR)

  _G.applyreadonly = applyreadonly
  _G.rawset = rawset

  _G.stdin = newStdin()
  _G.stdout = newStdout()
  _G.stderr = newStderr()

  if fs.exists(ROOT_DIR .. "/var/log/kernel_log") then
    fs.delete(ROOT_DIR .. "/var/log/kernel_log")
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
        return
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
    for i = 1, #argv do
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
    _G["fs"] = _G["fsd"]
  end
  threadMan()
end

kernel = applyreadonly(kernel) _G["kernel"] = kernel

if #argv > 0 then
  for i = 1, #argv do
    if argv[i] == "debug" then fDebug = true end
    if argv[i] == "nomodeset" then fNoModeSet = true end
    if argv[i] == "nopanic" then fNoPanic = true end
    if argv[i] == "log" then fLog = true end
    if argv[i] == "silent" then fSilent = true end
    if argv[i]:match("^.*=") == "root=" then _G["ROOT_DIR"] = argv[i]:sub(6) end
  end
end
start()
return
