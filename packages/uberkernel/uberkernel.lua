--UberKernel

local ccver = "1.0" --Precise ComputerCraft version

if not fs.exists("/rom/help/changelog") then
    print("Failed to find ComputerCraft version")
    print("Please report this bug at GitHub page")
    printError("Failed to start kernel")
    return
end

local fChangelog = fs.open("/rom/help/changelog", "r")
local sChangelog = fChangelog.readLine()
fChangelog.close()

ccver = sChangelog:match("New Features in ComputerCraft ([%d%.]+):")

if ccver < "1.6" then
    print("ComputerCraft " .. ccver .. " is not supported by this version of kernel")
    print("Supported versions: 1.6-1.73")
    print("Please, update your ComputerCraft")
    printError("Failed to start kernel")
    return
end

if ccver >= "1.74" and shell then
    print("ComputerCraft " .. ccver .. " is not supported by this version of kernel")
    print("It is recomended to downgrade your version of CC")
    print("Proceed on your own risk")
    print("Press any key to continue...")
    os.pullEvent("key")
end


if ccver < "1.63" then --Patch fs.getDir. Without this patch kernel will crash on CC before 1.63
    print("[CC < 1.63]: Patching fs.getDir")
    fs.getDir = function(dir)
        assert(type(dir) == "string", "string expected got " .. type(dir))
        if dir:match("/") then
            return dir:match("^/?(.*)/.+$")
        else
            return ""
        end
    end
end

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
local runlevel = 3
local init = "/sbin/init"

local loadedModules = {} --Already loaded modules

