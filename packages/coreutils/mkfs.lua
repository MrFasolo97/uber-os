--Make a new filesystem

local argv = { ... }
if #argv < 2 then
  print("Usage: mkfs <FS> <DEVICE>")
  return
end

local x = argv[1]
local y = argv[2]

getfenv()[x].saveFs(y, y)
