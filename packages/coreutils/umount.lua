--Unmount utility

local argv = { ... }

if #argv < 1 then
  print("Usage: umount <PATH>")
  return
end

fs.umountPath(argv[1])
