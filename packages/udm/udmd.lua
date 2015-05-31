--Login Daemon

argv = { ... }

if #argv == 0 then
    print("udmd start|stop|restart|status")
    return
end

if argv[1] == "status" then
    print(thread.getDaemonStatus("udmd"))
end

if argv[1] == "start" then
    thread.runDaemon("/usr/bin/udm", "udmd")
end

if argv[1] == "stop" then
    thread.stopDaemon("udmd")
end

if argv[1] == "restart" then
    thread.stopDaemon("udmd")
    thread.runDaemon("/usr/bin/udm", "udmd")
end

