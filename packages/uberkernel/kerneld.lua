--Kernel Daemon

argv = { ... }

if #argv == 0 then
  print("kerneld start|stop|restart|status")
  return
end

if argv[1] == "status" then
  print(thread.getDaemonStatus("kerneld"))
end

if argv[1] == "start" then
  shell.run("/boot/uberkernel start")
end

if argv[1] == "stop" then
  shell.run("/boot/uberkernel stop")
end

if argv[1] == "restart" then
  shell.run("/boot/uberkernel restart")
end

