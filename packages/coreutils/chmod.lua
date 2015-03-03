--Chmod

local argv = { ... }

local x = 2
if argv[1] == "-R" then x = 3 end

if #argv < x then
  print("Usage: chmod [-R] <mode> <file1> [file2] ...")
  return
end

for i = x, #argv do
  if x == 2 then
    fsd.setNode(fsd.normalizePath(shell.resolve(argv[i])), nil, argv[x - 1])
  else
    for k, v in pairs(fsd.recursList(shell.resolve(argv[i]))) do
      fsd.setNode(v, nil, argv[x - 1])
    end
  end
end
