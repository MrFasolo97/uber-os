--Login Daemon

argv = { ... }

if #argv == 0 then
    print("logind start|stop|restart|status")
    return
end

if argv[1] == "status" then
    print(thread.getDaemonStatus("logind"))
end

if argv[1] == "start" then
    thread.runDaemon("/sbin/login", "logind")
end

if argv[1] == "stop" then
    thread.stopDaemon("logind")
end

if argv[1] == "restart" then
    thread.stopDaemon("logind")
    thread.runDaemon("/sbin/login", "logind")
end

