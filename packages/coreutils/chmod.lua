--Chmod

local argv = { ... }

if #argv < 2 then
  print("Usage: chmod <mode> <file1> [file2] ...")
  return
end

for i = 2, #argv do
  fsd.setNode(fsd.normalizePath(shell.resolve(argv[i])), nil, argv[1])
end
