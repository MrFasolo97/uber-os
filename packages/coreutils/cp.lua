
local argv = { ... }
local x = 2
if argv[1] == "-v" then x = 3 end
if #argv < x then
	print( "Usage: cp [-v] <source> <destination>" )
	return
end

for k, v in pairs(fs.find(shell.resolve(argv[x - 1]))) do
  fs.copy(v, shell.resolve(argv[x]))
  if x == 3 then
    print("Copied from " .. v .. " to " .. fsd.normalizePath(shell.resolve(argv[x])))
  end
end
