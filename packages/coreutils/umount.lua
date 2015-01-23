--Unmount utility

local argv = { ... }

if #argv < 1 then
  error("Usage: umount <PATH>")
end

fs.umountPath(argv[1])
