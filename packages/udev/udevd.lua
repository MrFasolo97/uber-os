--Udev Daemon

argv = { ... }

if #argv == 0 then
  print("udevd start|stop|restart|status")
  return
end

if argv[1] == "status" then
  print(thread.getDaemonStatus("udevd"))
end

if argv[1] == "start" then
  thread.runDaemon("/sbin/udev", "udevd")
end

if argv[1] == "stop" then
  thread.stopDaemon("udevd")
end

if argv[1] == "restart" then
  thread.stopDaemon("udevd")
  thread.runDaemon("/sbin/udev", "udevd")
end

