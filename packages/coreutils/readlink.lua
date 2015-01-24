local argv = { ... }

if #argv < 1 then
  error("Usage: readlink <LINK>")
end
local l = fs.getInfo(shell.resolve(argv[1])).linkto
if l then
  print(l)
else
  error("Not a link!")
end
