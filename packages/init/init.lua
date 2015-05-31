--UberOS init

thread.registerSignal("INT", function() end)
thread.registerSignal("TERM", function() end)
thread.registerSignal("KILL", function() end)

local function usage()
    print("Usage: init [runlevel]")
end

local function run(level)
    kernel.log("New runlevel: " .. level)
    if not fs.exists("/etc/inittab") then
        kernel.panic("/etc/inittab not found")
        return
    end
    local f = fs.open("/etc/inittab", "r")
    local lst = string.split(f.readAll(), "\n")
    local inittab = {}
    for k, v in pairs(lst) do
        local tmp = string.split(v, ":")
        if tmp[3] ~= "off" then
            inittab[tmp[1]] = {
                runlevels = tmp[2],
                process = tmp[4],
                action = tmp[3]
            }
        end
    end
    for k, v in pairs(inittab) do
        if v.runlevels:match(tostring(level)) then
            local pause = false
            if v.action == "wait" then pause = true end
            kernel.log("[init] Starting " .. v.process)
            local pid = thread.runFile(v.process, nil, pause)
            if not pause then
                if v.action == "respawn" then
                    kernel.registerHook("dead", function(dpid)
                        if dpid == pid then
                            kernel.log("[init] Restarting " .. v.process)
                            pid = thread.runFile(v.process)
                        end
                    end)
                end
            end
        end
    end
    kernel.registerHook("dead", function(pid)
        local t = thread.getRunningThreads()
        local r = 0
        for k, v in pairs(t) do
            if not v.dead then
                r = r + 1
            end
        end
        if r <= 1 then
            print("System halted")
            while true do
                coroutine.yield()
            end
            return
        end
    end)
    while true do
        coroutine.yield()
    end
end

local argv = { ... }
if #argv == 0 then
    run(3)
    kernel.panic("Init done. Running init 0")
    run(0)
    return
elseif argv[1] == "--help" then
    usage()
    kernel.log("Stopping init")
    return
else
    run(math.floor(tonumber(argv[1])))
end
