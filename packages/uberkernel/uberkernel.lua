--UberKernel
local version = "UberKernel Beta"
local temp_dir
if KERNEL_DIR then
  temp_dir = KERNEL_DIR
else
  temp_dir = fs.getDir(shell.getRunningProgram())
end
local KERNEL_DIR = temp_dir 

local argv = { ... } --Kernel arguments
local fullargv = argv
if shell then
  fullargv = {"/" .. shell.getRunningProgram()}
  for i = 1, #argv do
    fullargv[i + 1] = argv[i]
  end
end

local ccver = os.version()
local luajver = _VERSION

--Stock functions and APIs

local oldprint = print
local oldwrite = write
local oldread  = read
local olderror = error
local oldPrintError = printError
local nativefs = fs
local kernelCoroutine = coroutine.running()
local hooks = {} --Hooking system


--STD stream

newStdin = function() --Create new stdin stream
  return {
    isStdin = true,
    close = function() end,
    flush = function() end,
    readLine = oldread,
    readAll = function(mask, history)
      local z = ""
      while true do
        local x = oldread(mask, history)
        if x == "\\eof" then break end
        z = z .. "\n" .. x
      end
      return z
    end
  }
end

newStdout = function() --Create new stdout stream
  return {
    isStdout = true,
    close = function() end,
    flush = function() end,
    write = function(x) oldwrite(x) end,
    writeLine = function(x) oldwrite(x .. "\n") end
  }
end

newStderr = function() --Create new stderr stream
  return {
    isStderr = true,
    close = function() end,
    flush = function() end,
    write = function(x) oldPrintError(x) end,
    writeLine = function(x) oldPrintError(x) end
  }
end

--Thread manager
local threads = {} --Currently running threads
local starting = {} --Threads, that are just started
local eventFilter = nil --Event filter, yet unused
local initRan = false --First process ran?
local daemons = {} --Currently running deamons (PIDs)
local isPanic = false --Is kernel in panic

kernel = {} --Main class

