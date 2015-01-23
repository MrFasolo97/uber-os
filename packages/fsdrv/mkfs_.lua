--Make a new filesystem

local argv = { ... }
if #argv < 2 then
  error("Usage: mkfs <FS> <DEVICE>")
end

local x = argv[1]
local y = argv[2]

getfenv()[x].saveFs(y, y)
