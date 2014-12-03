--Chown

local argv = { ... }

if #argv < 2 then
  print("Usage: chown <owner> <file1> [file2] ...")
  return
end

for i = 2, #argv do
  fsd.setNode(fsd.normalizePath(shell.resolve(argv[i])), users.getUIDByUsername(argv[1]), nil)
end