local readOnlyTables = {} --Read-only tables

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
    __newindex = function(_table, key, value)
      if thread then
        if thread.getUID(coroutine.running()) ~= 0 then
          printError("Attempt to modify read-only table") --Allowing root to crash system. This is ok.
        else
          table[key] = value
        end
      end
    end,
    __metatable = false
  })
  readOnlyTables[#readOnlyTables + 1] = tmp
  return tmp
end

local oldrawset = rawset
rawset = function(table, index, value)
  for i = 1, #readOnlyTables do
    if (table == readOnlyTables[i]) or (table[index] == readOnlyTables[i]) then
      if thread then
        if thread.getUID(coroutine.running()) ~= 0 then
          printError("Attempt to modify read-only table") --Allowing root to crash system. This is ok.
        else
          oldrawset(table, index, value)
        end
      end
      return 
    end
  end
  oldrawset(table, index, value)
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
      for k, v in pairs(threads) do if t.pid == v.pid then v.uid = uid end end
    end
  end)
   
  rawset(thread, "startThread", function(fn, reserved, desc, uid, stdin, stdout, stderr, daemon) --Run the thread
    if thread.getUID(coroutine.running()) ~= 0 then
      daemon = nil
    end
    --[[stdin = stdin or thread.status(thread.getPID(coroutine.running())).stdin
    stdout = stdout or thread.status(thread.getPID(coroutine.running())).stdout
    stderr = stderr or thread.status(thread.getPID(coroutine.running())).stderr]]
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
      error = nil, --Is process errored
      dead = false, --Is process dead
      filter = nil, --Event filter(glitchy)
      kill = false, --Kill status
      pid = newpid, --Process ID
      ppid = thread.getPID(coroutine.running()), --Parent Process ID
      desc = desc or "", --Description
      uid = uid, --UID of user, running process
      paused = false, --Is process paused
      stdin = stdin or newStdin(), --Stdin stream for process
      stdout = stdout or newStdout(), --Stdout stream for process
      stderr = stderr or newStderr(), --Stderr stream for process
      daemon = daemon,
      signals = {}
    })
    return newpid, starting[#starting]
  end)

  rawset(thread, "runFile", function(file, reserved, pause, uid, stdin, stdout, stderr, daemon) --Start file
    local pid, t = thread.startThread(function()
      if shell then
        shell.run(file)
      else
        os.run({}, file)
      end
    end, nil, daemon or file, uid or thread.getUID(coroutine.running()), stdin, stdout, stderr, daemon)
    if daemon and (thread.getUID(coroutine.running()) == 0) then
      t.ppid = 1
    end
    if pause then
      local ppid = thread.getPID(coroutine.running())
      for k, v in pairs(threads) do if ppid == v.pid then v.paused = true end end
      coroutine.yield()
    else
      return pid
    end
  end)

  rawset(thread, "runDaemon", function(file, name) --Start daemon
    if thread.getUID(coroutine.running()) ~= 0 then
      printError("Cannot start daemon " .. name .. " - Access denied!")
      return 
    end
    if daemons[name] then
      printError("Daemon " .. name .. " is already running.")
      return
    end
    local pid, t = thread.runFile(file, nil, false, nil, nil, nil, nil, name)
    daemons[name] = pid
    fs.open("/var/lock/" .. name, "w").close()
    os.sleep(0)
  end)

  rawset(thread, "stopDaemon", function(name) --Stop daemon
    if thread.getUID(coroutine.running()) ~= 0 then
      printError("Cannot stop daemon " .. name .. " - Access denied!")
      return
    end
    if not daemons[name] then
      printError("Daemon " .. name .. " is not running.")
      return
    end
    thread.kill(daemons[name], "TERM")
    daemons[name] = nil
    fs.delete("/var/lock/" .. name)
  end)

  rawset(thread, "getDaemonStatus", function(name) --Get daemon status (running or stopped)
    if daemons[name] then
      return "running"
    else
      return "stopped"
    end
  end)
  rawset(thread, "registerSignal", function(sig, func)
    for i = 1, #threads do
      if threads[i].pid == thread.getPID(coroutine.running()) then
        if (sig ~= "KILL") or threads[i].pid == 1 then
          threads[i].signals[sig] = func
        end
      end
    end
  end)

  rawset(thread, "kill", function(pid, sig) --Send signal to process
    for i = 1, #threads do
      if threads[i].pid == pid then
        if (thread.getUID(coroutine.running()) == 0) or
           (thread.getUID(coroutine.running()) == threads[i].uid) then
          if threads[i].signals[sig] then
            threads[i].signals[sig]()
          else
            if sig == "KILL" then threads[i].kill = true end
            if sig == "INT" then threads[i].kill = true end
            if sig == "TERM" then threads[i].kill = true end
          end
        end
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


  rawset(thread, "getRunningThreads", function() --Return running threads
    local r = {}
    for k, v in pairs(threads) do
      r[k] = thread.status(v.pid)
    end
    return r
  end)

  rawset(thread, "status", function(pid) --Get process status
    for i = 1, #threads do
      if threads[i].pid == pid then
        if (thread.getUID(coroutine.running()) == threads[i].uid) or
           (thread.getUID(coroutine.running()) == 0) then
        return {
          dead = threads[i].dead,
          kill = threads[i].kill,
          pid = pid,
          ppid = threads[i].ppid,
          desc = threads[i].desc,
          uid = threads[i].uid,
          paused = threads[i].paused,
          stdin = threads[i].stdin,
          stdout = threads[i].stdout,
          stderr = threads[i].stderr,
          daemon = threads[i].daemon
        }
        else
        return {
          dead = threads[i].dead,
          kill = threads[i].kill,
          pid = pid,
          ppid = threads[i].ppid,
          desc = threads[i].desc,
          uid = threads[i].uid,
          paused = threads[i].paused,
          daemon = threads[i].daemon
        }
      end
      end
    end
    for i = 1, #starting do
      if starting[i].pid == pid then
        if (thread.getUID(coroutine.running()) == starting[i].uid) or
           (thread.getUID(coroutine.running()) == 0) then
        return {
          dead = starting[i].dead,
          kill = starting[i].kill,
          pid = pid,
          ppid = starting[i].ppid,
          desc = starting[i].desc,
          uid = starting[i].uid,
          paused = starting[i].paused,
          stdin = starting[i].stdin,
          stdout = starting[i].stdout,
          stderr = starting[i].stderr,
          daemon = starting[i].daemon
        }
        else
        return {
          dead = starting[i].dead,
          kill = starting[i].kill,
          pid = pid,
          ppid = starting[i].ppid,
          desc = starting[i].desc,
          uid = starting[i].uid,
          paused = starting[i].paused,
          daemon = starting[i].daemon
        }
      end
      end
    end
  end)

  print = function( ... ) --Print override
    arg = arg or {}
    local fOut = (thread.status(thread.getPID(coroutine.running())) or {stdout = newStdout()}).stdout
    fOut.writeLine(table.concat(arg, ""))
  end

  write = function(data) --Write override
    local fOut = (thread.status(thread.getPID(coroutine.running())) or {stdout = newStdout()}).stdout
     fOut.write(data)
  end

  read = function(mask, history) --Read override
    local fIn = (thread.status(thread.getPID(coroutine.running())) or {stdin = newStdin()}).stdin
    return fIn.readLine(mask, history)
  end

  printError = function(msg) --Error override
    local fErr = (thread.status(thread.getPID(coroutine.running())) or {stderr = newStderr()}).stderr
    fErr.write(msg .. "\n")
  end

  local function tick(t, evt, ...) --Resume process
    if isPanic then while true do os.sleep(0) end end
    if t.dead then return end
    if t.paused then return end
    if t.filter ~= nil and evt ~= t.filter then return end
    if evt == "terminate" then thread.kill(t.pid, "INT") end
    kernel.doHook("before_resume", t.pid, evt, ...)
    if not t.kill then
      coroutine.resume(t.cr, evt, ...)
      t.dead = (coroutine.status(t.cr) == "dead")
    else
      t.dead = true
    end
    kernel.doHook("after_resume", t.pid, evt, ...)
    if t.dead and t.pid ~= 1 then
      local clone = deepcopy(daemons)
      for k, v in pairs(daemons) do
        if k == t.daemon then
          clone[k] = nil
        end
      end
      daemons = clone
      for k, v in pairs(threads) do if t.ppid == v.pid then v.paused = false end end
      for k, v in pairs(threads) do if t.ppid == v.pid then tick(v, "resume_event") end end
      t.stdout.close()
      t.stdin.close()
      t.stderr.close()
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

  _G = applyreadonly(_G)

  if type(threadMain) == "function" then
    thread.startThread(threadMain)
  else
    _G["print"] = print
    _G["read"] = read
    _G["write"] = write
    _G["printError"] = printError
    _G["newStdin"] = newStdin
    _G["newStdout"] = newStdout
    _G["newStderr"] = newStderr
    os = applyreadonly(os) _G["os"] = os
    thread.startThread(function() 
        kernel.log("Starting init")
        os.run({}, "/sbin/init")
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

kernel.registerHook = function(name, func)
  if thread and thread.getUID(coroutine.running()) ~= 0 then
    return false
  end
  if not hooks[name] then hooks[name] = {} end
  table.insert(hooks[name], func)
end

kernel.doHook = function (name, ...) --Run hook
  if thread and thread.getUID(coroutine.running()) ~= 0 then
    return false
  end
  for k, v in pairs(hooks[name] or {}) do
    v(unpack(arg))
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
        printError("Failed to load module" .. module .. "\nError: " .. err)
      end
    end
  end
  for i = 1, #loadedModules do
    if loadedModules[i] == module then
      return true
    end
  end
  kernel.log("Loading module " .. module)
  status = os.run({}, ROOT_DIR .. "/lib/modules/" .. module)
  if status then
    kernel.log("Loading module DONE")
    table.insert(loadedModules, module)
    return true
  else
    kernel.log("Loading module FAILED")
    if panic then
      kernel.panic("Failed to load module " .. module .. "\nError: " .. err)
    else
      printError("Failed to load module" .. module .. "\nError: " .. err)
    end
  end
end

local function start()
  if (shell or multishell) and not fNoModeSet then --tlco

    os.sleep(0)
    local a = _G["printError"]
    function _G.printError()
      _G["printError"] = a
      term.redirect(term.native())
      shell = nil
      multishell = nil
      term.setBackgroundColor(colors.black)
      term.setTextColor(colors.white)
      term.clear()
      term.setCursorPos(1, 1)
      os.run({KERNEL_DIR = KERNEL_DIR}, unpack(fullargv))
    end
    os.queueEvent("terminate")
    return
  end
  os.version = function()
    return version
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

  --[[ Setup paths
  local sPath = ".:" .. ROOT_DIR .."/bin:" .. ROOT_DIR .. "/sbin:" .. ROOT_DIR .. "/etc/init.d"
  shell.setPath( sPath )

  -- Setup aliases
  shell.setAlias( "ls", ROOT_DIR .. "/bin/ls")
  shell.setAlias( "cp", ROOT_DIR .. "/bin/cp" )
  shell.setAlias( "mv", ROOT_DIR .. "/bin/mv" )
  shell.setAlias( "rm", ROOT_DIR .. "/bin/rm" )
  shell.setAlias( "clr", ROOT_DIR .. "/bin/clear" )
  shell.setAlias( "sh", ROOT_DIR .. "/bin/ush")]]

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
local status, err = pcall(start)
if not status then
  oldwrite("\n\n[" .. os.clock() .."] Kernel oops\n")
  oldwrite("This may occur because of an error in code\n")
  oldwrite("Make sure, that you are using latest stable kernel\n")
  oldwrite("Debug information:\n")
  oldwrite("Computercraft Version: " .. ccver .. "\n")
  oldwrite("LuaJ Version: " .. luajver .. "\n")
  oldwrite("Error message: " .. err .. "\n")
  oldwrite("Loaded modules: " .. table.concat(loadedModules, ", ") .. "\n")  
  os.sleep(9999)
end
return