function applyreadonly(table) --Make a table read-only
    local tmp = {}
    setmetatable(tmp, {
        __index = table,
        __newindex = function(_table, key, value)
            if thread and thread.getUID(coroutine.running()) ~= 0 then
                printError("Attempt to modify read-only table") --Allowing root to crash system. This is ok.
            else
                table[key] = value
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
            if thread and thread.getUID(coroutine.running()) ~= 0 then
                printError("Attempt to modify read-only table") --Allowing root to crash system. This is ok.
            else
                oldrawset(table, index, value)
            end
            return 
        end
    end
    oldrawset(table, index, value)
end

local threadMan = function() --Start the thread manager
    kernel.log("Starting thread manager")

    local nativeCoroutineCreate = coroutine.create
    coroutine.create = function()
        printError("coroutine.create is not supported\nUse thread API instead")
    end

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

    rawset(thread, "startThread", function(fn, tterm, desc, uid, stdin, stdout, stderr, daemon) --Run the thread
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
            cr = nativeCoroutineCreate(fn), --Process coroutine
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
            signals = {},
            skip = false,
            tterm = tterm or term.current()
        })
        return newpid, starting[#starting]
    end)


    rawset(thread, "runDaemon", function(file, name) --Start daemon
        if thread.getUID(coroutine.running()) ~= 0 then
            printError("Cannot start daemon " .. name .. " - Access denied")
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
            printError("Cannot stop daemon " .. name .. " - Access denied")
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
                        daemon = threads[i].daemon,
                        tterm = threads[i].tterm
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
                        daemon = threads[i].daemon,
                        tterm = threads[i].tterm
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
        if not t.kill then
            if t.paused then return end
            if t.filter ~= nil and evt ~= t.filter then return end
            if evt == "terminate" then thread.kill(t.pid, "INT") end
            kernel.doHook("before_resume", t.pid, evt, ...)
            term.redirect(t.tterm)
            coroutine.resume(t.cr, evt, ...)
            t.dead = (coroutine.status(t.cr) == "dead")
        else
            t.dead = true
        end
        kernel.doHook("after_resume", t.pid, evt, ...)
        if t.dead and t.pid ~= 1 then
            kernel.doHook("dead", t.pid)
            local clone = deepcopy(daemons)
            for k, v in pairs(daemons) do
                if k == t.daemon then
                    clone[k] = nil
                end
            end
            daemons = clone
            for k, v in pairs(threads) do if t.ppid == v.pid then v.paused = false end end
            for k, v in pairs(threads) do if t.ppid == v.pid then tick(v, "resume_event") v.skip = true end end
            t.stdout.close()
            t.stdin.close()
            t.stderr.close()
        end
    end

    rawset(thread, "runFile", function(file, shell, pause, uid, stdin, stdout, stderr, daemon, tterm) --Start file
        local pid, t = thread.startThread(function()
            if shell then
                shell.run(file)
            else
                local tmp = string.split(file, " ")
                file = tmp[1]
                os.run({}, file, unpack(tmp, 2))
            end
        end, tterm, daemon or file, uid or thread.getUID(coroutine.running()), stdin, stdout, stderr, daemon)
        if daemon and (thread.getUID(coroutine.running()) == 0) then
            t.ppid = 1
        end
        os.queueEvent("process_start", pid)
        if pause then
            local ppid = thread.getPID(coroutine.running())
            for k, v in pairs(threads) do if ppid == v.pid then v.paused = true end end
            coroutine.yield()
        else
            return pid
        end
    end)

    local function tickAll() --Main routine
        if isPanic then while true do os.sleep(0) end end
        for k, v in pairs(starting) do v.skip = false end
        for k, v in pairs(threads) do v.skip = false end
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
            if not v.skip then
                tick(v, unpack(e))
            end
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
        _G._G = applyreadonly(_G)
        if not fs.exists(init) then
            kernel.panic("init not found.\nTry passing init= option to kernel")
            return
        end
        _G.os.loadAPI = nil
        _G.os.unloadAPI = nil
        thread.startThread(function() 
            kernel.log("Starting init")
            os.run({}, init, tostring(runlevel))
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
    if not ROOT_DIR then 
        os.pullEvent = os.pullEventRaw
        kernel.panic("Root directory not found. Try passing root= option to kernel")
        return
    end
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
    os.pullEvent = os.pullEventRaw
    os.version = function()
        return version
    end
    kernel.log("Boot directory = /" .. KERNEL_DIR)
    kernel.log("Root directory = /" .. ROOT_DIR)

    function deepcopy(orig)
        local orig_type = type(orig)
        local copy
        if orig_type == 'table' then
            copy = {}
            for orig_key, orig_value in next, orig, nil do
                copy[deepcopy(orig_key)] = deepcopy(orig_value)
            end
            setmetatable(copy, deepcopy(getmetatable(orig)))
        else -- number, string, boolean, etc
            copy = orig
        end
        return copy
    end

    _G.deepcopy = deepcopy
    local function serializeImpl( t, tTracking, sIndent )
        local sType = type(t)
        if sType == "table" then
            if tTracking[t] ~= nil then
                error( "Cannot serialize table with recursive entries", 0 )
            end
            tTracking[t] = true

            if next(t) == nil then
                -- Empty tables are simple
                return "{}"
            else
                -- Other tables take more work
                local sResult = "{\n"
                local sSubIndent = sIndent .. "  "
                local tSeen = {}
                for k,v in ipairs(t) do
                    tSeen[k] = true
                    sResult = sResult .. sSubIndent .. serializeImpl( v, tTracking, sSubIndent ) .. ",\n"
                end
                for k,v in pairs(t) do
                    if not tSeen[k] then
                        local sEntry
                        if type(k) == "string" and string.match( k, "^[%a_][%a%d_]*$" ) then
                            sEntry = k .. " = " .. serializeImpl( v, tTracking, sSubIndent ) .. ",\n"
                        else
                            sEntry = "[ " .. serializeImpl( k, tTracking, sSubIndent ) .. " ] = " .. serializeImpl( v, tTracking, sSubIndent ) .. ",\n"
                        end
                        sResult = sResult .. sSubIndent .. sEntry
                    end
                end
                sResult = sResult .. sIndent .. "}"
                tTracking[t] = nil
                return sResult
            end

            elseif sType == "string" then
                return string.format( "%q", t )

                elseif sType == "number" or sType == "boolean" or sType == "nil" then
                    return tostring(t)

                else
                    error( "Cannot serialize type "..sType, 0 )

                end
            end

            local function serialize( t )
                local tTracking = {}
                return serializeImpl( t, tTracking, "" )
            end

            textutils.serialize = serialize
            function split(s,re)
                local i1 = 1
                local ls = {}
                local append = table.insert
                if not re then re = '%s+' end
                if re == '' then return {s} end
                while true do
                    local i2,i3 = s:find(re,i1)
                    if not i2 then
                        local last = s:sub(i1)
                        if last ~= '' then append(ls,last) end
                        if #ls == 1 and ls[1] == '' then
                            return {}
                        else
                            return ls
                        end
                    end
                    append(ls,s:sub(i1,i2-1))
                    i1 = i3+1
                end
            end
            -- better split
            function string:split(delimiter)
                if type( delimiter ) == "string" then
                    local result = { }
                    local from = 1
                    local delim_from, delim_to = string.find( self, delimiter, from )
                    while delim_from do
                        table.insert( result, string.sub( self, from , delim_from-1 ) )
                        from = delim_to + 1
                        delim_from, delim_to = string.find( self, delimiter, from )
                    end
                    table.insert( result, string.sub( self, from ) )
                    return result
                    elseif type( delimiter ) == "number" then
                        return self:gmatch( (".?"):rep( delimiter ) )
                    end
                end

                _G.split = split

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

                local modules
                if #argv <= 1 then
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
                    if argv[i]:match("^.*=") == "runlevel=" then runlevel = argv[i]:sub(10) end
                    if argv[i]:match("^.*=") == "init=" then init = argv[i]:sub(6) end
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
