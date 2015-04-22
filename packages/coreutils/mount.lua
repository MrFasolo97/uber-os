--Mount utility

local argv = { ... }

if #argv < 3 then
  print("Usage: mount <DEV> <FS> <MOUNTPOINT>")
  return
end

if fs.exists(argv[1]) then
  local x = fs.open(argv[1], "r")
  local y = textutils.unserialize(x.readAll())
  x.close()
  fs.mount("/" .. y.mounted, argv[2], argv[3])
else
  fs.mount(argv[1], argv[2], argv[3])
end
