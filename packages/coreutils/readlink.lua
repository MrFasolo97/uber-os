local argv = { ... }

if #argv < 1 then
    print("Usage: readlink <LINK>")
end
local l = fs.getInfo(shell.resolve(argv[1])).linkto
if l then
    print(l)
else
    print(fs.normalizePath(shell.resolve(argv[1])))
end
