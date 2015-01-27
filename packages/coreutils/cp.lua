
local argv = { ... }
if #argv < 2 then
	print( "Usage: cp <source> <destination>" )
	return
end

fs.copy(shell.resolve(argv[1]), shell.resolve(argv[2]))
