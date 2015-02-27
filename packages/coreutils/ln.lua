local argv = { ... }

if #argv < 2 then
  print("Usage: ln <TARGET> <LINK_NAME>")
  return
end

if fs.exists(fs.normalizePath(shell.resolve(argv[2]))) then error("Link already exists!") end
if not fs.exists(fs.normalizePath(shell.resolve(argv[1]))) then error("Target does not exists!") end

if fs.isDir(fs.normalizePath(shell.resolve(argv[1]))) then
  fs.makeDir(fs.normalizePath(shell.resolve(argv[2])))
else
  fs.open(fs.normalizePath(shell.resolve(argv[2])), "w").close()
end

fs.setNode(shell.resolve(argv[2]), nil, nil, shell.resolve(argv[1]))
