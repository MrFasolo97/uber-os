--Make a new filesystem

local argv = { ... }
if #argv < 2 then
  error("Usage: mkfs <FS> <DEVICE>")
end


