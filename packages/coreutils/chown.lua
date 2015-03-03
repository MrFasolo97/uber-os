--Chown

local argv = { ... }

local x = 2
if argv[1] == "-R" then x = 3 end

if #argv < x then
  print("Usage: chown [-R] <owner> <file1> [file2] ...")
  return
end

for i = x, #argv do
  if x == 2 then
    fsd.setNode(fsd.normalizePath(shell.resolve(argv[i])), users.getUIDByUsername(argv[x - 1]), nil)
  else
    for k, v in pairs(fsd.recursList(shell.resolve(argv[i]))) do
      fsd.setNode(v, users.getUIDByUsername(argv[x - 1]), nil)
    end
  end
end
