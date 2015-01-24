local argv = { ... }

if #argv < 2 then
  error("Usage ln <TARGET> <LINK_NAME>")
end

if fs.exists(fs.normalizePath(argv[2])) then error("Link already exists!") end
if not fs.exists(fs.normalizePath(argv[1])) then error("Target does not exists!") end

if fs.isDir(fs.normalizePath(argv[1])) then
  fs.makeDir(fs.normalizePath(argv[2]))
else
  fs.open(fs.normalizePath(argv[2]), "w").close()
end

fs.setNode(shell.resolve(argv[2]), nil, nil, argv[1])
